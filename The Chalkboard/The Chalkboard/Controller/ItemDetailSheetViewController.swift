//
//  ItemDetailSheetViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

final class ItemDetailSheetViewController: UIViewController {
    private var item: ChalkboardItem
    private let onToggleCompleted: ((Bool) -> Void)?
    private let onUpdate: ((String, Date) -> Void)?
    private let centeredCardTransition = CenteredCardTransitioningDelegate()

    private var draftText: String
    private var draftDate: Date

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerRow = UIStackView()
    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private let itemCardView = UIView()
    private let itemTitleLabel = UILabel()
    private let itemTitleEditor = AutoGrowingTextView()
    private var itemTitleMinHeightConstraint: NSLayoutConstraint?

    private let chipsRow = UIStackView()
    private let statusChip = ChipView()
    private let dateChip = ChipView()
    private let datePicker = UIDatePicker()

    private let actionsRow = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let toggleCompletedButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    private var isShowingDatePicker = false
    private var backgroundTapGesture: UITapGestureRecognizer?
    private var itemCardTapGesture: UITapGestureRecognizer?

    private let itemTextMinHeight: CGFloat = 44

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(
        item: ChalkboardItem,
        onToggleCompleted: ((Bool) -> Void)? = nil,
        onUpdate: ((String, Date) -> Void)? = nil
    ) {
        self.item = item
        self.onToggleCompleted = onToggleCompleted
        self.onUpdate = onUpdate
        self.draftText = item.text
        self.draftDate = item.date
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
        view.backgroundColor = .systemBackground
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
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        item.text = trimmed
        item.date = draftDate
        draftText = trimmed
        applyDraftTitleToLabel()

        view.endEditing(true)
        onUpdate?(trimmed, draftDate)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        updateSaveState()
        applyItemToUI(animated: true)
    }

    @objc private func didTapDateChip() {
        isShowingDatePicker.toggle()
        datePicker.isHidden = !isShowingDatePicker

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }

