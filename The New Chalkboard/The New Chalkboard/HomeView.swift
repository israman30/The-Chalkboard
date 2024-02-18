//
//  HomeView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

struct TagModel: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var size: CGFloat = 0
}

struct HomeView: View {
    
    @State var text = ""
    @State var tagGroup = [String]()
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    TextField("Enter something..", text: $text)
                        .padding()
                        .font(.title)
                        .border(Color.black)
                    HStack {
                        Spacer()
                        Button {
                            self.addTag()
                        } label: {
                            Text("Add")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                }
                Text("bottom")
                    .padding()
                    .background(Color(.systemGray4))
                    .foregroundColor(Color(.label))
                ForEach(tagGroup, id: \.self) { item in
                    HStack {
                        Text(item)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 5)
            .navigationTitle("The New Chalkboard")
        }
        
    }
    
    func addTag() {
        tagGroup.append(text)
        text = ""
    }
}

#Preview {
    HomeView()
}
