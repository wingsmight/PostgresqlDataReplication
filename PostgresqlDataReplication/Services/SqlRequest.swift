//
//  SqlRequest.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 15.12.2021.
//

import Foundation
import PostgresClientKit


class SqlRequest {
    private static var _configuraion: PostgresClientKit.ConnectionConfiguration? = nil
    
    
    public static func createSequence() {
        let connection = try! PostgresClientKit.Connection(configuration: SqlRequest.configuration)
        defer { connection.close() }

        let text = "CREATE SEQUENCE device_count START 12"
        let statement = try! connection.prepareStatement(text: text)
        defer { statement.close() }
        do {
            try statement.execute()
        } catch {
            print("createSequence() error: \(error).")
        }
    }
    public static func requestTest() {
        do {
            let connection = try PostgresClientKit.Connection(configuration: SqlRequest.configuration)
            defer { connection.close() }

            let text = "SELECT * FROM pmib8502.s WHERE town = $1;"
            let statement = try connection.prepareStatement(text: text)
            defer { statement.close() }

            let cursor = try statement.execute(parameterValues: [ "Париж" ])
            defer { cursor.close() }

            for row in cursor {
                let columns = try row.get().columns

                let n_post = try columns[0].string()
                let name = try columns[1].string()
                let reiting = try columns[2].int()
                let town = try columns[3].string()

                print("""
                    \(n_post) on \(name): reiting: \(reiting), town: \(town)
                    """)
            }
        } catch {
            print(error)
        }
    }
    
    
    public static var configuration: ConnectionConfiguration! {
        if _configuraion == nil {
            var newConfiguration = PostgresClientKit.ConnectionConfiguration()
            newConfiguration.host = "fpm2.ami.nstu.ru"
            newConfiguration.database = "students"
            newConfiguration.user = "pmi-b8502"
            newConfiguration.ssl = false
            newConfiguration.credential = .cleartextPassword(password: "32Schero")
            
            _configuraion = newConfiguration
        }
        return _configuraion
    }
}
