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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack {
                    TagTextEditor(viewModel: viewModel)
                    
                    switch viewModel.viewState {
                    case .empty:
                        Text("No tags yet. Add one above.")
                            .foregroundColor(.appTextSecondary)
                            .font(.body)
                            .padding(.top, 24)
                        
                    case .loaded:
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
                        
                    default:
                        EmptyView()
                    }
                    Spacer()
                }
            }
            .navigationTitle("The New Chalkboard")
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
        .foregroundColor(.appTextPrimary)
        .onSubmit {
            viewModel.tagInputText = ""
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.appBorder, lineWidth: 1)
        )
        .padding()
    }
}