        if isShowingDatePicker {
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
        headerIconView.tintColor = .white
        headerIconView.backgroundColor = .greenColor
        headerIconView.layer.cornerRadius = 14
        headerIconView.layer.cornerCurve = .continuous

        headerTitleLabel.font = .preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textColor = .label
        headerTitleLabel.numberOfLines = 1
        headerTitleLabel.text = "Item details"

        if #available(iOS 15.0, *) {
            var closeConfig = UIButton.Configuration.plain()
            closeConfig.image = UIImage(systemName: "xmark.circle.fill")
            closeConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            closeConfig.baseForegroundColor = .secondaryLabel
            closeConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            closeButton.configuration = closeConfig
        } else {
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .secondaryLabel
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

        itemCardView.backgroundColor = .secondarySystemBackground
        itemCardView.layer.cornerRadius = 16
        itemCardView.layer.cornerCurve = .continuous
        itemCardView.layer.borderWidth = 1 / UIScreen.main.scale
        itemCardView.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        itemCardView.isUserInteractionEnabled = true

        let cardTap = UITapGestureRecognizer(target: self, action: #selector(didTapItemCard))
        cardTap.cancelsTouchesInView = false
        itemCardView.addGestureRecognizer(cardTap)
        itemCardTapGesture = cardTap

        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        itemTitleLabel.font = .preferredFont(forTextStyle: .title2)
        itemTitleLabel.adjustsFontForContentSizeCategory = true
        itemTitleLabel.textColor = .label
        itemTitleLabel.numberOfLines = 0
        itemTitleLabel.isUserInteractionEnabled = true
        itemTitleLabel.accessibilityTraits.insert(.button)
        itemTitleLabel.accessibilityLabel = "Item title"
        itemTitleLabel.accessibilityHint = "Double tap to edit the title"
        itemTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapItemCard)))

        itemTitleEditor.translatesAutoresizingMaskIntoConstraints = false
        itemTitleEditor.delegate = self
        itemTitleEditor.isEditable = true
        itemTitleEditor.isSelectable = true
        itemTitleEditor.isUserInteractionEnabled = true
        itemTitleEditor.setContentHuggingPriority(.required, for: .vertical)
        itemTitleEditor.setContentCompressionResistancePriority(.required, for: .vertical)
        itemTitleEditor.font = .preferredFont(forTextStyle: .title2)
        itemTitleEditor.adjustsFontForContentSizeCategory = true
        itemTitleEditor.textColor = .label
        itemTitleEditor.backgroundColor = .clear
        itemTitleEditor.isScrollEnabled = false
        itemTitleEditor.textContainerInset = .zero
        itemTitleEditor.textContainer.lineFragmentPadding = 0
        itemTitleEditor.keyboardType = .default
        itemTitleEditor.autocapitalizationType = .sentences
        itemTitleEditor.accessibilityLabel = "Edit item title"
        itemTitleEditor.accessibilityHint = "Edit the item title"
        itemTitleEditor.isHidden = true

        itemCardView.addSubview(itemTitleLabel)
        itemCardView.addSubview(itemTitleEditor)
        let minHeight = itemTitleEditor.heightAnchor.constraint(greaterThanOrEqualToConstant: itemTextMinHeight)
        minHeight.priority = .required
        itemTitleMinHeightConstraint = minHeight

        NSLayoutConstraint.activate([
            itemTitleLabel.leadingAnchor.constraint(equalTo: itemCardView.leadingAnchor, constant: 14),
            itemTitleLabel.trailingAnchor.constraint(equalTo: itemCardView.trailingAnchor, constant: -14),
            itemTitleLabel.topAnchor.constraint(equalTo: itemCardView.topAnchor, constant: 14),
            itemTitleLabel.bottomAnchor.constraint(equalTo: itemCardView.bottomAnchor, constant: -14),

            itemTitleEditor.leadingAnchor.constraint(equalTo: itemCardView.leadingAnchor, constant: 14),
            itemTitleEditor.trailingAnchor.constraint(equalTo: itemCardView.trailingAnchor, constant: -14),
            itemTitleEditor.topAnchor.constraint(equalTo: itemCardView.topAnchor, constant: 14),
            itemTitleEditor.bottomAnchor.constraint(equalTo: itemCardView.bottomAnchor, constant: -14),
            minHeight
        ])

        chipsRow.axis = .horizontal
        chipsRow.alignment = .center
        chipsRow.spacing = 10
        chipsRow.distribution = .fillProportionally

        statusChip.setContentHuggingPriority(.required, for: .horizontal)
        dateChip.setContentHuggingPriority(.required, for: .horizontal)

        chipsRow.addArrangedSubview(statusChip)
        chipsRow.addArrangedSubview(dateChip)
        chipsRow.addArrangedSubview(UIView())

        dateChip.isUserInteractionEnabled = true
        dateChip.accessibilityTraits = [.button]
        dateChip.accessibilityHint = "Double tap to change the date"
        dateChip.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDateChip)))

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
            saveConfig.baseForegroundColor = .systemBlue
            saveConfig.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            saveConfig.image = UIImage(systemName: "checkmark.circle")
            saveConfig.imagePadding = 8
            saveConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            saveButton.configuration = saveConfig
        } else {
            saveButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            saveButton.tintColor = .systemBlue
            saveButton.setTitleColor(.systemBlue, for: .normal)
            saveButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
            saveButton.layer.cornerRadius = 14
            saveButton.layer.borderWidth = 1 / UIScreen.main.scale
            saveButton.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
            saveButton.layer.cornerCurve = .continuous
        }
        saveButton.setTitle("Save changes", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var toggleConfig = UIButton.Configuration.filled()
            toggleConfig.cornerStyle = .large
            toggleConfig.baseBackgroundColor = .greenColor
            toggleConfig.baseForegroundColor = .white
            toggleConfig.imagePadding = 8
            toggleConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            toggleCompletedButton.configuration = toggleConfig
        } else {
            toggleCompletedButton.backgroundColor = .greenColor
            toggleCompletedButton.setTitleColor(.white, for: .normal)
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
            copyConfig.baseForegroundColor = .secondaryLabel
            copyConfig.baseBackgroundColor = .tertiarySystemBackground
            copyConfig.image = UIImage(systemName: "doc.on.doc")
            copyConfig.imagePadding = 8
            copyConfig.title = "Copy"
            copyConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            copyButton.configuration = copyConfig
        } else {
            copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
            copyButton.tintColor = .secondaryLabel
            copyButton.setTitle("Copy", for: .normal)
            copyButton.setTitleColor(.secondaryLabel, for: .normal)
            copyButton.backgroundColor = .tertiarySystemBackground
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
            shareConfig.baseForegroundColor = .secondaryLabel
            shareConfig.baseBackgroundColor = .tertiarySystemBackground
            shareConfig.image = UIImage(systemName: "square.and.arrow.up")
            shareConfig.imagePadding = 8
            shareConfig.title = "Share"
            shareConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            shareButton.configuration = shareConfig
        } else {
            shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
            shareButton.tintColor = .secondaryLabel
            shareButton.setTitle("Share", for: .normal)
            shareButton.setTitleColor(.secondaryLabel, for: .normal)
            shareButton.backgroundColor = .tertiarySystemBackground
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
        contentStack.addArrangedSubview(itemCardView)
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

        headerIconView.image = UIImage(systemName: "doc.text")

        updateSaveState()

        // Always show the entire title by expanding with its content.
        // The outer scroll view will handle scrolling when the overall card content is tall.
        itemTitleEditor.isScrollEnabled = false
        itemTitleEditor.text = draftText
        applyDraftTitleToLabel()
    }

    func applyItemToUI(animated: Bool) {
        let updates = {
            let addedText = Self.dateFormatter.string(from: self.draftDate)
            self.dateChip.configure(
                text: "Added \(addedText)",
                systemImageName: "calendar",
                tintColor: .secondaryLabel,
                backgroundColor: UIColor.tertiarySystemBackground
            )

            if self.item.isCompleted {
                self.statusChip.configure(
                    text: "Completed",
                    systemImageName: "checkmark.circle.fill",
                    tintColor: UIColor.greenColor,
                    backgroundColor: UIColor.greenColor.withAlphaComponent(0.12)
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
                self.headerIconView.backgroundColor = .greenColor
            } else {
                self.statusChip.configure(
                    text: "Active",
                    systemImageName: "circle.fill",
                    tintColor: .secondaryLabel,
                    backgroundColor: UIColor.tertiarySystemBackground
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
                self.headerIconView.backgroundColor = .greenColor
            }

            let labelText = self.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
            self.view.accessibilityLabel = self.item.isCompleted
                ? "\(labelText). Completed. Added \(addedText)"
                : "\(labelText). Added \(addedText)"
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
        let hasDateChange = !Calendar.current.isDate(draftDate, inSameDayAs: item.date)
        let canSave = hasText && (hasTextChange || hasDateChange)

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
        itemTitleEditor.becomeFirstResponder()
    }

    func endEditingTitle() {
        itemTitleEditor.resignFirstResponder()
        itemTitleEditor.isHidden = true
        itemTitleLabel.isHidden = false
        applyDraftTitleToLabel()
    }

    func applyDraftTitleToLabel() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            itemTitleLabel.text = "Title"
            itemTitleLabel.textColor = .secondaryLabel
        } else {
            itemTitleLabel.text = trimmed
            itemTitleLabel.textColor = .label
        }
        itemTitleLabel.accessibilityValue = trimmed
    }
}

private final class ChipView: UIView {
    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel

        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
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
        itemTitleEditor.invalidateIntrinsicContentSize()
        updateSaveState()
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
        if touchedView.isDescendant(of: itemCardView) { return false }
        if touchedView.isDescendant(of: datePicker) { return false }

        return true
    }
}

