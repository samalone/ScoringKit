//
//  FinishPosition.swift
//  
//
//  Created by Stuart A. Malone on 5/31/23.
//

import Foundation

public protocol FinishPosition: Codable, Equatable, CustomStringConvertible {
    init?(_ value: String)
}

extension Int: FinishPosition {}

extension Date: FinishPosition {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    public init?(_ value: String) {
        if let d = Date.formatter.date(from: value) {
            self = d
        }
        else {
            return nil
        }
    }
}
