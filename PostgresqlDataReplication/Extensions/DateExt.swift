//
//  DateExt.swift
//  PostgresqlDataReplication
//
//  Created by Igoryok on 16.12.2021.
//

import Foundation


extension Date {
    public func toSQLDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
