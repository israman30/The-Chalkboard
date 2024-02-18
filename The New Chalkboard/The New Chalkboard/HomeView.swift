//
//  HomeView.swift
//  The New Chalkboard
//
//  Created by Israel Manzo on 2/17/24.
//

import SwiftUI

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
                            
                        } label: {
                            Text("Add")
                        }
                    }
                    
                }
                
                Text("bottom")
                    .padding()
                    .background(Color.yellow)
                Spacer()
            }
            .navigationTitle("The New Chalkboard")
        }
        
    }
    
    func addTag() {
        tagGroup.append(text)
    }
}

#Preview {
    HomeView()
}
