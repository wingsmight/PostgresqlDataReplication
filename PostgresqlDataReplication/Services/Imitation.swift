//
//  Imitation.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class Imitation {
    typealias UpdatedRow = (oldRow: String, newRow: String)
    typealias InsertedRow = (String)
    typealias DeletedRow = (String)
    
    public static func update(databaseNumber: Int) -> UpdatedRow? {
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
        
        return UpdatedRow(oldRow: oldRow!.description, newRow: newRow!.description)
    }
    public static func insert(databaseNumber: Int) -> InsertedRow? {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "INSERT INTO pmib8502.devices_in_db\(databaseNumber) (n_device, label, developer, type, last_operation, last_operation_date) VALUES ('D'||nextval('device_count'), 'Безымянный девайс', 'Безымянная компания', 'Неизвестный тип', 'вставка в БД\(databaseNumber)', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC')"
        let insertedRowStatement = try! connection.prepareStatement(text: text)
        defer { insertedRowStatement.close() }
        let cursor = try! insertedRowStatement.execute()
        defer { cursor.close() }
        
        if let insertedRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "max") {
            return InsertedRow(insertedRow)
        }
        return nil
    }
    public static func delete(databaseNumber: Int) -> DeletedRow? {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let oldRow = getOidRow(databaseNumber: databaseNumber, connection: connection, oidModifier: "max")
        if oldRow == nil {
            return nil
        }
        print("old row = \(oldRow)")
        
        let text = "DELETE FROM pmib8502.devices_in_db\(databaseNumber) WHERE oid=(SELECT max(oid) FROM pmib8502.devices_in_db\(databaseNumber)); "
        let deleteRowStatement = try! connection.prepareStatement(text: text)
        defer { deleteRowStatement.close() }
        try! deleteRowStatement.execute()
        
        updateDeviceCount(databaseNumber: databaseNumber, connection: connection)
        
        return DeletedRow(oldRow!.description)
    }
    
    private static func getOidRow(databaseNumber: Int, connection: Connection, oidModifier: String) -> String? {
        let text = "SELECT * FROM pmib8502.devices_in_db\(databaseNumber) WHERE oid=(SELECT \(oidModifier)(oid) FROM pmib8502.devices_in_db\(databaseNumber))"
        let oldRowStatement = try! connection.prepareStatement(text: text)
        defer { oldRowStatement.close() }

        let cursor = try! oldRowStatement.execute()
        defer { cursor.close() }
        
        if let firstRow = cursor.next() {
            let insertedRow = try! firstRow.get().columns
            
            return insertedRow.description
        }
        
        return nil
    }
    private static func updateDeviceCount(databaseNumber: Int, connection: Connection) {
        let text = "SELECT setval('device_count', count(*)) FROM pmib8502.devices_in_db\(databaseNumber)"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }

        let cursor = try! statement.execute()
        defer { cursor.close() }
    }
}