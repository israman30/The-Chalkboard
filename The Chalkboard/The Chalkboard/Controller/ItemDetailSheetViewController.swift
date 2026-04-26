//
//  ItemDetailSheetViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

protocol ItemDetailSheetProtocol {
    var item: ChalkboardItem { get set }
}

protocol ItemDetailSheetEventProtocol {
    var onToggleCompleted: ((Bool) -> Void)? { get set }
    var onUpdate: ((String, Date, ChalkboardItemPrioritySeverity?) -> Void)? { get set }
}

extension ItemDetailSheetViewController: ItemDetailSheetProtocol, ItemDetailSheetEventProtocol { }

final class ItemDetailSheetViewController: UIViewController {
    var item: ChalkboardItem
    var onToggleCompleted: ((Bool) -> Void)?
    var onUpdate: ((String, Date, ChalkboardItemPrioritySeverity?) -> Void)?
    private let centeredCardTransition = CenteredCardTransitioningDelegate()

    // Draft state decouples editing from persistence:
    // - the user can freely edit/clear/change dates
    // - nothing is committed until “Save changes”
    // This also keeps “Cancel/Close” semantics intuitive.
    private var draftText: String
    private var draftDate: Date
    private var draftPrioritySeverity: ChalkboardItemPrioritySeverity?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerRow = UIStackView()
    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private let itemTitleLabel = InsetLabel()
    private let itemTitleEditor = AutoGrowingTextView()
    private let clearTitleButton = UIButton(type: .system)
    private var itemTitleMinHeightConstraint: NSLayoutConstraint?
    private var itemTitleEditorHeightConstraint: NSLayoutConstraint?

    private let chipsRow = UIStackView()
    private let statusChip = ChipView()
    private let priorityChip = ChipView()
    private let dateChip = ChipView()
    private let datePicker = UIDatePicker()

    private let actionsRow = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let toggleCompletedButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    private var isShowingDatePicker = false
    private var backgroundTapGesture: UITapGestureRecognizer?

