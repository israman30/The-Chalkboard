//
//  HomeView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

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
