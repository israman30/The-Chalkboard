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
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The Chalkboard"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    @objc func add() {
        print("Added")
    }

}