    private let itemTextMinHeight: CGFloat = 44
    private let clearButtonSize: CGFloat = 24

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(
        item: ChalkboardItem,
        onToggleCompleted: ((Bool) -> Void)? = nil,
        onUpdate: ((String, Date, ChalkboardItemPrioritySeverity?) -> Void)? = nil
    ) {
        self.item = item
        self.onToggleCompleted = onToggleCompleted
        self.onUpdate = onUpdate
        self.draftText = item.text
        self.draftDate = item.date
        self.draftPrioritySeverity = item.prioritySeverity
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = centeredCardTransition
        preferredContentSize = CGSize(width: 460, height: 560)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        applyItemToUI(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure layout updates keep the editor's intrinsic height accurate.
        itemTitleEditor.invalidateIntrinsicContentSize()
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapToggleCompleted() {
        item.isCompleted.toggle()
        onToggleCompleted?(item.isCompleted)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        applyItemToUI(animated: true)
    }

    @objc private func didTapSave() {
        // Treat whitespace-only edits as empty so we don’t persist “invisible” titles.
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        item.text = trimmed
        item.date = draftDate
        item.prioritySeverity = draftPrioritySeverity
        // “Draft becomes canonical” for this screen once saved.
        draftText = trimmed
        applyDraftTitleToLabel()

        view.endEditing(true)
        onUpdate?(trimmed, draftDate, draftPrioritySeverity)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        updateSaveState()
        applyItemToUI(animated: true)
    }

    @objc private func didTapPriorityChip() {
        let sheet = UIAlertController(title: "Priority", message: nil, preferredStyle: .actionSheet)

        let apply: (ChalkboardItemPrioritySeverity?) -> Void = { [weak self] severity in
            guard let self else { return }
            self.draftPrioritySeverity = severity
            self.updateSaveState()
            self.applyItemToUI(animated: true)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        sheet.addAction(UIAlertAction(title: "None", style: .default) { _ in apply(nil) })
        sheet.addAction(UIAlertAction(title: ChalkboardItemPrioritySeverity.low.title, style: .default) { _ in apply(.low) })
        sheet.addAction(UIAlertAction(title: ChalkboardItemPrioritySeverity.medium.title, style: .default) { _ in apply(.medium) })
        sheet.addAction(UIAlertAction(title: ChalkboardItemPrioritySeverity.high.title, style: .default) { _ in apply(.high) })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = priorityChip
            popover.sourceRect = priorityChip.bounds
        }

        present(sheet, animated: true)
    }

    @objc private func didTapDateChip() {
        isShowingDatePicker.toggle()
        datePicker.isHidden = !isShowingDatePicker

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }

        if isShowingDatePicker {
            // When expanding the inline picker, ensure it’s actually visible within the scroll view.
            let rectInScroll = datePicker.convert(datePicker.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rectInScroll.insetBy(dx: 0, dy: -20), animated: true)
        }
    }

    @objc private func dateDidChange() {
        draftDate = datePicker.date
        updateSaveState()
        applyItemToUI(animated: false)
    }

    @objc private func didTapBackground() {
        // Background taps dismiss the keyboard without interfering with controls inside the card.
        view.endEditing(true)
    }

    @objc private func didTapItemCard() {
        beginEditingTitle()
    }

    @objc private func didTapCopy() {
        UIPasteboard.general.string = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @objc private func didTapShare() {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        present(activity, animated: true)
    }

    @objc private func didTapClearTitle() {
        draftText = ""
        itemTitleEditor.text = ""
        updateItemTitleEditorHeight(animated: false)
        updateSaveState()
        updateClearTitleButtonVisibility(animated: true)
    }
}

private extension ItemDetailSheetViewController {
    func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.delaysContentTouches = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        backgroundTapGesture = tap

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 14
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16)

        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 12

        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        headerIconView.contentMode = .center
        headerIconView.tintColor = .appOnAccent
        headerIconView.backgroundColor = .appAccent
        headerIconView.layer.cornerRadius = 14
        headerIconView.layer.cornerCurve = .continuous

        headerTitleLabel.font = .preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textColor = .appTextPrimary
        headerTitleLabel.numberOfLines = 1
        headerTitleLabel.text = "Item details"

        if #available(iOS 15.0, *) {
            var closeConfig = UIButton.Configuration.plain()
            closeConfig.image = UIImage(systemName: "xmark.circle.fill")
            closeConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            closeConfig.baseForegroundColor = .appTextSecondary
            closeConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            closeButton.configuration = closeConfig
        } else {
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .appTextSecondary
            closeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        }
        closeButton.accessibilityLabel = "Close"
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        let headerSpacer = UIView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        headerRow.addArrangedSubview(headerIconView)
        headerRow.addArrangedSubview(headerTitleLabel)
        headerRow.addArrangedSubview(headerSpacer)
        headerRow.addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            headerIconView.widthAnchor.constraint(equalToConstant: 28),
            headerIconView.heightAnchor.constraint(equalToConstant: 28)
        ])

        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        itemTitleLabel.font = .preferredFont(forTextStyle: .title2)
        itemTitleLabel.adjustsFontForContentSizeCategory = true
        itemTitleLabel.numberOfLines = 0
        itemTitleLabel.isUserInteractionEnabled = true
        itemTitleLabel.accessibilityTraits.insert(.button)
        itemTitleLabel.accessibilityLabel = "Item title"
        itemTitleLabel.accessibilityHint = "Double tap to edit the title"
        itemTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapItemCard)))
        itemTitleLabel.backgroundColor = .appSurface
        itemTitleLabel.layer.cornerRadius = 16
        itemTitleLabel.layer.cornerCurve = .continuous
        itemTitleLabel.layer.borderWidth = 1 / UIScreen.main.scale
        itemTitleLabel.layer.borderColor = UIColor.appBorder.cgColor
        itemTitleLabel.layer.masksToBounds = true
        itemTitleLabel.contentInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        itemTitleEditor.translatesAutoresizingMaskIntoConstraints = false
        itemTitleEditor.delegate = self
        itemTitleEditor.isEditable = true
        itemTitleEditor.isSelectable = true
        itemTitleEditor.isUserInteractionEnabled = true
        itemTitleEditor.setContentHuggingPriority(.required, for: .vertical)
        itemTitleEditor.setContentCompressionResistancePriority(.required, for: .vertical)
        itemTitleEditor.font = .preferredFont(forTextStyle: .title2)
        itemTitleEditor.adjustsFontForContentSizeCategory = true
        itemTitleEditor.textColor = .appTextPrimary
        itemTitleEditor.backgroundColor = .appSurface
        itemTitleEditor.layer.cornerRadius = 16
        itemTitleEditor.layer.cornerCurve = .continuous
        itemTitleEditor.layer.borderWidth = 1 / UIScreen.main.scale
        itemTitleEditor.layer.borderColor = UIColor.appBorder.cgColor
        itemTitleEditor.layer.masksToBounds = true
        itemTitleEditor.isScrollEnabled = false
        // Extra trailing inset leaves room for the clear ("x") button.
        itemTitleEditor.textContainerInset = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14 + clearButtonSize + 10)
        itemTitleEditor.textContainer.lineFragmentPadding = 0
        itemTitleEditor.keyboardType = .default
        itemTitleEditor.autocapitalizationType = .sentences
        itemTitleEditor.accessibilityLabel = "Edit item title"
        itemTitleEditor.accessibilityHint = "Edit the item title"
        itemTitleEditor.isHidden = true

        clearTitleButton.translatesAutoresizingMaskIntoConstraints = false
        clearTitleButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearTitleButton.tintColor = .appTextSecondary
        clearTitleButton.accessibilityLabel = "Clear text"
        clearTitleButton.accessibilityHint = "Clears the item title text"
        clearTitleButton.addTarget(self, action: #selector(didTapClearTitle), for: .touchUpInside)
        clearTitleButton.isHidden = true
        clearTitleButton.alpha = 0
        itemTitleEditor.addSubview(clearTitleButton)

        let minHeight = itemTitleEditor.heightAnchor.constraint(greaterThanOrEqualToConstant: itemTextMinHeight)
        minHeight.priority = .required
        minHeight.isActive = true
        itemTitleMinHeightConstraint = minHeight

        chipsRow.axis = .horizontal
        chipsRow.alignment = .center
        chipsRow.spacing = 10
        chipsRow.distribution = .fillProportionally

        statusChip.setContentHuggingPriority(.required, for: .horizontal)
        priorityChip.setContentHuggingPriority(.required, for: .horizontal)
        dateChip.setContentHuggingPriority(.required, for: .horizontal)

        chipsRow.addArrangedSubview(statusChip)
        chipsRow.addArrangedSubview(priorityChip)
        chipsRow.addArrangedSubview(dateChip)
        chipsRow.addArrangedSubview(UIView())

        dateChip.isUserInteractionEnabled = true
        dateChip.accessibilityTraits = [.button]
        dateChip.accessibilityHint = "Double tap to change the date"
        dateChip.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDateChip)))

        priorityChip.isUserInteractionEnabled = true
        priorityChip.accessibilityTraits = [.button]
        priorityChip.accessibilityHint = "Double tap to change the priority"
        priorityChip.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPriorityChip)))

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        datePicker.date = draftDate
        datePicker.addTarget(self, action: #selector(dateDidChange), for: .valueChanged)
        datePicker.isHidden = true

        actionsRow.axis = .vertical
        actionsRow.alignment = .fill
        actionsRow.spacing = 10

        if #available(iOS 15.0, *) {
            var saveConfig = UIButton.Configuration.tinted()
            saveConfig.cornerStyle = .large
            saveConfig.baseForegroundColor = .appAccent
            saveConfig.baseBackgroundColor = UIColor.appAccent.withAlphaComponent(0.14)
            saveConfig.image = UIImage(systemName: "checkmark.circle")
            saveConfig.imagePadding = 8
            saveConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            saveButton.configuration = saveConfig
        } else {
            saveButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            saveButton.tintColor = .appAccent
            saveButton.setTitleColor(.appAccent, for: .normal)
            saveButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
            saveButton.layer.cornerRadius = 14
            saveButton.layer.borderWidth = 1 / UIScreen.main.scale
            saveButton.layer.borderColor = UIColor.appBorder.cgColor
            saveButton.layer.cornerCurve = .continuous
        }
        saveButton.setTitle("Save changes", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var toggleConfig = UIButton.Configuration.filled()
            toggleConfig.cornerStyle = .large
            toggleConfig.baseBackgroundColor = .appAccent
            toggleConfig.baseForegroundColor = .appOnAccent
            toggleConfig.imagePadding = 8
            toggleConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            toggleCompletedButton.configuration = toggleConfig
        } else {
            toggleCompletedButton.backgroundColor = .appAccent
            toggleCompletedButton.setTitleColor(.appOnAccent, for: .normal)
            toggleCompletedButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
            toggleCompletedButton.layer.cornerRadius = 14
            toggleCompletedButton.layer.cornerCurve = .continuous
        }
        toggleCompletedButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        toggleCompletedButton.titleLabel?.adjustsFontForContentSizeCategory = true
        toggleCompletedButton.addTarget(self, action: #selector(didTapToggleCompleted), for: .touchUpInside)

        let quickRow = UIStackView(arrangedSubviews: [copyButton, shareButton])
        quickRow.axis = .horizontal
        quickRow.alignment = .fill
        quickRow.distribution = .fillEqually
        quickRow.spacing = 12

        if #available(iOS 15.0, *) {
            var copyConfig = UIButton.Configuration.tinted()
            copyConfig.cornerStyle = .large
            copyConfig.baseForegroundColor = .appTextSecondary
            copyConfig.baseBackgroundColor = .appElevatedSurface
            copyConfig.image = UIImage(systemName: "doc.on.doc")
            copyConfig.imagePadding = 8
            copyConfig.title = "Copy"
            copyConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            copyButton.configuration = copyConfig
        } else {
            copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
            copyButton.tintColor = .appTextSecondary
            copyButton.setTitle("Copy", for: .normal)
            copyButton.setTitleColor(.appTextSecondary, for: .normal)
            copyButton.backgroundColor = .appElevatedSurface
            copyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            copyButton.layer.cornerRadius = 14
            copyButton.layer.cornerCurve = .continuous
        }
        copyButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        copyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        copyButton.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var shareConfig = UIButton.Configuration.tinted()
            shareConfig.cornerStyle = .large
            shareConfig.baseForegroundColor = .appTextSecondary
            shareConfig.baseBackgroundColor = .appElevatedSurface
            shareConfig.image = UIImage(systemName: "square.and.arrow.up")
            shareConfig.imagePadding = 8
            shareConfig.title = "Share"
            shareConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            shareButton.configuration = shareConfig
        } else {
            shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
            shareButton.tintColor = .appTextSecondary
            shareButton.setTitle("Share", for: .normal)
            shareButton.setTitleColor(.appTextSecondary, for: .normal)
            shareButton.backgroundColor = .appElevatedSurface
            shareButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            shareButton.layer.cornerRadius = 14
            shareButton.layer.cornerCurve = .continuous
        }
        shareButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        shareButton.titleLabel?.adjustsFontForContentSizeCategory = true
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)

        actionsRow.addArrangedSubview(saveButton)
        actionsRow.addArrangedSubview(toggleCompletedButton)
        actionsRow.addArrangedSubview(quickRow)

        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(itemTitleLabel)
        contentStack.addArrangedSubview(itemTitleEditor)
        contentStack.addArrangedSubview(chipsRow)
        contentStack.addArrangedSubview(datePicker)
        contentStack.addArrangedSubview(actionsRow)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        NSLayoutConstraint.activate([
            clearTitleButton.widthAnchor.constraint(equalToConstant: clearButtonSize),
            clearTitleButton.heightAnchor.constraint(equalToConstant: clearButtonSize),
            clearTitleButton.trailingAnchor.constraint(equalTo: itemTitleEditor.trailingAnchor, constant: -(14)),
            clearTitleButton.topAnchor.constraint(equalTo: itemTitleEditor.topAnchor, constant: 12)
        ])

        headerIconView.image = UIImage(systemName: "doc.text")

        updateSaveState()

        // Always show the entire title by expanding with its content.
        // The outer scroll view will handle scrolling when the overall card content is tall.
        itemTitleEditor.isScrollEnabled = false
        itemTitleEditor.text = draftText
        applyDraftTitleToLabel()
        updateClearTitleButtonVisibility(animated: false)
    }

    func applyItemToUI(animated: Bool) {
        let updates = {
            let addedText = Self.dateFormatter.string(from: self.draftDate)
            self.dateChip.configure(
                text: "Added \(addedText)",
                systemImageName: "calendar",
                tintColor: .appTextSecondary,
                backgroundColor: UIColor.appElevatedSurface
            )

            if let severity = self.draftPrioritySeverity {
                self.priorityChip.configure(
                    text: "Priority: \(severity.title)",
                    systemImageName: severity.systemImageName,
                    tintColor: severity.tagForegroundColor,
                    backgroundColor: severity.tagColor
                )
            } else {
                self.priorityChip.configure(
                    text: "Priority: None",
                    systemImageName: "flag",
                    tintColor: .appTextSecondary,
                    backgroundColor: UIColor.appElevatedSurface
                )
            }

            if self.item.isCompleted {
                self.statusChip.configure(
                    text: "Completed",
                    systemImageName: "checkmark.circle.fill",
                    tintColor: UIColor.appAccent,
                    backgroundColor: UIColor.appAccent.withAlphaComponent(0.16)
                )
                if #available(iOS 15.0, *) {
                    var toggleConfig = self.toggleCompletedButton.configuration ?? UIButton.Configuration.filled()
                    toggleConfig.title = "Mark as active"
                    toggleConfig.image = UIImage(systemName: "arrow.uturn.left.circle")
                    self.toggleCompletedButton.configuration = toggleConfig
                } else {
                    self.toggleCompletedButton.setTitle("Mark as active", for: .normal)
                    self.toggleCompletedButton.setImage(UIImage(systemName: "arrow.uturn.left.circle"), for: .normal)
                    self.toggleCompletedButton.tintColor = .white
                }
                self.headerIconView.image = UIImage(systemName: "checkmark.circle.fill")
                self.headerIconView.backgroundColor = .appAccent
            } else {
                self.statusChip.configure(
                    text: "Active",
                    systemImageName: "circle.fill",
                    tintColor: .appTextSecondary,
                    backgroundColor: UIColor.appElevatedSurface
                )
                if #available(iOS 15.0, *) {
                    var toggleConfig = self.toggleCompletedButton.configuration ?? UIButton.Configuration.filled()
                    toggleConfig.title = "Mark as completed"
                    toggleConfig.image = UIImage(systemName: "checkmark.circle")
                    self.toggleCompletedButton.configuration = toggleConfig
                } else {
                    self.toggleCompletedButton.setTitle("Mark as completed", for: .normal)
                    self.toggleCompletedButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
                    self.toggleCompletedButton.tintColor = .white
                }
                self.headerIconView.image = UIImage(systemName: "doc.text")
                self.headerIconView.backgroundColor = .appAccent
            }

            let labelText = self.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
            let priorityText = self.draftPrioritySeverity.map { " Priority \($0.title)." } ?? ""
            self.view.accessibilityLabel = self.item.isCompleted
                ? "\(labelText). Completed.\(priorityText) Added \(addedText)"
                : "\(labelText).\(priorityText) Added \(addedText)"
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updates)
        } else {
            updates()
        }
    }

    func updateSaveState() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty

        let hasTextChange = trimmed != item.text
        // Only compare at day granularity so time components don’t accidentally enable “Save”.
        let hasDateChange = !Calendar.current.isDate(draftDate, inSameDayAs: item.date)
        let hasPriorityChange = draftPrioritySeverity != item.prioritySeverity
        let canSave = hasText && (hasTextChange || hasDateChange || hasPriorityChange)

        saveButton.isEnabled = canSave
        saveButton.alpha = canSave ? 1.0 : 0.5
    }

    func updateTitleEditorScrolling() {
        // Intentionally no-op: the title editor expands to fit all lines.
        itemTitleEditor.isScrollEnabled = false
    }

    func beginEditingTitle() {
        itemTitleEditor.text = draftText
        itemTitleLabel.isHidden = true
        itemTitleEditor.isHidden = false
        updateItemTitleEditorHeight(animated: false)
        updateClearTitleButtonVisibility(animated: false)
        itemTitleEditor.becomeFirstResponder()
    }

    func endEditingTitle() {
        itemTitleEditor.resignFirstResponder()
        itemTitleEditor.isHidden = true
        itemTitleLabel.isHidden = false
        itemTitleEditorHeightConstraint?.isActive = false
        itemTitleEditorHeightConstraint = nil
        applyDraftTitleToLabel()
    }

    func applyDraftTitleToLabel() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            itemTitleLabel.text = "Title"
            itemTitleLabel.textColor = .appTextSecondary
        } else {
            itemTitleLabel.text = trimmed
            itemTitleLabel.textColor = .appTextPrimary
        }
        itemTitleLabel.accessibilityValue = trimmed
    }

    func updateItemTitleEditorHeight(animated: Bool) {
        guard !itemTitleEditor.isHidden else { return }

        view.layoutIfNeeded()

        // In a stack view with layoutMarginsRelativeArrangement, arranged subviews are laid out inside margins.
        let availableWidth = max(1, contentStack.bounds.width - contentStack.layoutMargins.left - contentStack.layoutMargins.right)
        let fitting = itemTitleEditor.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        let targetHeight = max(itemTextMinHeight, fitting.height)

        if itemTitleEditorHeightConstraint == nil {
            let c = itemTitleEditor.heightAnchor.constraint(equalToConstant: targetHeight)
            c.priority = .required
            c.isActive = true
            itemTitleEditorHeightConstraint = c
        } else {
            itemTitleEditorHeightConstraint?.constant = targetHeight
        }

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    func updateClearTitleButtonVisibility(animated: Bool) {
        let trimmed = itemTitleEditor.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldShow = !itemTitleEditor.isHidden && !trimmed.isEmpty

        if shouldShow {
            clearTitleButton.isHidden = false
        }

        let updates = {
            self.clearTitleButton.alpha = shouldShow ? 1.0 : 0.0
        }

        let completion: (Bool) -> Void = { _ in
            self.clearTitleButton.isHidden = !shouldShow
        }

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updates, completion: completion)
        } else {
            updates()
            completion(true)
        }
    }
}

