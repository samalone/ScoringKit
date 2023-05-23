//
//  ScoringSystem.swift
//  
//
//  Created by Stuart A. Malone on 5/14/23.
//

import Foundation

public enum ScoringSystem: String, Codable {
    case lowPoint
    case lowPointAveraged
    case highPointPercentage
    
    public var name: String {
        switch self {
        case .lowPoint:
            return "Low point"
        case .lowPointAveraged:
            return "Low point averaged"
        case .highPointPercentage:
            return "High point percentage"
        }
    }
    
    func computeScore(result: RaceResult,
                      isLongSeries: Bool,
                      competitorsInStartingArea: Int,
                      competitorsInSeries: Int) -> Points {
        switch self {
        case .lowPoint:
            switch result {
            case .finished(let position):
                return Points(position)
            case .dnc:
                return Points( competitorsInSeries + 1)
            default:
                return Points(isLongSeries ? (competitorsInStartingArea + 1) : (competitorsInSeries + 1))
            }
        case .lowPointAveraged:
            
            switch result {
            case .finished(let position):
                return Points(position)
            case .dnc:
                return Points()
            default:
                return Points(competitorsInStartingArea + 1)
            }
        case .highPointPercentage:
            switch result {
            case .finished(let position):
                // Define 'N' to be the number of boats that compete in a particular race. Each boat finishing that race and not thereafter retiring or being disqualified will be scored as follows:
                // Finishing place          Score
                // First                    N
                // Second                   N - 1
                // Third                    N - 2
                // Fourth                   N - 3
                // Each place thereafter    Subtract 1 point
                return Points(numerator: competitorsInStartingArea - position + 1, denominator: competitorsInStartingArea)
            case .dnc:
                // Her series score is based only on the races in which she competes, and therefore, provided she sails in sufficient races to qualify for the series, she is not placed at a disadvantage it she misses some races.
                return Points()
            default:
                // All other boats that compete in that race, including any that finish and thereafter retire or are disqualified, will score 0 points.
                return Points(numerator: 0, denominator: competitorsInStartingArea)
            }
        }
    }
    
    func betterScore(_ lhs: Points, _ rhs: Points) -> Bool {
        switch self {
        case .lowPoint:
            return lhs.numerator < rhs.numerator
        case .lowPointAveraged:
            return (lhs.numerator * rhs.denominator) < (rhs.numerator * lhs.denominator)
        case .highPointPercentage:
            return (lhs.numerator * rhs.denominator) > (rhs.numerator * lhs.denominator)
        }
    }
    
    func sameScore(_ lhs: Points, _ rhs: Points) -> Bool {
        switch self {
        case .lowPoint:
            return lhs.numerator == rhs.numerator
        case .lowPointAveraged:
            return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
        case .highPointPercentage:
            return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
        }
    }
    
    func describe(_ points: Points, debug: Bool = false) -> String {
        switch self {
        case .lowPoint:
            return points.numerator.description
        case .lowPointAveraged:
            guard points.denominator != 0 else { return "-" }
            return (debug ? "\(points.numerator)/\(points.denominator) " : "") + String(format: "%.2f", Double(points.numerator) / Double(points.denominator))
        case .highPointPercentage:
            guard points.denominator != 0 else { return "-" }
            return (debug ? "\(points.numerator)/\(points.denominator) " : "") + String(format: "%#.1f", 100.0 * Double(points.numerator) / Double(points.denominator))
        }
    }
    
    func describe(score: RaceScore, debug: Bool = false) -> String {
        switch self {
        case .lowPoint:
            switch score.result {
            case .racing:
                return ""
            case .finished(let position):
                return "\(position)"
            default:
                return "\(score.result.description) \(describe(score.points))"
            }
        case .lowPointAveraged:
            switch score.result {
            case .racing:
                return ""
            case .finished(let position):
                return "\(position)"
            case .dnc:
                return score.result.description
            default:
                return score.result.description + (debug ? " \(score.points.numerator)" : "")
            }
        case .highPointPercentage:
            switch score.result {
            case .racing:
                return ""
            case .finished(let position):
                return "\(position)" + (debug ? " \(score.points.numerator)/\(score.points.denominator)" : "")
            case .dnc:
                return score.result.description
            default:
                return "\(score.result.description)" + (debug ? " \(score.points.numerator)/\(score.points.denominator)" : " 0")
            }
        }
    }
}
