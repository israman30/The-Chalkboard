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
        view.layer.cornerRadius = 5
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
    
    private let statusIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .center
        iv.tintColor = .appTextSecondary
        iv.isAccessibilityElement = false
        if #available(iOS 15.0, *) {
            iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        }
        return iv
    }()
    
    private let titleRowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .top
        return sv
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
    
    private let dueTagLabel: PaddingLabel = {
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

    private let timeTagLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.insets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.layer.cornerRadius = 10
        label.layer.cornerCurve = .continuous
        label.layer.masksToBounds = true
        label.accessibilityTraits.insert(.staticText)
        label.isHidden = true
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
    
    private var baseSurfaceColor: UIColor = .appSurface
    private var baseBorderColor: UIColor = .appBorder
    private var baseShadowOpacityLight: Float = 0.08
    private var baseShadowOpacityDark: Float = 0.16
    
    func bind(_ item: ChalkboardItem) {
        let dueState = dueVisualState(for: item)
        applyChrome(for: item, dueState: dueState)
        applyStatusIcon(for: item, dueState: dueState)
        
        titleLabel.attributedText = makeTitleAttributedText(for: item)
        
        let dueDateText = Self.dateFormatter.string(from: Calendar.current.startOfDay(for: item.date))
        let timeText: String? = item.dueTimeMinutes.map { minutes in
            Self.timeFormatter.string(from: Self.dateForTimePicker(minutesSinceMidnight: minutes))
        }
        
        let duePrefix: String = {
            switch dueState {
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .upcoming: return "Due"
            }
        }()
        let dueText: String = (dueState == .today || dueState == .tomorrow) ? "\(duePrefix) • \(dueDateText)" : "\(duePrefix) \(dueDateText)"
        applyDueBadges(dueText: dueText, timeText: timeText, dueState: dueState)

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
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        titleRowStack.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        dueTagLabel.translatesAutoresizingMaskIntoConstraints = false
        timeTagLabel.translatesAutoresizingMaskIntoConstraints = false
        metaRowStack.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)

        metaRowStack.addArrangedSubview(dueTagLabel)
        metaRowStack.addArrangedSubview(timeTagLabel)
        metaRowStack.addArrangedSubview(priorityTagLabel)
        metaRowStack.addArrangedSubview(metaSpacerView)
        metaRowStack.addArrangedSubview(detailButton)

        // Allow the due badge to truncate before squeezing fixed-size controls.
        dueTagLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dueTagLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeTagLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeTagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priorityTagLabel.setContentHuggingPriority(.required, for: .horizontal)
        priorityTagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailButton.setContentHuggingPriority(.required, for: .horizontal)
        detailButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleRowStack.addArrangedSubview(statusIconView)
        titleRowStack.addArrangedSubview(titleLabel)
        
        statusIconView.setContentHuggingPriority(.required, for: .horizontal)
        statusIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        stackView.addArrangedSubview(titleRowStack)
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
            
            statusIconView.widthAnchor.constraint(equalToConstant: 22),
            statusIconView.heightAnchor.constraint(equalToConstant: 22),
            
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
        dueTagLabel.text = nil
        dueTagLabel.attributedText = nil
        timeTagLabel.text = nil
        timeTagLabel.attributedText = nil
        timeTagLabel.isHidden = true
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
        dueTagLabel.numberOfLines = isAX ? 0 : 1
        timeTagLabel.numberOfLines = isAX ? 0 : 1
        titleRowStack.alignment = isAX ? .top : .top
    }
    
    private func applyChrome(highlighted: Bool) {
        containerView.backgroundColor = highlighted ? .appElevatedSurface : baseSurfaceColor
        containerView.layer.borderColor = baseBorderColor.withAlphaComponent(highlighted ? 0.55 : 1.0).cgColor
        containerView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? baseShadowOpacityDark : baseShadowOpacityLight
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
    enum DueVisualState {
        case completed
        case overdue
        case today
        case tomorrow
        case upcoming
    }
    
    func dueVisualState(for item: ChalkboardItem) -> DueVisualState {
        if item.isCompleted { return .completed }
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dueDay = cal.startOfDay(for: item.date)
        
        if dueDay < today { return .overdue }
        
        if let minutes = item.dueTimeMinutes, dueDay == today {
            let dueDateTime = cal.date(byAdding: .minute, value: max(0, minutes), to: dueDay) ?? dueDay
            if Date() > dueDateTime { return .overdue }
        }
        
        if cal.isDate(dueDay, inSameDayAs: today) { return .today }
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: today), cal.isDate(dueDay, inSameDayAs: tomorrow) {
            return .tomorrow
        }
        return .upcoming
    }
    
    func applyChrome(for item: ChalkboardItem, dueState: DueVisualState) {
        baseSurfaceColor = .appSurface
        baseBorderColor = .appBorder
        baseShadowOpacityLight = 0.08
        baseShadowOpacityDark = 0.16
        
        if item.isCompleted {
            baseShadowOpacityLight = 0.03
            baseShadowOpacityDark = 0.08
            baseBorderColor = UIColor.appBorder.withAlphaComponent(0.85)
            baseSurfaceColor = .appSurface
        }
        
        switch dueState {
        case .overdue:
            // Keep the frame on-brand (no red border) even when overdue.
            baseBorderColor = UIColor.appAccent.withAlphaComponent(0.45)
            baseShadowOpacityLight = max(baseShadowOpacityLight, 0.10)
            baseShadowOpacityDark = max(baseShadowOpacityDark, 0.18)
        case .today:
            baseBorderColor = UIColor.appAccent.withAlphaComponent(0.40)
        case .tomorrow:
            baseBorderColor = UIColor.systemOrange.withAlphaComponent(0.28)
        case .completed, .upcoming:
            break
        }
        
        if let severity = item.prioritySeverity, !item.isCompleted, dueState != .overdue {
            baseBorderColor = severity.tagColor.withAlphaComponent(0.28)
        }
        
        updateHighlight(highlighted: isHighlighted || isSelected, animated: false)
    }
    
    func applyStatusIcon(for item: ChalkboardItem, dueState: DueVisualState) {
        let trimmed = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isChecklistLike = trimmed.contains("- [ ]") || trimmed.contains("- [x]") || trimmed.contains("- [X]")
        let isMultiline = trimmed.contains("\n")
        
        let symbolName: String = {
            if item.isCompleted { return "checkmark.circle.fill" }
            if isChecklistLike { return "checklist" }
            if isMultiline { return "text.alignleft" }
            return "circle"
        }()
        statusIconView.image = UIImage(systemName: symbolName)
        
        let tint: UIColor = {
            switch dueState {
            case .completed: return .appTextSecondary
            case .overdue: return .appAccentPressed
            case .today: return .appAccent
            case .tomorrow: return .systemOrange
            case .upcoming:
                if let severity = item.prioritySeverity { return severity.tagColor }
                return .appTextSecondary
            }
        }()
        statusIconView.tintColor = tint
    }
    
    func makeTitleAttributedText(for item: ChalkboardItem) -> NSAttributedString {
        let isCompleted = item.isCompleted
        let primaryColor = isCompleted ? UIColor.appTextSecondary : UIColor.appTextPrimary
        let secondaryColor = UIColor.appTextSecondary
        
        let baseFont = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .headline)
        let secondaryFont = UIFont.preferredFont(forTextStyle: .subheadline)
        
        let strikeStyle: Int? = isCompleted ? NSUnderlineStyle.single.rawValue : nil
        
        let text = item.text
        let parts = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard parts.count > 1 else {
            var attrs: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: primaryColor
            ]
            if let strikeStyle {
                attrs[.strikethroughStyle] = strikeStyle
                attrs[.strikethroughColor] = primaryColor
            }
            return NSAttributedString(string: text, attributes: attrs)
        }
        
        let result = NSMutableAttributedString()
        for (idx, line) in parts.enumerated() {
            if idx > 0 { result.append(NSAttributedString(string: "\n")) }
            let isFirst = idx == 0
            var attrs: [NSAttributedString.Key: Any] = [
                .font: isFirst ? baseFont : secondaryFont,
                .foregroundColor: isFirst ? primaryColor : secondaryColor
            ]
            if let strikeStyle {
                attrs[.strikethroughStyle] = strikeStyle
                attrs[.strikethroughColor] = isFirst ? primaryColor : secondaryColor
            }
            result.append(NSAttributedString(string: line, attributes: attrs))
        }
        return result
    }
    
    func applyDueBadges(dueText: String, timeText: String?, dueState: DueVisualState) {
        let dueColors: (fg: UIColor, bg: UIColor, symbol: String) = {
            switch dueState {
            case .completed:
                return (.appTextSecondary, .appElevatedSurface, "checkmark")
            case .overdue:
                return (.appAccentPressed, UIColor.appAccent.withAlphaComponent(0.18), "calendar.badge.exclamationmark")
            case .today:
                return (.appAccentPressed, UIColor.appAccent.withAlphaComponent(0.16), "calendar")
            case .tomorrow:
                return (.systemOrange, UIColor.systemOrange.withAlphaComponent(0.16), "calendar")
            case .upcoming:
                return (.appTextSecondary, .appElevatedSurface, "calendar")
            }
        }()
        
        dueTagLabel.backgroundColor = dueColors.bg
        dueTagLabel.textColor = dueColors.fg
        dueTagLabel.attributedText = makeBadgeAttributedText(symbolName: dueColors.symbol, text: dueText, textStyle: .caption1, textColor: dueColors.fg)
        dueTagLabel.accessibilityLabel = dueText
        
        guard let timeText else {
            timeTagLabel.isHidden = true
            timeTagLabel.attributedText = nil
            timeTagLabel.text = nil
            timeTagLabel.accessibilityLabel = nil
            return
        }
        
        // Match time badge styling to the due badge state.
        let timeFg: UIColor = (dueState == .today || dueState == .overdue) ? dueColors.fg : .appTextSecondary
        let timeBg: UIColor = (dueState == .today || dueState == .overdue) ? dueColors.bg : .appElevatedSurface
        timeTagLabel.isHidden = false
        timeTagLabel.backgroundColor = timeBg
        timeTagLabel.textColor = timeFg
        timeTagLabel.attributedText = makeBadgeAttributedText(symbolName: "clock", text: timeText, textStyle: .caption1, textColor: timeFg)
        timeTagLabel.accessibilityLabel = "Due time \(timeText)"
    }
    
    func makeBadgeAttributedText(symbolName: String, text: String, textStyle: UIFont.TextStyle, textColor: UIColor) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let config = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(textColor, renderingMode: .alwaysOriginal)
        
        let result = NSMutableAttributedString()
        if let image {
            let attachment = NSTextAttachment()
            attachment.image = image
            let height = font.capHeight
            attachment.bounds = CGRect(x: 0, y: (font.descender), width: height, height: height)
            result.append(NSAttributedString(attachment: attachment))
            result.append(NSAttributedString(string: " "))
        }
        
        result.append(NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: textColor
        ]))
        return result
    }
    
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
                text: "- [ ] Buy chalk\n- [ ] Erase board\n- [ ] Refill markers",
                date: Date(),
                dueTimeMinutes: 9 * 60 + 30,
                isCompleted: false,
                prioritySeverity: .medium
            ),
            ChalkboardItem(
                text: "Overdue high priority item",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                dueTimeMinutes: 8 * 60,
                isCompleted: false,
                prioritySeverity: .high
            ),
            ChalkboardItem(
                text: "Multi-line note style\nSecond line is treated as a detail preview.\nThird line too.",
                date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                dueTimeMinutes: nil,
                isCompleted: false,
                prioritySeverity: .low
            ),
            ChalkboardItem(
                text: "Completed item (muted)",
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                dueTimeMinutes: nil,
                isCompleted: true,
                prioritySeverity: nil
            )
        ])
        .previewLayout(.sizeThatFits)
        .frame(width: 390, height: 420)
        .padding()
        .previewDisplayName("Main Cell")
    }
}
#endif
