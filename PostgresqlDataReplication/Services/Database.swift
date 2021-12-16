//
//  Database.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class Database {
    public static func create(databaseNumber: Int) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = """
        INSERT INTO pmib8502.devices_in_db\(databaseNumber) VALUES
        ('D1', 'iPhone X', 'Apple Inc.', 'smartphone', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D2', ' QN90A Samsung Neo QLED 4K Smart TV (2021)', 'Samsung Group', 'TV', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D3', 'ThinkPad E14', 'Lenovo', 'laptop', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D4', 'MacBook Pro 2013', 'Apple Inc.', 'laptop', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D5', 'Huawei Nova 9', 'Huawei Technologies Co.', 'smartphone', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D6', 'Apple TV 4K', 'Apple Inc.', 'TV', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D7', 'iPhone 11', 'Apple Inc.', 'smartphone', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D8', 'HUAWEI Band 6', 'Huawei Technologies Co.', 'smartwatch', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D9', 'Galaxy Watch4 LTE', 'Samsung Group', 'smartwatch', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D10', 'Apple Watch SE', 'Apple Inc.', 'smartwatch', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D11', 'MacBook Air M1', 'Apple Inc.', 'laptop', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC'),
        ('D12', 'Huawei MateBook 16', 'Huawei Technologies Co.', 'laptop', 'инициализация', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC')
        """
        
        do {
            let createStatement = try connection.prepareStatement(text: text)
            defer { createStatement.close() }
            try createStatement.execute()
        } catch {
            print(error)
        }
    }
    public static func update(databaseNumber: Int, deviceRow: DeviceRow, operation: String, operationDate: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "UPDATE pmib8502.devices_in_db\(databaseNumber) SET label='\(deviceRow.title)', developer='\(deviceRow.developer)', type='\(deviceRow.type)', last_operation='\(operation)', last_operation_date='\(operationDate)' WHERE n_device='\(deviceRow.id)'"
        do {
            let updateRowStatement = try connection.prepareStatement(text: text)
            defer { updateRowStatement.close() }
            try updateRowStatement.execute()
        } catch {
            print(error)
            
            insert(databaseNumber: databaseNumber, deviceRow: deviceRow, operation: operation, operationDate: operationDate)
        }
    }
    public static func insert(databaseNumber: Int, deviceRow: DeviceRow, operation: String, operationDate: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "INSERT INTO pmib8502.devices_in_db\(databaseNumber) (n_device, label, developer, type, last_operation, last_operation_date) VALUES (\(deviceRow.id.isEmpty ? "'D'||nextval('device_count')" : "'\(deviceRow.id)'"), '\(deviceRow.title)', '\(deviceRow.developer)', '\(deviceRow.type)', '\(operation)', '\(operationDate)')"
        do {
            let insertedRowStatement = try connection.prepareStatement(text: text)
            defer { insertedRowStatement.close() }
            try insertedRowStatement.execute()
        } catch {
            print(error)
        }
    }
    public static func delete(databaseNumber: Int, deviceNumber: String) {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "DELETE FROM pmib8502.devices_in_db\(databaseNumber) WHERE n_device='\(deviceNumber)'"
        do {
            let deleteRowStatement = try connection.prepareStatement(text: text)
            defer { deleteRowStatement.close() }
            try deleteRowStatement.execute()
            
            updateDeviceCount(databaseNumber: databaseNumber, connection: connection)
        } catch {
            print(error)
        }
    }
    
    private static func updateDeviceCount(databaseNumber: Int, connection: Connection) {
        let text = "SELECT setval('device_count', count(*)) FROM pmib8502.devices_in_db\(databaseNumber)"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }
        try! statement.execute()
    }
}
