import Foundation

public struct LowPointAveragedSystem: ScoringSystem {
    public var name: String {
        return "Low point averaged"
    }
    
    public func computeScore(result: RaceResult, isLongSeries: Bool, competitorsInStartingArea: Int, competitorsInSeries: Int) -> Points {
        switch result {
        case .finished(let position):
            return Points(position)
        case .dnc:
            return Points()
        default:
            return Points(competitorsInStartingArea + 1)
        }
    }
    
    public func betterScore(_ lhs: Points, _ rhs: Points) -> Bool {
        return (lhs.numerator * rhs.denominator) < (rhs.numerator * lhs.denominator)
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
