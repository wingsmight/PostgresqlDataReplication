//
//  Imitation.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class Imitation {
    typealias UpdatedRow = (oldRow: Row, newRow: Row)
    typealias InsertedRow = (Row)
    typealias DeletedRow = (Row)
    
    
    private var tableChangeLog = TableChangeLog()
    private var operatePeriodSeconds: Double
    private var isWorking = false
    
    
    public init() {
        operatePeriodSeconds = Double.random(in: 1.0...4.0)
    }
    
    
    public func start() {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        for databaseIndex in 1...3 {
            updateDeviceCount(databaseNumber: databaseIndex, connection: connection)
        }
                              
        operatePeriodSeconds = Double.random(in: 1.0...4.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + operatePeriodSeconds, execute: operate)
        
        isWorking = true
    }
    public func stop() {
        isWorking = false
        
        tableChangeLog.saveToFile(fileUrl: URL(fileURLWithPath: "/Users/user/Downloads/devices_changelog.txt"))
    }
    
    private func operate() {
        let databaseNumber = Int.random(in: 1...3)
        let operationIndex = Int.random(in: 0...2)
        
        switch operationIndex {
        case 0:
            let updatedRow = update(databaseNumber: databaseNumber)
            tableChangeLog.insert(row: updatedRow!.oldRow, databaseNumber: databaseNumber, operation: "Строка была изменена.До:")
            tableChangeLog.insert(row: updatedRow!.newRow, databaseNumber: databaseNumber, operation: "Строка была изменена.После:")
            
            break
        case 1:
            let deviceRow = DeviceRow(id: "", title: "Девайс\(Int.random(in: 1...100))", developer: "Комания\(Int.random(in: 1...100))", type: "неопределенный тип")
            let insertedRow = insert(databaseNumber: databaseNumber, deviceRow: deviceRow)
            tableChangeLog.insert(row: insertedRow!, databaseNumber: databaseNumber, operation: "Строка была вставлена")
            
            break
        case 2:
            let deletedRow = delete(databaseNumber: databaseNumber)
            tableChangeLog.insert(row: deletedRow!, databaseNumber: databaseNumber, operation: "Строка была удалена")
            
            break
        default:
            fatalError("operation index is out of range")
        }
        
        if isWorking {
            DispatchQueue.main.asyncAfter(deadline: .now() + operatePeriodSeconds, execute: operate)
        }
    }
    private func update(databaseNumber: Int) -> UpdatedRow? {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let oldRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "min")
        if oldRow == nil {
            return nil
        }
        print("old row = \(oldRow)")
        
        let text = "UPDATE pmib8502.devices_in_db\(databaseNumber) SET last_operation='обновление в БД\(databaseNumber)', last_operation_date=date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC' WHERE oid=(SELECT min(oid) FROM pmib8502.devices_in_db\(databaseNumber))"
        let updateRowStatement = try! connection.prepareStatement(text: text)
        defer { updateRowStatement.close() }
        try! updateRowStatement.execute()
        
        let newRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "min")
        if newRow == nil {
            return nil
        }
        print("new row = \(newRow)")
        
        return UpdatedRow(oldRow: oldRow!, newRow: newRow!)
    }
    private func insert(databaseNumber: Int, deviceRow: DeviceRow) -> Row? {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "INSERT INTO pmib8502.devices_in_db\(databaseNumber) (n_device, label, developer, type, last_operation, last_operation_date) VALUES (\(deviceRow.id.isEmpty ? "'D'||nextval('device_count')" : "'\(deviceRow.id)'"), '\(deviceRow.title)', '\(deviceRow.developer)', '\(deviceRow.type)', 'вставка в БД\(databaseNumber)', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC')"
        let insertedRowStatement = try! connection.prepareStatement(text: text)
        defer { insertedRowStatement.close() }
        
        do {
            let cursor = try insertedRowStatement.execute()
            defer { cursor.close() }
            
            let insertedRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "max")
            return insertedRow
        } catch {
            print(error)
        }

        return nil
    }
    private func delete(databaseNumber: Int) -> Row? {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let oldRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "max")
        if oldRow == nil {
            return nil
        }
        print("old row = \(oldRow?.columns)")
        
        let text = "DELETE FROM pmib8502.devices_in_db\(databaseNumber) WHERE oid=(SELECT max(oid) FROM pmib8502.devices_in_db\(databaseNumber)); "
        let deleteRowStatement = try! connection.prepareStatement(text: text)
        defer { deleteRowStatement.close() }
        try! deleteRowStatement.execute()
        
        //updateDeviceCount(databaseNumber: databaseNumber, connection: connection)
        
        return oldRow
    }
    
    private func getOidRow(databaseNumber: Int, connection: Connection, oidModifier: String) -> Row? {
        let text = "SELECT * FROM pmib8502.devices_in_db\(databaseNumber) WHERE oid=(SELECT \(oidModifier)(oid) FROM pmib8502.devices_in_db\(databaseNumber))"
        let oldRowStatement = try! connection.prepareStatement(text: text)
        defer { oldRowStatement.close() }

        let cursor = try! oldRowStatement.execute()
        defer { cursor.close() }
        
        if let firstRow = cursor.next() {
            let insertedRow = try! firstRow.get()
            
            return insertedRow
        }
        
        return nil
    }
    private func updateDeviceCount(databaseNumber: Int, connection: Connection) {
        let text = "SELECT setval('device_count', count(*)) FROM pmib8502.devices_in_db\(databaseNumber)"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }

        let cursor = try! statement.execute()
        defer { cursor.close() }
    }
}
