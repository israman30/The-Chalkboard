//
//  TagView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/18/24.
//

import SwiftUI

struct TagView: View {
    var row: TagModel
    var viewModel: TagsViewModel
    
    var body: some View {
        VStack {
            Text(row.name)
                .customTag {
                    viewModel.removeTag(by: row.id)
                }
            /// `Saving this commented code for reference`
//                .font(.system(size: 16))
//                .fontWeight(.light)
//                .padding(.leading, 14)
//                .padding(.trailing, 30)
//                .padding(.vertical, 8)
//                .background(
//                    ZStack(alignment: .trailing) {
//                        Capsule()
//                            .fill(.gray.opacity(0.3))
//                        Button {
//                            viewModel.removeTag(by: row.id)
//                        } label: {
//                            Image(systemName: "xmark")
//                                .font(.system(size: 18))
//                                .padding(.horizontal, 8)
//                                .foregroundColor(.red)
//                        }
//                    }
//                )
            
        }
    }
}

#Preview {
    TagView(row: TagModel(name: "The Tag"), viewModel: TagsViewModel())
}

struct CustomTag: ViewModifier {
    var action: () -> Void
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .fontWeight(.light)
            .padding(.leading, 14)
            .padding(.trailing, 30)
            .padding(.vertical, 8)
            .background(
                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(.gray.opacity(0.3))
                    Button {
                        action()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .padding(.horizontal, 8)
                            .foregroundColor(.red)
                    }
                }
            )
    }
    
}
extension View {
    func customTag(action: @escaping () -> Void) -> some View {
        modifier(CustomTag(action: action))
    }
}
