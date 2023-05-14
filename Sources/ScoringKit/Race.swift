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
}

public extension Race {
    var competitorsInStartingArea: Int {
        return results.map({($0.value == .dnc) ? 0 : 1}).reduce(0, +)
    }
}
