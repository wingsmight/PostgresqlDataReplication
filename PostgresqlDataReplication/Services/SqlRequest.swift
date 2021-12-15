//
//  SqlRequest.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 15.12.2021.
//

import Foundation
import PostgresClientKit


class SqlRequest {
    static func requestTest() {
        do {
            var configuration = PostgresClientKit.ConnectionConfiguration()
            configuration.host = "fpm2.ami.nstu.ru"
            configuration.database = "students"
            configuration.user = "pmi-b8502"
            configuration.ssl = false
            configuration.credential = .cleartextPassword(password: "32Schero")

            let connection = try PostgresClientKit.Connection(configuration: configuration)
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
}
