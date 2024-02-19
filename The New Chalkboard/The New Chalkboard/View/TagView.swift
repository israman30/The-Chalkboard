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
}

#Preview {
    TagView(row: TagModel(name: "The Tag"), viewModel: TagsViewModel())
}
