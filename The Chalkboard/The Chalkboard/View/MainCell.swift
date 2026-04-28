//
//  MainCell.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

enum Cell: String {
    case mainCell = "cell"
}

protocol CellProtocol {
    func bind(_ item: ChalkboardItem)
}

final class MainCell: UITableViewCell, CellProtocol {
    
    var onDetailTapped: ((MainCell) -> Void)?
    var onTitleTapped: ((MainCell) -> Void)?
    
    private lazy var toggleCompletedAction = UIAccessibilityCustomAction(
        name: "Toggle completed",
        target: self,
        selector: #selector(accessibilityToggleCompleted)
    )
    
    private lazy var showDetailsAction = UIAccessibilityCustomAction(
        name: "Show details",
        target: self,
        selector: #selector(accessibilityShowDetails)
    )
    
    private lazy var detailFeedback = UIImpactFeedbackGenerator(style: .light)
    private lazy var titleFeedback = UISelectionFeedbackGenerator()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appSurface
        view.layer.cornerRadius = 14
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = UIColor.appBorder.cgColor
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let baseFont = UIFont(name: "GillSans-Italic", size: 22) ?? UIFont.preferredFont(forTextStyle: .headline)
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .appTextPrimary
        return label
    }()
    
    private let detailButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "info.circle")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        configuration.baseForegroundColor = .appTextSecondary
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = configuration
        button.accessibilityLabel = "Show item details"
        button.accessibilityHint = "Opens the details sheet for this item."
        return button
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .appTextSecondary
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let priorityTagLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.insets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.layer.cornerRadius = 10
        label.layer.cornerCurve = .continuous
        label.layer.masksToBounds = true
        label.accessibilityTraits.insert(.staticText)
        return label
    }()
    
    private let metaRowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
        return sv
    }()
    
    private let metaSpacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        sv.alignment = .fill
        return sv
    }()
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()
    
    func bind(_ item: ChalkboardItem) {
        // Styling is data-driven so completed items can be visually distinguished (and read via VO).
        let titleAttributes: [NSAttributedString.Key: Any] = {
            if item.isCompleted {
                return [
                    .font: titleLabel.font as Any,
                    .foregroundColor: UIColor.appTextSecondary,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.appTextSecondary
                ]
            } else {
                return [
                    .font: titleLabel.font as Any,
                    .foregroundColor: UIColor.appTextPrimary
                ]
            }
        }()

        titleLabel.attributedText = NSAttributedString(string: item.text, attributes: titleAttributes)
        let dueDateText = Self.dateFormatter.string(from: item.date)
        let timeText: String? = item.dueTimeMinutes.map { minutes in
            Self.timeFormatter.string(from: Self.dateForTimePicker(minutesSinceMidnight: minutes))
        }
        if let timeText {
            dateLabel.text = "Due \(dueDateText) • \(timeText)"
        } else {
            dateLabel.text = "Due \(dueDateText)"
        }

        if let severity = item.prioritySeverity {
            priorityTagLabel.text = severity.title
            priorityTagLabel.textColor = severity.tagForegroundColor
            priorityTagLabel.backgroundColor = severity.tagColor
            priorityTagLabel.accessibilityLabel = "Priority \(severity.title)"
        } else {
            priorityTagLabel.text = "None"
            priorityTagLabel.textColor = .appTextSecondary
            priorityTagLabel.backgroundColor = .appElevatedSurface
            priorityTagLabel.accessibilityLabel = "Priority None"
        }

        accessibilityLabel = item.text
        
        var valueParts: [String] = []
        valueParts.append(item.isCompleted ? "Completed" : "Not completed")
        if let severity = item.prioritySeverity {
            valueParts.append("Priority \(severity.title)")
        } else {
            valueParts.append("Priority None")
        }
        valueParts.append(timeText == nil ? "Due \(dueDateText)" : "Due \(dueDateText), \(timeText!)")
        accessibilityValue = valueParts.joined(separator: ", ")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        accessibilityTraits.insert(.button)
        accessibilityHint = "Double-tap to toggle completed. Swipe up or down for more actions."
        accessibilityCustomActions = [toggleCompletedAction, showDetailsAction]
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        metaRowStack.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)

        metaRowStack.addArrangedSubview(dateLabel)
        metaRowStack.addArrangedSubview(priorityTagLabel)
        metaRowStack.addArrangedSubview(metaSpacerView)
        metaRowStack.addArrangedSubview(detailButton)

        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priorityTagLabel.setContentHuggingPriority(.required, for: .horizontal)
        priorityTagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailButton.setContentHuggingPriority(.required, for: .horizontal)
        detailButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metaRowStack)
        containerView.addSubview(stackView)
        
        detailButton.addTarget(self, action: #selector(didTapDetail), for: .touchUpInside)
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.isAccessibilityElement = false
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTitle)))
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        updateLayoutForContentSizeCategory()
        updateHighlight(highlighted: false, animated: false)
        registerForTraitChangesIfAvailable()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onDetailTapped = nil
        onTitleTapped = nil
        titleLabel.attributedText = nil
        dateLabel.text = nil
        priorityTagLabel.text = nil
        accessibilityLabel = nil
        accessibilityValue = nil
        updateHighlight(highlighted: false, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Provide a concrete shadow path for better performance than dynamic shadow rendering.
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateHighlight(highlighted: highlighted, animated: animated)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateHighlight(highlighted: selected, animated: animated)
    }
    
    private func updateHighlight(highlighted: Bool, animated: Bool) {
        let updates = {
            self.applyChrome(highlighted: highlighted)
        }
        
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updates)
        } else {
            updates()
        }
    }
    
    @objc private func didTapDetail() {
        detailFeedback.prepare()
        detailFeedback.impactOccurred()
        onDetailTapped?(self)
    }
    
    @objc private func didTapTitle() {
        titleFeedback.prepare()
        titleFeedback.selectionChanged()
        onTitleTapped?(self)
    }
    
    @available(iOS, deprecated: 17.0)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // On iOS 17+, trait changes are handled via registration APIs.
        if #available(iOS 17.0, *) { return }
        handleTraitChanges(previousTraitCollection: previousTraitCollection)
    }
    
    override func accessibilityActivate() -> Bool {
        didTapTitle()
        return true
    }
    
    private func updateLayoutForContentSizeCategory() {
        let isAX = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        metaRowStack.axis = isAX ? .vertical : .horizontal
        metaRowStack.alignment = isAX ? .leading : .center
        metaRowStack.spacing = isAX ? 6 : 10
        metaSpacerView.isHidden = isAX
        dateLabel.numberOfLines = isAX ? 0 : 1
    }
    
    private func applyChrome(highlighted: Bool) {
        containerView.backgroundColor = highlighted ? .appElevatedSurface : .appSurface
        containerView.layer.borderColor = UIColor.appBorder.withAlphaComponent(highlighted ? 0.55 : 1.0).cgColor
        containerView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.16 : 0.08
    }

    private func handleTraitChanges(previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateLayoutForContentSizeCategory()
        }

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateHighlight(highlighted: isHighlighted || isSelected, animated: false)
        }
    }

    private func registerForTraitChangesIfAvailable() {
        guard #available(iOS 17.0, *) else { return }

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitUserInterfaceStyle.self]) { (cell: MainCell, previousTraitCollection: UITraitCollection) in
            cell.handleTraitChanges(previousTraitCollection: previousTraitCollection)
        }
    }
    
    @objc private func accessibilityToggleCompleted() -> Bool {
        didTapTitle()
        return true
    }
    
    @objc private func accessibilityShowDetails() -> Bool {
        didTapDetail()
        return true
    }
}

