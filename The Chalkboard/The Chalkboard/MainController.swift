//
//  ViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/29/22.
//

import UIKit

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
    
    var items = [String]()
    
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

        textField.text = ""
        input()

        let newIndex = items.count
        items.append(inputText)

        let indexPath = IndexPath(row: newIndex, section: 0)
        DispatchQueue.main.async {
            self.tableView.performBatchUpdates {
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            } completion: { _ in
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
        label.text = "10/10/1001"
        label.textColor = .secondaryLabel
        return label
    }()
    
    func configure(item: String) {
        titleLabel.text = item
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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
