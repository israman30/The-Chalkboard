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
        navigationItem.rightBarButtonItem?.tintColor = .label
        
        /// TableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(MainCell.self, forCellReuseIdentifier: Cell.mainCell.rawValue)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = true
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        
        let stackView = UIStackView(arrangedSubviews: [textField, addButton])
        stackView.distribution = .fillProportionally
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(stackView)
        
        inputHeightConstrain = stackView.heightAnchor.constraint(equalToConstant: 0.0)
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
}
