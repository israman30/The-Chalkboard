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
                .foregroundColor(.appTextPrimary)
                .customTag {
                    viewModel.removeTag(by: row.id)
                }
            
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
            // Extra trailing space reserves room for the close (“x”) button.
            .padding(.trailing, 30)
            .padding(.vertical, 8)
            .background(
                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(Color.appElevatedSurface)
                        .overlay(
                            Capsule().stroke(Color.appBorder, lineWidth: 1)
                        )
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
