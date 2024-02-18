//
//  HomeView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

struct TagModel: Identifiable, Hashable {
    var id = UUID().uuidString
    var name: String
    var size: CGFloat = 0
}

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.width
}

extension String {
    func getSize() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return size.width
    }
}

class TagsViewModel: ObservableObject {
    
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
        var rows: [[TagModel]] = []
        var currentRow: [TagModel] = []
        var totalWidth: CGFloat = 0
        let screenWidth = UIScreen.screenWidth - 10
        let tagSpacing: CGFloat = 14 + 30 + 6 + 6
        
        if !tags.isEmpty {
            for index in  0..<tags.count {
                tags[index].size = tags[index].name.getSize()
            }
            
            tags.forEach { tag in
                totalWidth += (tag.size + tagSpacing)
                
                if totalWidth > screenWidth{
                    totalWidth = (tag.size + tagSpacing)
                    rows.append(currentRow)
                    currentRow.removeAll()
                    currentRow.append(tag)
                } else {
                    currentRow.append(tag)
                }
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow.removeAll()
            }
            
            self.rows = rows
        } else {
            rows = []
        }
    }
    
    func addTag() {
        tags.append(TagModel(name: tagInputText))
        tagInputText = ""
        getTags()
    }
    
    func removeTag(by id: String){
        tags = tags.filter { $0.id != id }
        getTags()
    }
}

struct HomeView: View {
    
    @StateObject var viewModel = TagsViewModel()
    
    var body: some View {
        NavigationView  {
            VStack {
                TextField("Enter tag", text: $viewModel.tagInputText, onCommit: {
                    viewModel.addTag()
                })
                .onSubmit {
                    viewModel.tagInputText = ""
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder()
                        .foregroundColor(.black)
                )
                .padding()
                
                VStack(alignment: .leading, spacing: 4){
                    ForEach(viewModel.rows, id:\.self) { rows in
                        HStack(spacing: 6){
                            ForEach(rows) { row in
                                
                                Text(row.name)
                                    .font(.system(size: 16))
                                    .padding(.leading, 14)
                                    .padding(.trailing, 30)
                                    .padding(.vertical, 8)
                                    .background(
                                        ZStack(alignment: .trailing) {
                                            Capsule()
                                                .fill(.gray.opacity(0.3))
                                            Button{
                                                viewModel.removeTag(by: row.id)
                                            } label:{
                                                Image(systemName: "xmark")
                                                    .frame(width: 15, height: 15)
                                                    .padding(.trailing, 8)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    )
                            }
                        }
                        .frame(height: 28)
                        .padding(.bottom, 10)
                    }
                }
                .padding(24)
                .navigationTitle("The New Chalkboard")
                Spacer()
            }
        }
    }
}


#Preview {
    HomeView()
}
