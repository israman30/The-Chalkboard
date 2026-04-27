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
    private let initialDueTimeMinutes: Int?
    private let onSave: (String, Date, Int?) -> Void

    private let titleLabel = UILabel()
    private let textField = UITextField()
    private let datePicker = UIDatePicker()
    private let timeLabel = UILabel()
    private let timeToggle = UISwitch()
    private let timePicker = UIDatePicker()
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    init(
        titleText: String,
        initialText: String,
        initialDate: Date,
        initialDueTimeMinutes: Int? = nil,
        onSave: @escaping (String, Date, Int?) -> Void
    ) {
        self.titleText = titleText
        self.initialText = initialText
        self.initialDate = initialDate
        self.initialDueTimeMinutes = initialDueTimeMinutes
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .appBackground

        titleLabel.text = titleText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .appTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        textField.text = initialText
        textField.placeholder = "Title"
        textField.borderStyle = .roundedRect
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = .appTextPrimary
        textField.tintColor = .appAccent
        textField.autocapitalizationType = .sentences
        textField.clearButtonMode = .always
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }
        datePicker.date = initialDate

        timeLabel.text = "Time (optional)"
        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .appTextSecondary
        timeLabel.numberOfLines = 1

        timeToggle.isOn = initialDueTimeMinutes != nil
        timeToggle.addTarget(self, action: #selector(didToggleTime), for: .valueChanged)
        timeToggle.accessibilityLabel = "Add time"

        timePicker.datePickerMode = .time
        if #available(iOS 14.0, *) {
            timePicker.preferredDatePickerStyle = .wheels
        }
        if let minutes = initialDueTimeMinutes {
            timePicker.date = Self.dateForTimePicker(minutesSinceMidnight: minutes)
        }
        timePicker.isHidden = !timeToggle.isOn

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .appAccent
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        doneButton.setTitle("Save", for: .normal)
        doneButton.tintColor = .appAccent
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12

        let timeHeader = UIStackView(arrangedSubviews: [timeLabel, UIView(), timeToggle])
        timeHeader.axis = .horizontal
        timeHeader.alignment = .center
        timeHeader.spacing = 10

        let timeStack = UIStackView(arrangedSubviews: [timeHeader, timePicker])
        timeStack.axis = .vertical
        timeStack.alignment = .fill
        timeStack.spacing = 8

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField, datePicker, timeStack, buttons])
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
        // Keep the “Save” action disabled when the title would be effectively empty.
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
        let picked = Calendar.current.startOfDay(for: datePicker.date)
        let minutes: Int? = timeToggle.isOn ? Self.minutesSinceMidnight(from: timePicker.date) : nil
        // Fire the save callback after the sheet is dismissed to keep transitions clean.
        dismiss(animated: true) { [onSave] in
            onSave(trimmed, picked, minutes)
        }
    }
}

private extension EditItemSheetViewController {
    @objc func didToggleTime() {
        timePicker.isHidden = !timeToggle.isOn
    }

    static func minutesSinceMidnight(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    static func dateForTimePicker(minutesSinceMidnight minutes: Int) -> Date {
        let h = max(0, minutes) / 60
        let m = max(0, minutes) % 60
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }
}

