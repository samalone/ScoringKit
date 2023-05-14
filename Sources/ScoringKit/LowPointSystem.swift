//
//  LowPointSystem.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/25/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public struct LowPointSystem: ScoringSystem {
    
    public var name: String {
        return "Low point"
    }
    
    public func computeScore(result: RaceResult, isLongSeries: Bool, competitorsInStartingArea: Int, competitorsInSeries: Int) -> Points {
        switch result {
        case .finished(let position):
            return Points(position)
        case .dnc:
            return Points( competitorsInSeries + 1)
        default:
            return Points(isLongSeries ? (competitorsInStartingArea + 1) : (competitorsInSeries + 1))
        }
    }
    
    public func betterScore(_ lhs: Points, _ rhs: Points) -> Bool {
        return lhs.numerator < rhs.numerator
    }
    
    public func sameScore(_ lhs: Points, _ rhs: Points) -> Bool {
        return lhs.numerator == rhs.numerator
    }
    
    public func description(_ points: Points) -> String {
        return points.numerator.description
    }
    
    public func debugDescription(_ points: Points) -> String {
        return points.numerator.description
    }
}