private final class ChipView: UIView {
    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .appElevatedSurface
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .appTextSecondary

        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appTextSecondary
        label.numberOfLines = 1

        addSubview(stack)
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),

            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])

        isAccessibilityElement = true
        accessibilityTraits.insert(.staticText)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, systemImageName: String, tintColor: UIColor, backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        iconView.image = UIImage(systemName: systemImageName)
        iconView.tintColor = tintColor
        label.text = text
        label.textColor = tintColor
        accessibilityLabel = text
    }
}

extension ItemDetailSheetViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        draftText = textView.text ?? ""
        updateItemTitleEditorHeight(animated: false)
        updateSaveState()
        updateClearTitleButtonVisibility(animated: true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        endEditingTitle()
    }
}

extension ItemDetailSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }

        // Don't dismiss the keyboard / steal touches while the user interacts with the editor or date picker.
        if touchedView.isDescendant(of: itemTitleEditor) { return false }
        if touchedView.isDescendant(of: itemTitleLabel) { return false }
        if touchedView.isDescendant(of: datePicker) { return false }

        return true
    }
}

private final class InsetLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
private final class ItemDetailPreviewHostViewController: UIViewController {
    private let detail: ItemDetailSheetViewController

    init(item: ChalkboardItem) {
        self.detail = ItemDetailSheetViewController(item: item)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground

        let dim = UIView()
        dim.translatesAutoresizingMaskIntoConstraints = false
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        view.addSubview(dim)

        NSLayoutConstraint.activate([
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let cardContainer = UIView()
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = .clear
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.18
        cardContainer.layer.shadowRadius = 16
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.addSubview(cardContainer)

        let cardContent = UIView()
        cardContent.translatesAutoresizingMaskIntoConstraints = false
        cardContent.backgroundColor = .appBackground
        cardContent.layer.cornerRadius = 18
        cardContent.layer.cornerCurve = .continuous
        cardContent.layer.masksToBounds = true
        cardContainer.addSubview(cardContent)

        addChild(detail)
        detail.view.translatesAutoresizingMaskIntoConstraints = false
        cardContent.addSubview(detail.view)
        detail.didMove(toParent: self)

        let maxWidth: CGFloat = 460
        let preferred = detail.preferredContentSize
        let preferredW = (preferred.width > 0 ? preferred.width : 460)
        let preferredH = (preferred.height > 0 ? preferred.height : 560)

        NSLayoutConstraint.activate([
            cardContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
            cardContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            cardContainer.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.82),

            cardContent.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            cardContent.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            cardContent.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            cardContent.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            detail.view.leadingAnchor.constraint(equalTo: cardContent.leadingAnchor),
            detail.view.trailingAnchor.constraint(equalTo: cardContent.trailingAnchor),
            detail.view.topAnchor.constraint(equalTo: cardContent.topAnchor),
            detail.view.bottomAnchor.constraint(equalTo: cardContent.bottomAnchor)
        ])

        // Give the card a concrete baseline size so it doesn't collapse in previews.
        let width = cardContainer.widthAnchor.constraint(equalToConstant: min(maxWidth, preferredW))
        width.priority = .defaultHigh
        width.isActive = true

        let height = cardContainer.heightAnchor.constraint(equalToConstant: preferredH)
        height.priority = .defaultHigh
        height.isActive = true
    }
}

@available(iOS 13.0, *)
private struct ItemDetailPreview: UIViewControllerRepresentable {
    let item: ChalkboardItem

    func makeUIViewController(context: Context) -> UIViewController {
        ItemDetailPreviewHostViewController(item: item)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@available(iOS 13.0, *)
struct ItemDetailSheetViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ItemDetailPreview(item: ChalkboardItem(
                text: "Quick item",
                date: Date(),
                isCompleted: false
            ))
            .previewDisplayName("Detail Card (Short)")

            ItemDetailPreview(item: ChalkboardItem(
                text: "This is a very long item title meant to test multi-line layout in the card detail view. Tap the title to edit it, and make sure the entire text is visible and wraps nicely without clipping.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                isCompleted: false
            ))
            .previewDisplayName("Detail Card (Long)")
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 390, height: 820)
        .padding()
    }
}
#endif

