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
    
    var onEditTapped: ((MainCell) -> Void)?
    var onDetailTapped: ((MainCell) -> Void)?
    var onTitleTapped: ((MainCell) -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 14
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let baseFont = UIFont(name: "GillSans-Italic", size: 22) ?? UIFont.preferredFont(forTextStyle: .headline)
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "pencil")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        configuration.baseForegroundColor = .secondaryLabel
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = configuration
        button.accessibilityLabel = "Edit item"
        return button
    }()
    
    private let detailButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "info.circle")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        configuration.baseForegroundColor = .secondaryLabel
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = configuration
        button.accessibilityLabel = "Show item details"
        return button
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()
    
    private let metaRowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
        return sv
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
    
    func bind(_ item: ChalkboardItem) {
        let titleAttributes: [NSAttributedString.Key: Any] = {
            if item.isCompleted {
                return [
                    .font: titleLabel.font as Any,
                    .foregroundColor: UIColor.secondaryLabel,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.secondaryLabel
                ]
            } else {
                return [
                    .font: titleLabel.font as Any,
                    .foregroundColor: UIColor.label
                ]
            }
        }()

        titleLabel.attributedText = NSAttributedString(string: item.text, attributes: titleAttributes)
        let addedText = Self.dateFormatter.string(from: item.date)
        dateLabel.text = "Added \(addedText)"
        
        if item.isCompleted {
            accessibilityLabel = "\(item.text). Completed. Added \(addedText)"
        } else {
            accessibilityLabel = "\(item.text). Added \(addedText)"
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        metaRowStack.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        metaRowStack.addArrangedSubview(dateLabel)
        metaRowStack.addArrangedSubview(spacer)
        metaRowStack.addArrangedSubview(editButton)
        metaRowStack.addArrangedSubview(detailButton)

        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailButton.setContentHuggingPriority(.required, for: .horizontal)
        detailButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metaRowStack)
        containerView.addSubview(stackView)
        
        editButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(didTapDetail), for: .touchUpInside)
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.accessibilityTraits.insert(.button)
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onEditTapped = nil
        onDetailTapped = nil
        onTitleTapped = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
            self.containerView.backgroundColor = highlighted ? .tertiarySystemBackground : .secondarySystemBackground
            self.containerView.layer.borderColor = UIColor.separator.withAlphaComponent(highlighted ? 0.45 : 0.25).cgColor
        }
        
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updates)
        } else {
            updates()
        }
    }
    
    @objc private func didTapEdit() {
        onEditTapped?(self)
    }
    
    @objc private func didTapDetail() {
        onDetailTapped?(self)
    }
    
    @objc private func didTapTitle() {
        onTitleTapped?(self)
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
        tableView.backgroundColor = .systemBackground
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
