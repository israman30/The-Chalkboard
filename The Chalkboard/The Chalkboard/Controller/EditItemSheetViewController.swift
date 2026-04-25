//
//  EditItemSheetViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

final class EditItemSheetViewController: UIViewController {
    private let titleText: String
    private let initialText: String
    private let initialDate: Date
    private let onSave: (String, Date) -> Void

    private let titleLabel = UILabel()
    private let textField = UITextField()
    private let datePicker = UIDatePicker()
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    init(
        titleText: String,
        initialText: String,
        initialDate: Date,
        onSave: @escaping (String, Date) -> Void
    ) {
        self.titleText = titleText
        self.initialText = initialText
        self.initialDate = initialDate
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        titleLabel.text = titleText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        textField.text = initialText
        textField.placeholder = "Title"
        textField.borderStyle = .roundedRect
        textField.font = .preferredFont(forTextStyle: .body)
        textField.autocapitalizationType = .sentences
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        datePicker.date = initialDate

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        doneButton.setTitle("Save", for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField, datePicker, buttons])
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

        updateDoneState()
    }

    @objc private func textDidChange() {
        updateDoneState()
    }

    private func updateDoneState() {
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        doneButton.isEnabled = !trimmed.isEmpty
        doneButton.alpha = doneButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let picked = datePicker.date
        dismiss(animated: true) { [onSave] in
            onSave(trimmed, picked)
        }
    }
}

