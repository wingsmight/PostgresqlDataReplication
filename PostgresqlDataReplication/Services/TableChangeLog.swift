//
//  DeviceChangeLog.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation
import PostgresClientKit

class TableChangeLog {
    private var connection: Connection
    
    
    public init() {
        connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        
        let text = """
        CREATE TABLE IF NOT EXISTS pmib8502.devices_changelog(
            change_id SERIAL NOT NULL,
            n_db integer NOT NULL,
            operation character(40) NOT NULL,
            operation_date timestamp without time zone NOT NULL,
            n_device character(4) NOT NULL,
            device_label character(60) NOT NULL,
            device_developer character(50) NOT NULL,
            device_type character(50) NOT NULL,
            device_last_operation character(30) NOT NULL,
            device_last_operation_date timestamp without time zone NOT NULL
        );
        """
        
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }

        let cursor = try! statement.execute()
        defer { cursor.close() }
    }
    
    
    public func insert(row: Row, databaseNumber: Int, operation: String) {
        connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        
        let text = "INSERT INTO pmib8502.devices_changelog (n_db, device_last_operation, device_last_operation_date, n_device, device_label, device_developer, device_type, operation, operation_date) VALUES ('\(databaseNumber)', '\(row.columns[4])', '\(row.columns[5])', '\(row.columns[0])', '\(row.columns[1])', '\(row.columns[2])', '\(row.columns[3])', '\(operation)', date_trunc('second', current_timestamp) AT TIME ZONE '-7 UTC')"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }

        let cursor = try! statement.execute()
        defer { cursor.close() }
    }
    public func saveToFile(fileUrl: URL) {
        connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }
        
        let text = "SELECT * FROM pmib8502.devices_changelog"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }

        let cursor = try! statement.execute()
        defer { cursor.close() }
        
        do {
            let emptyText = ""
            try emptyText.write(to: fileUrl, atomically: false, encoding: String.Encoding.utf8)
            
            for row in cursor {
                if let fileHandle = try? FileHandle(forWritingTo: fileUrl) {
                                fileHandle.seekToEndOfFile()
                    fileHandle.write(try! row.get().columns.description.data(using: String.Encoding.utf8)! )
                                fileHandle.closeFile()
                            }
            }
        } catch {
            print("saveToFile produced error: \(error)")
        }
    }
}
