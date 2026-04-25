//
//  ViewController.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/29/22.
//

import UIKit

protocol PresentPickerProtocol {
    func presentDatePicker(title: String, initialDate: Date, onPick: @escaping (Date) -> Void)
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
    
    var itemViewModel = ItemViewModel()

    /// Persistence-backed store used for all CRUD in this controller.
    /// Keeping Core Data behind `ChalkboardItemStoring` prevents Core Data from leaking into UI code.
    private let itemStore: ChalkboardItemStoring = ChalkboardItemStore.shared
    
    var inputHeightConstrain: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The Chalkboard"
        updateInputToggleButton()
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
        textField.addTarget(self, action: #selector(input), for: .editingChanged)
        setMainUI()
        // READ: Load persisted items from Core Data.
        loadItems()
        applyViewState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // READ: Refresh from disk in case another screen changed items.
        loadItems()
    }

    private func loadItems() {
        do {
            itemViewModel.items = try itemStore.fetchAll()
            tableView.reloadData()
        } catch {
            assertionFailure("Failed to fetch items: \(error)")
        }
    }

    private func updateInputToggleButton() {
        let symbolName = itemViewModel.isOpen ? "xmark.circle" : "plus.circle"
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: symbolName, withConfiguration: config)

        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(openInput))
        button.accessibilityLabel = itemViewModel.isOpen ? "Close input" : "Add item"
        navigationItem.rightBarButtonItem = button
    }
    
    @objc func input() {
        let hasInput = textField.text?.isEmpty == false
        addButton.isEnabled = hasInput
        addButton.setTitleColor(hasInput ? .white : .systemGray, for: .normal)
        addButton.backgroundColor = hasInput ? .greenColor : .systemGray4
    }
    
    @objc func add() {
        let rawText = textField.text ?? ""
        let inputText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputText.isEmpty else { return }

        view.endEditing(true)

        presentDatePicker(title: "Date added", initialDate: Date()) { [weak self] selectedDate in
            guard let self else { return }

            self.textField.text = ""
            self.input()

            do {
                // CREATE: Persist the new item, then append to the in-memory list driving the table view.
                let newItem = try self.itemStore.create(text: inputText, date: selectedDate, isCompleted: false)
                let newIndex = self.itemViewModel.items.count
                self.itemViewModel.items.append(newItem)
                self.applyViewState()

                let indexPath = IndexPath(row: newIndex, section: 0)
                DispatchQueue.main.async {
                    self.tableView.performBatchUpdates {
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                    } completion: { _ in
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            } catch {
                assertionFailure("Failed to create item: \(error)")
            }
        }
    }
    
    @objc func openInput() {
        itemViewModel.isOpen.toggle()
        
        inputHeightConstrain?.constant = itemViewModel.isOpen ? 50 : 0
        addButton.setTitle(itemViewModel.isOpen ? "Add" : "", for: .normal)
        
        if !itemViewModel.isOpen {
            view.endEditing(true)
        }
        updateInputToggleButton()
        animateLayout()
    }
    
    private func animateLayout() {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

}

extension MainController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemViewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.mainCell.rawValue, for: indexPath) as! MainCell
        cell.bind(itemViewModel.items[indexPath.row])
        cell.onDetailTapped = { [weak self, weak tableView] cell in
            guard
                let self,
                let tableView,
                let indexPath = tableView.indexPath(for: cell)
            else { return }
            self.presentItemDetail(at: indexPath)
        }
        cell.onTitleTapped = { [weak self, weak tableView] cell in
            guard
                let self,
                let tableView,
                let indexPath = tableView.indexPath(for: cell)
            else { return }
            
            self.itemViewModel.items[indexPath.row].isCompleted.toggle()
            let updated = self.itemViewModel.items[indexPath.row]
            do {
                // UPDATE: Persist the completion toggle.
                _ = try self.itemStore.setCompleted(id: updated.id, isCompleted: updated.isCompleted)
            } catch {
                assertionFailure("Failed to update completion: \(error)")
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            let item = self.itemViewModel.items[indexPath.row]
            do {
                // DELETE: Remove from Core Data first, then update the table view.
                try self.itemStore.delete(id: item.id)
                self.itemViewModel.items.remove(at: indexPath.row)
                applyViewState()

                tableView.performBatchUpdates {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                } completion: { _ in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

                completion(true)
            } catch {
                assertionFailure("Failed to delete item: \(error)")
                completion(false)
            }
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
}

extension MainController: PresentPickerProtocol {
    func presentDatePicker(title: String, initialDate: Date, onPick: @escaping (Date) -> Void) {
        let pickerVC = DatePickerSheetViewController(
            titleText: title,
            initialDate: initialDate,
            onPick: onPick
        )
        pickerVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = pickerVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(pickerVC, animated: true)
    }
}

private extension MainController {
    func applyViewState() {
        switch itemViewModel.viewState {
        case .empty:
            tableView.backgroundView = makeEmptyStateView()
        case .loaded:
            tableView.backgroundView = nil
        default:
            tableView.backgroundView = nil
        }
    }
    
    func makeEmptyStateView() -> UIView {
        let container = UIView()
        
        let imageView = UIImageView(image: UIImage(systemName: "square.and.pencil"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "No items yet.\nTap + to add your first one."
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 34),
            imageView.widthAnchor.constraint(equalToConstant: 34),
            
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20)
        ])
        
        return container
    }
    
    func presentEditItem(at indexPath: IndexPath) {
        let item = itemViewModel.items[indexPath.row]
        
        let editVC = EditItemSheetViewController(
            titleText: "Update item",
            initialText: item.text,
            initialDate: item.date
        ) { [weak self] updatedText, updatedDate in
            guard let self else { return }
            let existing = self.itemViewModel.items[indexPath.row]
            do {
                // UPDATE: Persist changes from the edit sheet.
                let updated = try self.itemStore.update(
                    id: existing.id,
                    text: updatedText,
                    date: updatedDate,
                    isCompleted: existing.isCompleted
                )
                self.itemViewModel.items[indexPath.row] = updated
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            } catch {
                assertionFailure("Failed to update item: \(error)")
            }
        }
        
        editVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = editVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(editVC, animated: true)
    }
    
    func presentItemDetail(at indexPath: IndexPath) {
        let item = itemViewModel.items[indexPath.row]
        let detailVC = ItemDetailSheetViewController(
            item: item,
            onToggleCompleted: { [weak self, weak tableView] isCompleted in
                guard let self, let tableView else { return }
                self.itemViewModel.items[indexPath.row].isCompleted = isCompleted
                let updated = self.itemViewModel.items[indexPath.row]
                do {
                    // UPDATE: Persist completion toggle coming from the detail sheet.
                    _ = try self.itemStore.setCompleted(id: updated.id, isCompleted: updated.isCompleted)
                } catch {
                    assertionFailure("Failed to update completion: \(error)")
                }
                tableView.reloadRows(at: [indexPath], with: .automatic)
            },
            onUpdate: { [weak self, weak tableView] updatedText, updatedDate in
                guard let self, let tableView else { return }

                let existing = self.itemViewModel.items[indexPath.row]
                do {
                    // UPDATE: Persist changes coming from the detail sheet.
                    let updated = try self.itemStore.update(
                        id: existing.id,
                        text: updatedText,
                        date: updatedDate,
                        isCompleted: existing.isCompleted
                    )
                    self.itemViewModel.items[indexPath.row] = updated
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                } catch {
                    assertionFailure("Failed to update item: \(error)")
                }
            }
        )
        present(detailVC, animated: true)
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
private struct MainControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = MainController()
        vc.itemViewModel.items = [
            ChalkboardItem(text: "Finish the UI polish for the chalkboard cells.", date: Date()),
            ChalkboardItem(text: "Swipe left on a cell to delete it.", date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            ChalkboardItem(text: "Tap a cell to update its date.", date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        ]
        vc.loadViewIfNeeded()
        vc.tableView.reloadData()
        return UINavigationController(rootViewController: vc)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

@available(iOS 13.0, *)
struct MainController_Previews: PreviewProvider {
    static var previews: some View {
        MainControllerPreview()
            .ignoresSafeArea()
            .previewDisplayName("Main View")
    }
}
#endif
