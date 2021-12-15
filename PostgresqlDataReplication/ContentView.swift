//
//  ContentView.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button {
                Imitation.update(databaseNumber: 1)
            } label: {
                Label("Update", systemImage: "arrow.clockwise")
            }
            .padding(.top)
            
            Button {
                Imitation.insert(databaseNumber: 1)
            } label: {
                Label("Insert", systemImage: "text.insert")
            }
            
            Button {
                Imitation.delete(databaseNumber: 1)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear() {
            SqlRequest.createSequence()
        }
    }
}

    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
