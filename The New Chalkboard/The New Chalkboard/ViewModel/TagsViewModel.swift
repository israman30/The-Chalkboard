//
//  TagsViewModel.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/18/24.
//

import SwiftUI

protocol TagsProtocol: ObservableObject {
    var rows: [[TagModel]] { get set }
    var tags: [TagModel] { get set }
    var tagInputText: String { get set }
    func getTags()
    func addTag()
    func removeTag(by id: String)
}

class TagsViewModel: TagsProtocol {
    
    @Published var rows: [[TagModel]] = []
    @Published var tags: [TagModel] = []
    @Published var tagInputText = ""
    
    init() {
        tags = [
            TagModel(name: "Xcode"),
            TagModel(name: "Android Studio"),
            TagModel(name: "VS Code"),
            TagModel(name: "Jetbrains")
        ]
        getTags()
    }
    
    func getTags() {
        var addedRows: [[TagModel]] = []
        var currentRow: [TagModel] = []
        var totalWidth: CGFloat = 0
        let screenWidth = UIScreen.screenWidth - 10
        let tagSpacing: CGFloat = 14 + 30 + 6 + 5
        
        if !tags.isEmpty {
            for index in 0..<tags.count {
                tags[index].size = tags[index].name.getSize()
            }
            
            tags.forEach { tag in
                totalWidth += (tag.size + tagSpacing)
                
                if totalWidth > screenWidth {
                    totalWidth = (tag.size + tagSpacing)
                    addedRows.append(currentRow)
                    currentRow.removeAll()
                    currentRow.append(tag)
                } else {
                    currentRow.append(tag)
                }
            }
            
            if !currentRow.isEmpty {
                addedRows.append(currentRow)
                currentRow.removeAll()
            }
            
            self.rows = addedRows
        } else {
            addedRows = []
        }
    }
    
    func addTag() {
        let newTag = TagModel(name: tagInputText)
        tags.append(newTag)
        getTags()
    }
    
    func removeTag(by id: String) {
        tags = tags.filter { $0.id != id }
        getTags()
    }
}
