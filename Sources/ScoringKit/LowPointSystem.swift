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
    
    public func describe(_ points: Points, debug: Bool) -> String {
        return points.numerator.description
    }
    
    public func describe(score: RaceScore, debug: Bool) -> String {
        switch score.result {
        case .racing:
            return ""
        case .finished(let position):
            return "\(position)"
        default:
            return "\(score.result.description) \(describe(score.points))"
        }
    }
}
