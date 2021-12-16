//
//  Database.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class Database {
    public static func update(databaseNumber: Int, deviceRow: DeviceRow, operation: String, operationDate: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "UPDATE pmib8502.devices_in_db\(databaseNumber) SET (n_device, label, developer, type, last_operation, last_operation_date) = (\(deviceRow.id.isEmpty ? "'D'||nextval('device_count')" : "'\(deviceRow.id)'"), '\(deviceRow.title)', '\(deviceRow.developer)', '\(deviceRow.type)', '\(operation)', '\(operationDate)')"
        let updateRowStatement = try! connection.prepareStatement(text: text)
        defer { updateRowStatement.close() }
        try! updateRowStatement.execute()
    }
    public static func insert(databaseNumber: Int, deviceRow: DeviceRow, operation: String, operationDate: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "INSERT INTO pmib8502.devices_in_db\(databaseNumber) (n_device, label, developer, type, last_operation, last_operation_date) VALUES (\(deviceRow.id.isEmpty ? "'D'||nextval('device_count')" : "'\(deviceRow.id)'"), '\(deviceRow.title)', '\(deviceRow.developer)', '\(deviceRow.type)', '\(operation)', '\(operationDate)')"
        let insertedRowStatement = try! connection.prepareStatement(text: text)
        defer { insertedRowStatement.close() }
        try! insertedRowStatement.execute()
    }
    public static func delete(databaseNumber: Int, deviceNumber: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "DELETE FROM pmib8502.devices_in_db\(databaseNumber) WHERE n_device=\(deviceNumber)"
        let deleteRowStatement = try! connection.prepareStatement(text: text)
        defer { deleteRowStatement.close() }
        try! deleteRowStatement.execute()
        
        updateDeviceCount(databaseNumber: databaseNumber, connection: connection)
    }
    
    private static func updateDeviceCount(databaseNumber: Int, connection: Connection) {
        let text = "SELECT setval('device_count', count(*)) FROM pmib8502.devices_in_db\(databaseNumber)"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }
        try! statement.execute()
    }
}
