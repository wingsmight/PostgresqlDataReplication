//
//  ContentView.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import SwiftUI

struct ContentView: View {
    private let DATABASE_NUMBER = 1
    
    private var tableChangeLog = TableChangeLog()
    
    
    var body: some View {
        VStack {
            Button {
                let updatedRow = Imitation.update(databaseNumber: DATABASE_NUMBER)
                tableChangeLog.insert(row: updatedRow!.oldRow, databaseNumber: DATABASE_NUMBER, operation: "Строка была изменена.До:")
                tableChangeLog.insert(row: updatedRow!.newRow, databaseNumber: DATABASE_NUMBER, operation: "Строка была изменена.После:")
            } label: {
                Label("Update", systemImage: "arrow.clockwise")
            }
            .padding(.top)
            
            Button {
                let insertedRow = Imitation.insert(databaseNumber: DATABASE_NUMBER)
                tableChangeLog.insert(row: insertedRow!, databaseNumber: DATABASE_NUMBER, operation: "Строка была вставлена")
            } label: {
                Label("Insert", systemImage: "text.insert")
            }
            
            Button {
                let deletedRow = Imitation.delete(databaseNumber: DATABASE_NUMBER)
                tableChangeLog.insert(row: deletedRow!, databaseNumber: DATABASE_NUMBER, operation: "Строка была удалена")
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear() {
            SqlRequest.createSequence()
        }
        .onDisappear {
            tableChangeLog.saveToFile(fileUrl: URL(fileURLWithPath: "/Users/user/Downloads/devices_changelog.txt"))
        }
    }
}

    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
