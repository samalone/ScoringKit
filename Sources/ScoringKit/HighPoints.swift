import Foundation

public struct HighPoints: Points {
    var points: Int
    var possiblePoints: Int
    
    public static var systemName: String {
        return "High point"
    }
    
    fileprivate static var format: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        return f
    }()
    
    public init() {
        self.points = 0
        self.possiblePoints = 0
    }
    
    init(points: Int, possiblePoints: Int) {
        assert(points >= 0)
        assert(possiblePoints >= 0)
        assert(points <= possiblePoints)
        
        self.points = points
        self.possiblePoints = possiblePoints
    }
    
    public init(result: RaceResult?,
                isLongSeries: Bool,
                competitorsInStartingArea: Int,
                competitorsInSeries: Int) {
        guard let result else {
            points = 0
            possiblePoints = 0
            return
        }
        switch result {
        case .finished(let position):
            // Define 'N' to be the number of boats that compete in a particular race. Each boat finishing that race and not thereafter retiring or being disqualified will be scored as follows:
            // Finishing place          Score
            // First                    N
            // Second                   N - 1
            // Third                    N - 2
            // Fourth                   N - 3
            // Each place thereafter    Subtract 1 point
            points = competitorsInStartingArea - position + 1
            possiblePoints = competitorsInStartingArea
        case .dnc:
            // Her series score is based only on the races in which she competes, and therefore, provided she sails in sufficient races to qualify for the series, she is not placed at a disadvantage it she misses some races.
            points = 0
            possiblePoints = 0
        default:
            // All other boats that compete in that race, including any that finish and thereafter retire or are disqualified, will score 0 points.
            points = 0
            possiblePoints = competitorsInStartingArea
        }
    }

    public var description: String {
        return (possiblePoints == 0) ? "-" : HighPoints.format.string(from: NSNumber(value: 100.0 * Double(points) / Double(possiblePoints) as Double))!
    }
    
    public var debugDescription: String {
        return "\(points)/\(possiblePoints)"
    }
}

public func + (lhs: HighPoints, rhs: HighPoints) -> HighPoints {
    return HighPoints(points: lhs.points + rhs.points, possiblePoints: lhs.possiblePoints + rhs.possiblePoints)
}

public func += (lhs: inout HighPoints, rhs: HighPoints) {
    lhs.points += rhs.points
    lhs.possiblePoints += rhs.possiblePoints
}

public func == (lhs: HighPoints, rhs: HighPoints) -> Bool {
    switch (lhs.possiblePoints, rhs.possiblePoints) {
    case (0, 0):
        return true
    case (0, _), (_, 0):
        return false
    default:
        return (lhs.points * rhs.possiblePoints) == (rhs.points * lhs.possiblePoints)
    }
}

public func < (lhs: HighPoints, rhs: HighPoints) -> Bool {
    switch (lhs.possiblePoints, rhs.possiblePoints) {
    case (0, 0), (0, _):
        return false
    case (_, 0):
        return true
    default:
        return (lhs.points * rhs.possiblePoints) > (rhs.points * lhs.possiblePoints)
    }
}
