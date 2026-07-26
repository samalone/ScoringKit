//
//  ScoringSystem.swift
//  
//
//  Created by Stuart A. Malone on 5/14/23.
//

import Foundation

public enum ScoringSystem: String, CaseIterable, Codable, Sendable {
    case lowPoint
    case bonusPoint
    case lowPointAveraged
    case highPointPercentage
    
    public var name: String {
        switch self {
        case .lowPoint:
            return "Low point"
        case .bonusPoint:
            return "Bonus point"
        case .lowPointAveraged:
            return "Low point averaged"
        case .highPointPercentage:
            return "High point percentage"
        }
    }
    
    private func bonusPoints(position: Int) -> Points {
        switch position {
        case 1:
            return Points(0)
        case 2:
            return Points(30)
        case 3:
            return Points(57)
        case 4:
            return Points(80)
        case 5:
            return Points(100)
        case 6:
            return Points(117)
        case 7:
            return Points(130)
        default:
            return Points(130 + (10 * (position - 7)))
        }
    }
    
    /// The points a boat earns for finishing in `place`, before any A7 adjustment
    /// for a tie. A7 needs the points for the places below a tied place, which no
    /// boat necessarily finished in, so this is kept separate from `computeScore`.
    func points(forFinishingPlace place: Int, competitorsInStartingArea: Int) -> Points {
        switch self {
        case .lowPoint, .lowPointAveraged:
            return Points(place)
        case .bonusPoint:
            return bonusPoints(position: place)
        case .highPointPercentage:
            // Define 'N' to be the number of boats that compete in a particular race. Each boat finishing that race and not thereafter retiring or being disqualified will be scored as follows:
            // Finishing place          Score
            // First                    N
            // Second                   N - 1
            // Third                    N - 2
            // Fourth                   N - 3
            // Each place thereafter    Subtract 1 point
            // A place past the back of the fleet is not a real place, but A7 can
            // ask for one when the results are inconsistent. Score it zero rather
            // than letting a boat earn negative points.
            return Points(numerator: max(0, competitorsInStartingArea - place + 1),
                          denominator: competitorsInStartingArea)
        }
    }

    /// Whether a series total is built by accumulating numerators and denominators
    /// — earned/possible for high point, total/races for the averaged system —
    /// rather than by adding the race scores as proper fractions.
    ///
    /// An accumulated total only comes out right when every race is written over
    /// the same scale, which is what A7 tie splitting has to preserve.
    var accumulatesTotals: Bool {
        switch self {
        case .lowPoint, .bonusPoint:
            return false
        case .lowPointAveraged, .highPointPercentage:
            return true
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
                return points(forFinishingPlace: position, competitorsInStartingArea: competitorsInStartingArea)
            case .dnc:
                return Points(competitorsInSeries + 1)
            default:
                return Points(isLongSeries ? (competitorsInStartingArea + 1) : (competitorsInSeries + 1))
            }
        case .bonusPoint:
            switch result {
            case .finished(let position):
                return points(forFinishingPlace: position, competitorsInStartingArea: competitorsInStartingArea)
            case .dnc:
                return bonusPoints(position: competitorsInSeries + 1)
            default:
                return bonusPoints(position: isLongSeries ? (competitorsInStartingArea + 1) : (competitorsInSeries + 1))
            }
        case .lowPointAveraged:
            switch result {
            case .finished(let position):
                return points(forFinishingPlace: position, competitorsInStartingArea: competitorsInStartingArea)
            case .dnc:
                return Points()
            default:
                return Points(competitorsInStartingArea + 1)
            }
        case .highPointPercentage:
            switch result {
            case .finished(let position):
                return points(forFinishingPlace: position, competitorsInStartingArea: competitorsInStartingArea)
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
        case .lowPoint, .bonusPoint:
            // Use cross-multiplication to compare fractions: a/b < c/d iff a*d < c*b
            return (lhs.numerator * rhs.denominator) < (rhs.numerator * lhs.denominator)
        case .lowPointAveraged:
            switch (lhs.denominator, rhs.denominator) {
            case (0, 0):
                return false
            case (0, _):
                return false
            case (_, 0):
                return true
            default:
                return (lhs.numerator * rhs.denominator) < (rhs.numerator * lhs.denominator)
            }
        case .highPointPercentage:
            switch (lhs.denominator, rhs.denominator) {
            case (0, 0):
                return false
            case (0, _):
                return false
            case (_, 0):
                return true
            default:
                return (lhs.numerator * rhs.denominator) > (rhs.numerator * lhs.denominator)
            }
        }
    }
    
    func sameScore(_ lhs: Points, _ rhs: Points) -> Bool {
        switch self {
        case .lowPoint, .bonusPoint:
            // Use cross-multiplication to compare fractions: a/b == c/d iff a*d == c*b
            return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
        case .lowPointAveraged:
            switch (lhs.denominator, rhs.denominator) {
            case (0, 0):
                return true
            case (0, _):
                return false
            case (_, 0):
                return false
            default:
                return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
            }
        case .highPointPercentage:
            switch (lhs.denominator, rhs.denominator) {
            case (0, 0):
                return true
            case (0, _):
                return false
            case (_, 0):
                return false
            default:
                return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
            }
        }
    }
    
    func canExclude(result: RaceResult) -> Bool {
        if result == .dnc {
            switch self {
            case .lowPoint, .bonusPoint:
                return true
            case .lowPointAveraged:
                return false
            case .highPointPercentage:
                return false
            }
        }
        return result.isExcludable
    }
    
    public var canDebug: Bool {
        return self != .lowPoint
    }
    
    public func describe(_ points: Points, debug: Bool = false) -> String {
        switch self {
        case .lowPoint:
            // Handle fractional points from tie splitting (A7)
            if points.denominator == 1 {
                return points.numerator.description
            } else {
                return String(format: "%.1f", Double(points.numerator) / Double(points.denominator))
            }
        case .bonusPoint:
            // Bonus points are stored as integers * 10 (e.g., 5.7 = 57)
            // Handle fractional points from tie splitting (A7)
            return String(format: "%.2f", Double(points.numerator) / (10.0 * Double(points.denominator)))
        case .lowPointAveraged:
            guard points.denominator != 0 else { return "-" }
            return (debug ? "\(points.numerator)/\(points.denominator) " : "") + String(format: "%.2f", Double(points.numerator) / Double(points.denominator))
        case .highPointPercentage:
            guard points.denominator != 0 else { return "-" }
            return (debug ? "\(points.numerator)/\(points.denominator) " : "") + String(format: "%#.1f", 100.0 * Double(points.numerator) / Double(points.denominator))
        }
    }
    
    public func describe(score: RaceScore, debug: Bool = false) -> String {
        switch self {
        case .lowPoint, .bonusPoint:
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
                // The value, not the numerator: A7 tie splitting elsewhere in the
                // series can leave this race over a denominator greater than one,
                // and a bare numerator would read as twice the penalty it is.
                return score.result.description + (debug ? " \(describe(score.points))" : "")
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
