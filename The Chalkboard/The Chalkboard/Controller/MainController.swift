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
    
    let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor
        return view
    }()

    let inputTextView: UITextView = {
        let tv = AutoGrowingTextView()
        tv.backgroundColor = .clear
        tv.textColor = .label
        tv.font = UIFont(name: "GillSans-Italic", size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
        tv.adjustsFontForContentSizeCategory = true
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = false
        tv.keyboardType = .default
        tv.autocapitalizationType = .sentences
        tv.accessibilityLabel = "New item"
        return tv
    }()

    let inputPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter something.."
        label.textColor = .secondaryLabel
        label.font = UIFont(name: "GillSans-Italic", size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        return label
    }()
    
    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.isEnabled = false
        btn.clipsToBounds = true
        btn.layer.cornerCurve = .continuous
        return btn
    }()

    let inputBarStackView = UIStackView()
    
    var itemViewModel = ItemViewModel()

    /// Persistence-backed store used for all CRUD in this controller.
    /// Keeping Core Data behind `ChalkboardItemStoring` prevents Core Data from leaking into UI code.
    private let itemStore: ChalkboardItemStoring = ChalkboardItemStore.shared
    
    var inputHeightConstrain: NSLayoutConstraint?
    private let inputMinHeight: CGFloat = 50
    private let inputMaxHeight: CGFloat = 150

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "The Chalkboard"
        updateInputToggleButton()
        addButton.addTarget(self, action: #selector(add), for: .touchUpInside)
        inputTextView.delegate = self
        setMainUI()
        configureAddButton()
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
        guard itemViewModel.isOpen else {
            inputPlaceholderLabel.isHidden = true
            addButton.isEnabled = false
            updateAddButtonPresentation(animated: false)
            return
        }

        let trimmed = (inputTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasInput = !trimmed.isEmpty

        inputPlaceholderLabel.isHidden = !trimmed.isEmpty
        addButton.isEnabled = hasInput
        updateAddButtonPresentation(animated: true)

        updateInputHeight(animated: true)
    }
    
    @objc func add() {
        guard itemViewModel.isOpen else { return }
        guard presentedViewController == nil else { return }

        let rawText = inputTextView.text ?? ""
        let inputText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputText.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        view.endEditing(true)

        presentDatePicker(title: "Date added", initialDate: Date()) { [weak self] selectedDate in
            guard let self else { return }

            self.inputTextView.text = ""
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
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                assertionFailure("Failed to create item: \(error)")
            }
        }
    }
    
    @objc func openInput() {
        itemViewModel.isOpen.toggle()
        
        inputHeightConstrain?.constant = itemViewModel.isOpen ? preferredOpenInputHeight() : 0
        updateAddButtonPresentation(animated: false)
        
        if !itemViewModel.isOpen {
            view.endEditing(true)
            // Prevent placeholder from flashing when the bar is collapsed to 0.
            inputPlaceholderLabel.isHidden = true
            addButton.isEnabled = false
        }
        updateInputToggleButton()
        animateLayout()

        if itemViewModel.isOpen {
            input()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
                self?.inputTextView.becomeFirstResponder()
            }
        }
    }
    
    private func animateLayout() {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

}

private extension MainController {
    func configureAddButton() {
        addButton.accessibilityLabel = "Add"
        addButton.accessibilityHint = "Adds the new item after selecting a date"
        addButton.titleLabel?.adjustsFontForContentSizeCategory = true

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.cornerStyle = .capsule
            config.image = UIImage(systemName: "plus")
            config.imagePadding = 6
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)

            if let base = UIFont(name: "GillSans-Italic", size: UIFont.preferredFont(forTextStyle: .headline).pointSize) {
                let scaled = UIFontMetrics(forTextStyle: .headline).scaledFont(for: base)
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = scaled
                    return outgoing
                }
            }
            addButton.configuration = config

            addButton.configurationUpdateHandler = { [weak self] button in
                guard let self else { return }
                var config = button.configuration ?? UIButton.Configuration.filled()

                let showTitle = self.itemViewModel.isOpen
                let enabled = button.isEnabled && showTitle
                config.title = showTitle ? "Add" : ""
                if enabled, button.isHighlighted {
                    config.baseBackgroundColor = UIColor.greenColor.withAlphaComponent(0.85)
                } else {
                    config.baseBackgroundColor = enabled ? .greenColor : .systemGray4
                }
                config.baseForegroundColor = enabled ? .white : .systemGray
                button.configuration = config
            }
        } else {
            addButton.titleLabel?.font = UIFont(name: "GillSans-Italic", size: 20)
            addButton.setTitle("Add", for: .normal)
            addButton.setTitleColor(.systemGray, for: .normal)
            addButton.setImage(UIImage(systemName: "plus"), for: .normal)
            addButton.imageView?.contentMode = .scaleAspectFit
            addButton.tintColor = .systemGray
            addButton.semanticContentAttribute = .forceLeftToRight
            addButton.contentHorizontalAlignment = .center
            addButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
            addButton.backgroundColor = .systemGray4
            addButton.layer.cornerRadius = 22
            addButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        }

        updateAddButtonPresentation(animated: false)
    }

    func updateAddButtonPresentation(animated: Bool) {
        let updates = {
            if #available(iOS 15.0, *) {
                self.addButton.setNeedsUpdateConfiguration()
            } else {
                let showTitle = self.itemViewModel.isOpen
                self.addButton.setTitle(showTitle ? "Add" : "", for: .normal)

                let enabled = self.addButton.isEnabled && showTitle
                self.addButton.setTitleColor(enabled ? .white : .systemGray, for: .normal)
                self.addButton.tintColor = enabled ? .white : .systemGray
                self.addButton.backgroundColor = enabled ? .greenColor : .systemGray4
                self.addButton.alpha = enabled ? 1.0 : 0.85
            }
        }

        if animated {
            UIView.transition(with: addButton, duration: 0.15, options: [.transitionCrossDissolve, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }
}

protocol InputHeightProtocol {
    func preferredOpenInputHeight() -> CGFloat
    func updateInputHeight(animated: Bool)
}

extension MainController: InputHeightProtocol {
    func preferredOpenInputHeight() -> CGFloat {
        // When opening, start at least at the minimum height and grow if there's existing text.
        updateInputHeight(animated: false)
        return inputHeightConstrain?.constant ?? inputMinHeight
    }

    func updateInputHeight(animated: Bool) {
        guard itemViewModel.isOpen else { return }

        view.layoutIfNeeded()

        let availableWidth = max(1, inputContainerView.bounds.width)
        let padding: CGFloat = 20 // left + right inside the input container
        let textWidth = max(1, availableWidth - padding)

        let fitting = inputTextView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))
        let target = min(max(fitting.height + 20, inputMinHeight), inputMaxHeight) // + top/bottom padding

        inputTextView.isScrollEnabled = target >= inputMaxHeight

        guard inputHeightConstrain?.constant != target else { return }
        inputHeightConstrain?.constant = target

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension MainController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        input()
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

protocol StateControllerProtocol {
    func applyViewState()
    func makeEmptyStateView() -> UIView
}

protocol PresentViewProtocol {
    func presentEditItem(at indexPath: IndexPath)
    func presentItemDetail(at indexPath: IndexPath)
}

extension MainController: StateControllerProtocol, PresentViewProtocol {
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
