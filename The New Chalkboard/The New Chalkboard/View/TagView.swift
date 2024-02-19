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
                            viewModel.removeTag(by: row.id)
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
}

#Preview {
    TagView(row: TagModel(name: "The Tag"), viewModel: TagsViewModel())
}