private extension MainCell {
    static func dateForTimePicker(minutesSinceMidnight minutes: Int) -> Date {
        let h = max(0, minutes) / 60
        let m = max(0, minutes) % 60
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }
}

private final class PaddingLabel: UILabel {
    var insets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
private struct MainCellTablePreview: UIViewRepresentable {
    var items: [ChalkboardItem]

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items)
    }

    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(MainCell.self, forCellReuseIdentifier: Cell.mainCell.rawValue)
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = .appBackground
        tableView.isScrollEnabled = false
        return tableView
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        context.coordinator.items = items
        uiView.reloadData()
        uiView.layoutIfNeeded()
    }

    final class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        var items: [ChalkboardItem]

        init(items: [ChalkboardItem]) {
            self.items = items
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            items.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: Cell.mainCell.rawValue, for: indexPath) as! MainCell
            cell.bind(items[indexPath.row])
            return cell
        }
    }
}

@available(iOS 13.0, *)
struct MainCell_InFile_Previews: PreviewProvider {
    static var previews: some View {
        MainCellTablePreview(items: [
            ChalkboardItem(
                text: "This is a preview of the improved cell UI with dynamic type and better spacing.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            )
        ])
        .previewLayout(.sizeThatFits)
        .frame(width: 390, height: 200)
        .padding()
        .previewDisplayName("Main Cell")
    }
}
#endif
