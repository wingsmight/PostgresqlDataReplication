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
            Text("Tap on button!")
                .padding()
            Button {
                SqlRequest.requestTest()
            } label: {
                Label("Request", systemImage: "server.rack")
            }
        }
        .padding()
    }
}
    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
