//
//  ScoringSystem.swift
//  
//
//  Created by Stuart A. Malone on 5/14/23.
//

import Foundation

public protocol ScoringSystem {
    var name: String { get }
    
    func computeScore(result: RaceResult,
                      isLongSeries: Bool,
                      competitorsInStartingArea: Int,
                      competitorsInSeries: Int) -> Points
    func betterScore(_ lhs: Points, _ rhs: Points) -> Bool
    func sameScore(_ lhs: Points, _ rhs: Points) -> Bool
    func describe(_ points: Points, debug: Bool) -> String
    func describe(score: RaceScore, debug: Bool) -> String
}

extension ScoringSystem {
    public func describe(_ points: Points) -> String {
        describe(points, debug: false)
    }
    
    public func describe(score: RaceScore) -> String {
        describe(score: score, debug: false)
    }
}
