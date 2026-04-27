//
//  DatePickerSheetViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/24/26.
//

import UIKit

final class DatePickerSheetViewController: UIViewController {
    private let titleText: String
    private let initialDate: Date
    private let initialDueTimeMinutes: Int?
    private let initialPrioritySeverity: ChalkboardItemPrioritySeverity?
    private let onPick: (Date, Int?, ChalkboardItemPrioritySeverity?) -> Void

    private let titleLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let timeLabel = UILabel()
    private let timeToggle = UISwitch()
    private let timePicker = UIDatePicker()
    private let priorityLabel = UILabel()
    private let priorityControl = UISegmentedControl(items: ["None", "Low", "Medium", "High"])
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    init(
        titleText: String,
        initialDate: Date,
        initialDueTimeMinutes: Int? = nil,
        initialPrioritySeverity: ChalkboardItemPrioritySeverity? = nil,
        onPick: @escaping (Date, Int?, ChalkboardItemPrioritySeverity?) -> Void
    ) {
        self.titleText = titleText
        self.initialDate = initialDate
        self.initialDueTimeMinutes = initialDueTimeMinutes
        self.initialPrioritySeverity = initialPrioritySeverity
        self.onPick = onPick
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

        priorityLabel.text = "Priority (optional)"
        priorityLabel.font = .preferredFont(forTextStyle: .subheadline)
        priorityLabel.adjustsFontForContentSizeCategory = true
        priorityLabel.textColor = .appTextSecondary
        priorityLabel.numberOfLines = 1

        priorityControl.selectedSegmentIndex = {
            switch initialPrioritySeverity {
            case .none:
                return 0
            case .low:
                return 1
            case .medium:
                return 2
            case .high:
                return 3
            }
        }()

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .appAccent
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        doneButton.setTitle("Done", for: .normal)
        doneButton.tintColor = .appAccent
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12

        let priorityStack = UIStackView(arrangedSubviews: [priorityLabel, priorityControl])
        priorityStack.axis = .vertical
        priorityStack.alignment = .fill
        priorityStack.spacing = 8

        let timeHeader = UIStackView(arrangedSubviews: [timeLabel, UIView(), timeToggle])
        timeHeader.axis = .horizontal
        timeHeader.alignment = .center
        timeHeader.spacing = 10

        let timeStack = UIStackView(arrangedSubviews: [timeHeader, timePicker])
        timeStack.axis = .vertical
        timeStack.alignment = .fill
        timeStack.spacing = 8

        let stack = UIStackView(arrangedSubviews: [titleLabel, datePicker, timeStack, priorityStack, buttons])
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

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapDone() {
        let picked = Calendar.current.startOfDay(for: datePicker.date)
        let minutes: Int? = timeToggle.isOn ? Self.minutesSinceMidnight(from: timePicker.date) : nil
        let severity: ChalkboardItemPrioritySeverity? = {
            switch priorityControl.selectedSegmentIndex {
            case 1: return .low
            case 2: return .medium
            case 3: return .high
            default: return nil
            }
        }()
        // Invoke the callback after dismissal to avoid presenting/animating over an active sheet.
        dismiss(animated: true) { [onPick] in
            onPick(picked, minutes, severity)
        }
    }
}

private extension DatePickerSheetViewController {
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
