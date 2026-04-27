//
//  MainView.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/11/23.
//

import UIKit

extension MainController {
    
    func setMainUI() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem?.tintColor = .appAccent
        
        /// TableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(MainCell.self, forCellReuseIdentifier: Cell.mainCell.rawValue)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .appBackground
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.clipsToBounds = true
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        clearInputButton.translatesAutoresizingMaskIntoConstraints = false

        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(inputPlaceholderLabel)
        inputContainerView.addSubview(clearInputButton)

        NSLayoutConstraint.activate([
            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 10),
            inputTextView.trailingAnchor.constraint(equalTo: clearInputButton.leadingAnchor, constant: -clearInputButtonSpacing),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -10),

            inputPlaceholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor),
            inputPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: inputTextView.trailingAnchor),
            inputPlaceholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor),

            clearInputButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -10),
            clearInputButton.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            clearInputButton.widthAnchor.constraint(equalToConstant: clearInputButtonSize),
            clearInputButton.heightAnchor.constraint(equalToConstant: clearInputButtonSize)
        ])

        inputBarStackView.arrangedSubviews.forEach { inputBarStackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        inputBarStackView.addArrangedSubview(inputContainerView)
        inputBarStackView.addArrangedSubview(addButton)
        // Keep the Add button from shrinking when text is long.
        inputBarStackView.distribution = .fill
        inputBarStackView.axis = .horizontal
        inputBarStackView.alignment = .bottom
        inputBarStackView.spacing = 10
        inputBarStackView.translatesAutoresizingMaskIntoConstraints = false
        inputBarStackView.clipsToBounds = true

        addButton.setContentHuggingPriority(.required, for: .horizontal)
        addButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addButton.setContentHuggingPriority(.required, for: .vertical)
        addButton.setContentCompressionResistancePriority(.required, for: .vertical)
        inputContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        inputContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
            addButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            inputContainerView.heightAnchor.constraint(equalTo: inputBarStackView.heightAnchor)
        ])
        
        view.addSubview(tableView)
        view.addSubview(inputBarStackView)
        
        // The input bar is collapsible: we animate this single height constraint between 0 and a
        // measured height, which keeps the rest of the layout stable.
        inputHeightConstrain = inputBarStackView.heightAnchor.constraint(equalToConstant: 0.0)
        inputBarStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        inputBarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        inputBarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        inputHeightConstrain?.isActive = true
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: inputBarStackView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
