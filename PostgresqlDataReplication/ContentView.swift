//
//  ContentView.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import SwiftUI

struct ContentView: View {
    private let DATABASE_NUMBER = 1
    
    private let imitation = Imitation()
    
    
    @State private var replicator = Replicator(updatePeriodSeconds: 10.0)
    @State private var replicatorUpdatePeriodSeconds = ""
    @State private var replicatorUpdatePeriodTextField = false
    @State private var isImitationButtonDisabled = false
    @State private var isReplicatorButtonDisabled = false
    
    
    var body: some View {
        VStack {
            TextField("Интервал запуска РД", text: $replicatorUpdatePeriodSeconds)
                .frame(width: 200)
                .padding(.top)
                .disabled(replicatorUpdatePeriodTextField)
            
            Button {
                imitation.start()
                
                isImitationButtonDisabled = true
            } label: {
                Label("Запустить ИРС", systemImage: "play.fill")
            }
            .disabled(isImitationButtonDisabled)
            
            Button {
                replicator = Replicator(updatePeriodSeconds: Double(replicatorUpdatePeriodSeconds)!)
                replicator.start()
                
                isReplicatorButtonDisabled = true
                replicatorUpdatePeriodTextField = true
            } label: {
                Label("Запустить РД", systemImage: "play.fill")
            }
            .disabled(isReplicatorButtonDisabled || replicatorUpdatePeriodSeconds.isEmpty)
            .padding(.bottom)
            
            Button {
                isImitationButtonDisabled = false
                isReplicatorButtonDisabled = false
                
                imitation.stop()
                replicator.stop()
            } label: {
                Label("Остановить ИРС и РД", systemImage: "stop.fill")
            }
            .disabled(!isImitationButtonDisabled && !isReplicatorButtonDisabled)
            .padding()
        }
        .frame(width: 350)
        .padding()
        .onAppear() {
            for databaseNumber in 1...3 {
                Database.create(databaseNumber: databaseNumber)
            }
            
            SqlRequest.createSequence()
        }
        .onDisappear {
            imitation.stop()
            replicator.stop()
        }
    }
}

    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
