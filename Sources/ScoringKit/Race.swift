//
//  Race.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

public protocol Race {
    associatedtype CompetitorType: Competitor
    
    /// The race ID can be any short string (date, time, course letter, course number, etc.)
    /// to identify the race. It should be short to fit cleanly in HTML tables.
    var id: String { get }
    var results: [CompetitorType: Result] { get }
}

public extension Race {
    var competitorsInStartingArea: Int {
        return results.map({($0.value == .dnc) ? 0 : 1}).reduce(0, +)
    }
}
