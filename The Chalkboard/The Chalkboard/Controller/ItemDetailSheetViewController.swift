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
    private let onEdit: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerRow = UIStackView()
    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private let itemCardView = UIView()
    private let itemTextLabel = UILabel()

    private let chipsRow = UIStackView()
    private let statusChip = ChipView()
    private let dateChip = ChipView()

    private let actionsRow = UIStackView()
    private let toggleCompletedButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(item: ChalkboardItem, onToggleCompleted: ((Bool) -> Void)? = nil, onEdit: (() -> Void)? = nil) {
        self.item = item
        self.onToggleCompleted = onToggleCompleted
        self.onEdit = onEdit
        super.init(nibName: nil, bundle: nil)
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

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapToggleCompleted() {
        item.isCompleted.toggle()
        onToggleCompleted?(item.isCompleted)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        applyItemToUI(animated: true)
    }

    @objc private func didTapEdit() {
        dismiss(animated: true) { [onEdit] in
            onEdit?()
        }
    }

    @objc private func didTapCopy() {
        UIPasteboard.general.string = item.text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @objc private func didTapShare() {
        let activity = UIActivityViewController(activityItems: [item.text], applicationActivities: nil)
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

        itemTextLabel.translatesAutoresizingMaskIntoConstraints = false
        itemTextLabel.font = .preferredFont(forTextStyle: .title2)
        itemTextLabel.adjustsFontForContentSizeCategory = true
        itemTextLabel.textColor = .label
        itemTextLabel.numberOfLines = 0

        itemCardView.addSubview(itemTextLabel)
        NSLayoutConstraint.activate([
            itemTextLabel.leadingAnchor.constraint(equalTo: itemCardView.leadingAnchor, constant: 14),
            itemTextLabel.trailingAnchor.constraint(equalTo: itemCardView.trailingAnchor, constant: -14),
            itemTextLabel.topAnchor.constraint(equalTo: itemCardView.topAnchor, constant: 14),
            itemTextLabel.bottomAnchor.constraint(equalTo: itemCardView.bottomAnchor, constant: -14)
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

        actionsRow.axis = .vertical
        actionsRow.alignment = .fill
        actionsRow.spacing = 10

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

        if #available(iOS 15.0, *) {
            var editConfig = UIButton.Configuration.tinted()
            editConfig.cornerStyle = .large
            editConfig.baseForegroundColor = .greenColor
            editConfig.baseBackgroundColor = UIColor.greenColor.withAlphaComponent(0.14)
            editConfig.image = UIImage(systemName: "pencil")
            editConfig.imagePadding = 8
            editConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            editButton.configuration = editConfig
        } else {
            editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
            editButton.tintColor = .greenColor
            editButton.setTitleColor(.greenColor, for: .normal)
            editButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
            editButton.layer.cornerRadius = 14
            editButton.layer.borderWidth = 1 / UIScreen.main.scale
            editButton.layer.borderColor = UIColor.greenColor.withAlphaComponent(0.35).cgColor
            editButton.layer.cornerCurve = .continuous
        }
        editButton.setTitle("Edit item", for: .normal)
        editButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        editButton.titleLabel?.adjustsFontForContentSizeCategory = true
        editButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)

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

        actionsRow.addArrangedSubview(toggleCompletedButton)
        actionsRow.addArrangedSubview(editButton)
        actionsRow.addArrangedSubview(quickRow)

        contentStack.addArrangedSubview(headerRow)
        contentStack.addArrangedSubview(itemCardView)
        contentStack.addArrangedSubview(chipsRow)
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
    }

    func applyItemToUI(animated: Bool) {
        let updates = {
            self.itemTextLabel.text = self.item.text
            self.itemTextLabel.accessibilityLabel = self.item.text

            let addedText = Self.dateFormatter.string(from: self.item.date)
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

            self.view.accessibilityLabel = self.item.isCompleted
                ? "\(self.item.text). Completed. Added \(addedText)"
                : "\(self.item.text). Added \(addedText)"
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updates)
        } else {
            updates()
        }
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

