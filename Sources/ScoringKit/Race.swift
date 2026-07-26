//
//  Race.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

public protocol Race {
    associatedtype CompetitorType: Competitor

    var results: [CompetitorType: RaceResult] { get }

    /// The number of entries that competed in this race — the *N* of RRS A4,
    /// A9 and the high point percentage system.
    ///
    /// The default counts the results that are not DNC, which is what you want
    /// whenever the competitors being scored are the entries that raced.
    ///
    /// Override it when they are not. Scoring each crew member of a boat
    /// individually, for example, puts one result per sailor in `results` — all
    /// of them holding their boat's finishing place — but *N* is still the
    /// number of boats on the course. Without the override the denominator
    /// would follow the head count, so the same finish would score differently
    /// depending on how many people came sailing that day.
    var competitorsInStartingArea: Int { get }
}

public extension Race {
    var competitorsInStartingArea: Int {
        return results.map({($0.value == .dnc) ? 0 : 1}).reduce(0, +)
    }
}
