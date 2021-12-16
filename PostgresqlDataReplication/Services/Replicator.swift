//
//  Replicator.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class Replicator {
    private var updatePeriodSeconds: Double
    private var lastUpdateDate = Date(timeIntervalSince1970: 0)
    private var isWorking = false
    
    
    public init(updatePeriodSeconds: Double) {
        self.updatePeriodSeconds = updatePeriodSeconds
    }
    
    
    public func start() {
        isWorking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + updatePeriodSeconds, execute: updateDatabases)
    }
    public func stop() {
        isWorking = false
    }
    
    private func updateDatabases() {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        
        try! connection.beginTransaction()
        
        let text = "lock table pmib8502.devices_in_db1, pmib8502.devices_in_db2, pmib8502.devices_in_db3 in exclusive mode"
        let lockTableStatement = try! connection.prepareStatement(text: text)
        defer { lockTableStatement.close() }
        try! lockTableStatement.execute()
        
        try! connection.commitTransaction()
        
        var rows = getChangelogRows();
        
        removeCollisions(rows: &rows)
        
        for row in rows {
            let sourceDatabaseNumber = try! row.columns[1].int()
            let operation = (try! row.columns[2].string()).split(separator: " ")[2].description.split(separator: ".")[0].description
            let deviceRow = try! DeviceRow(id: row.columns[4].string(), title: row.columns[5].string(), developer: row.columns[6].string(), type: row.columns[7].string())
            let fullOperationDescription = try! row.columns[8].string()
            let operationDate = try! row.columns[9].string()
            
            for databaseNumber in 1...3 {
                switch operation {
                case "изменена":
                    Database.update(databaseNumber: databaseNumber, deviceRow: deviceRow, operation: fullOperationDescription, operationDate: operationDate)
                    
                    break
                case "вставлена":
                    Database.insert(databaseNumber: databaseNumber, deviceRow: deviceRow, operation: fullOperationDescription, operationDate: operationDate)
                    
                    break
                case "удалена":
                    Database.delete(databaseNumber: databaseNumber, deviceNumber: deviceRow.id)
                    
                    break
                default:
                    fatalError("operation doesn't exist")
                }
            }
        }
        
        lastUpdateDate = Date()
        print("lastUpdateDate = \(lastUpdateDate)")
        if isWorking {
            DispatchQueue.main.asyncAfter(deadline: .now() + updatePeriodSeconds, execute: updateDatabases)
        }
    }
    private func removeCollisions(rows: inout [Row]) {
        rows.reverse()
        
        var rowIndex = 0
        while rowIndex < (rows.count - 1) {
            let collisionRow = rows[rowIndex]
            var checkRowIndex = rowIndex + 1
            while checkRowIndex < rows.count {
                let checkRow = rows[checkRowIndex]
                if try! checkRow.columns[4].string() == collisionRow.columns[4].string() {
                    rows.remove(at: checkRowIndex)
                    checkRowIndex -= 1
                }
                
                checkRowIndex += 1
            }
            
            rowIndex += 1
        }
    }
    private func getChangelogRows() -> [Row] {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        
        let text = """
            SELECT *
            FROM pmib8502.devices_changelog
            WHERE operation_date >= '\(lastUpdateDate.toSQLDate())'
        """
        let lastRowsStatement = try! connection.prepareStatement(text: text)
        defer { lastRowsStatement.close() }
        try! lastRowsStatement.execute()
        
        let cursor = try! lastRowsStatement.execute()
        defer { cursor.close() }
        
        var rows = [Row]()
        for row in cursor {
            rows.append(try! row.get())
        }
        
        return rows
    }
}
