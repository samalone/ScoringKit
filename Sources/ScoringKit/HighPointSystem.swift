import Foundation

public struct HighPointSystem: ScoringSystem {
    public var name: String {
        return "High point"
    }
    
    public func computeScore(result: RaceResult, isLongSeries: Bool, competitorsInStartingArea: Int, competitorsInSeries: Int) -> Points {
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
    
    public func betterScore(_ lhs: Points, _ rhs: Points) -> Bool {
        return (lhs.numerator * rhs.denominator) > (rhs.numerator * lhs.denominator)
    }
    
    public func sameScore(_ lhs: Points, _ rhs: Points) -> Bool {
        return (lhs.numerator * rhs.denominator) == (rhs.numerator * lhs.denominator)
    }
    
    public func description(_ points: Points) -> String {
        guard points.denominator != 0 else { return "-" }
        return String(format: "%.2f", Double(points.numerator) / Double(points.denominator))
    }
    
    public func debugDescription(_ points: Points) -> String {
        return "\(points.numerator)/\(points.denominator)"
    }
}
