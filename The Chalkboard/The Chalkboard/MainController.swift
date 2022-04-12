//
//  ViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/29/22.
//

import UIKit

extension UIColor {
    static var greenColor = UIColor(red: 77/255, green: 125/255, blue: 90/255, alpha: 1)
}

extension UITextField {
    func makeFontDynamic() {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        font = UIFont(name: "GillSans-Italic", size: customFont)
        adjustsFontSizeToFitWidth = true
    }
    
    func makePlaeceholderDynamic(string: String) {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        attributedPlaceholder = NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: UIFont(name: "GillSans-Italic", size: customFont)!])
        adjustsFontForContentSizeCategory = true
        adjustsFontSizeToFitWidth = true
        isAccessibilityElement = true
    }
}

extension UILabel {
    func makeFontDynamic() {
        let customFont = UIFont.preferredFont(forTextStyle: .title3).pointSize
        font = UIFont(name: "GillSans-Italic", size: customFont)
        adjustsFontSizeToFitWidth = true
    }
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
//        tf.makePlaeceholderDynamic(string: "Enter something")
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
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openInput))
        navigationItem.rightBarButtonItem?.tintColor = .label
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
        textField.addTarget(self, action: #selector(input), for: .editingChanged)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        let stackView = UIStackView(arrangedSubviews: [textField, addButton])
        stackView.distribution = .fillProportionally
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(stackView)
        
        inputHeightConstrain?.constant = 50.0
        
        inputHeightConstrain = stackView.heightAnchor.constraint(equalToConstant: inputHeightConstrain?.constant ?? 0.0)
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        inputHeightConstrain?.isActive = true
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
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
        guard let inputText = textField.text else { return }
        print(inputText)
        textField.text = ""
        items.append(inputText)
        print(items)
        tableView.reloadData()
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
extension MainController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
