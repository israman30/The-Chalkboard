//
//  HomeView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = TagsViewModel()
    
    var body: some View {
        NavigationView  {
            VStack {
                TagTextEditor(viewModel: viewModel)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.rows, id:\.self) { rows in
                        HStack(spacing: 6) {
                            ForEach(rows) { row in
                                TagView(row: row, viewModel: viewModel)
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

struct TagTextEditor: View {
    @State var viewModel: TagsViewModel
    var body: some View {
        TextField("Enter tag", text: $viewModel.tagInputText, onCommit: {
            viewModel.addTag()
        })
        .font(.title2)
        .onSubmit {
            viewModel.tagInputText = ""
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder()
                .foregroundColor(Color(.systemGray4))
        )
        .padding()
    }
}
