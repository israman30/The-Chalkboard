//
//  ViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/29/22.
//

import UIKit

struct ChalkboardItem: Equatable {
    let text: String
    var date: Date
}

class MainController: UIViewController {
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.alwaysBounceVertical = false
        return tv
    }()
    
    let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter something.."
        tf.textColor = .label
        tf.makeFontDynamic()
        return tf
    }()
    
    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(UIColor.systemGray, for: .normal)
        btn.titleLabel?.font = UIFont(name: "GillSans-Italic", size: 20)
        btn.backgroundColor = .systemGray4
        btn.isEnabled = false
        btn.layer.cornerRadius = 2
        return btn
    }()
    
    var items = [ChalkboardItem]()
    
    var isOpen = false
    
    var inputHeightConstrain: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The Chalkboard"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openInput))
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
        textField.addTarget(self, action: #selector(input), for: .editingChanged)
        setMainUI()
        tableView.reloadData()
    }
    
    @objc func input() {
        guard let inputText = textField.text else { return }
        if !inputText.isEmpty {
            addButton.isEnabled = true
            addButton.setTitleColor(UIColor.white, for: .normal)
            addButton.backgroundColor = .greenColor
        } else {
            addButton.isEnabled = false
            addButton.setTitleColor(UIColor.systemGray, for: .normal)
            addButton.backgroundColor = .systemGray3
        }
    }
    
    @objc func add() {
        let rawText = textField.text ?? ""
        let inputText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputText.isEmpty else { return }

        view.endEditing(true)

        presentDatePicker(
            title: "Date added",
            initialDate: Date()
        ) { [weak self] selectedDate in
            guard let self else { return }

            self.textField.text = ""
            self.input()

            let newIndex = self.items.count
            self.items.append(ChalkboardItem(text: inputText, date: selectedDate))

            let indexPath = IndexPath(row: newIndex, section: 0)
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates {
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                } completion: { _ in
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    @objc func openInput() {
        if !isOpen {
            isOpen = true
            inputHeightConstrain?.constant = 50.0
            addButton.setTitle("Add", for: .normal)
        } else {
            isOpen = false
            inputHeightConstrain?.constant = 0.0
            addButton.setTitle("", for: .normal)
        }
        UIView.animate(withDuration: 0.2, delay: 0.0) {
            self.view.layoutIfNeeded()
        }
    }

}

enum Cell: String {
    case mainCell = "cell"
}

extension MainController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.mainCell.rawValue, for: indexPath) as! MainCell
        cell.configure(item: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]
        presentDatePicker(
            title: "Update date added",
            initialDate: item.date
        ) { [weak self] selectedDate in
            guard let self else { return }
            self.items[indexPath.row].date = selectedDate
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
}

class MainCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Test"
        label.numberOfLines = 0
        label.makeFontDynamic()
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .secondaryLabel
        return label
    }()
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    func configure(item: ChalkboardItem) {
        titleLabel.text = item.text
        dateLabel.text = "Date added: \(Self.dateFormatter.string(from: item.date))"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MainController {
    func presentDatePicker(title: String, initialDate: Date, onPick: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = initialDate
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        alert.view.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 12),
            datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -12),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 48),
            datePicker.heightAnchor.constraint(equalToConstant: 216)
        ])

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            onPick(datePicker.date)
        })

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }
}
