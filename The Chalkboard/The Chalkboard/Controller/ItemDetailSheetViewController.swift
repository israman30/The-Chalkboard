//
//  ItemDetailSheetViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

final class ItemDetailSheetViewController: UIViewController {
    private let item: ChalkboardItem

    private let titleLabel = UILabel()
    private let textLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()
    private let doneButton = UIButton(type: .system)

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(item: ChalkboardItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        titleLabel.text = "Item details"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        textLabel.text = item.text
        textLabel.font = .preferredFont(forTextStyle: .title3)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.textColor = .label
        textLabel.numberOfLines = 0

        let addedText = Self.dateFormatter.string(from: item.date)
        dateLabel.text = "Added \(addedText)"
        dateLabel.font = .preferredFont(forTextStyle: .subheadline)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = .secondaryLabel
        dateLabel.numberOfLines = 1

        statusLabel.text = item.isCompleted ? "Status: Completed" : "Status: Active"
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = item.isCompleted ? .secondaryLabel : .label
        statusLabel.numberOfLines = 1

        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, textLabel, dateLabel, statusLabel, doneButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func didTapDone() {
        dismiss(animated: true)
    }
}

