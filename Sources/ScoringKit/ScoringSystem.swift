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
    func description(_ points: Points) -> String
    func debugDescription(_ points: Points) -> String
}
