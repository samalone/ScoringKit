import Foundation

struct LowAveragedPoints: Points {
    var points: Int
    var races: Int
    
    static var systemName: String {
        return "Low point averaged"
    }
    
    fileprivate static var format: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 2
        return f
    }()
    
    init() {
        self.points = 0
        self.races = 0
    }

    init(points: Int) {
        assert(points > 0)
        self.points = points
        self.races = 1
    }

    init(points: Int, races: Int) {
        assert(races >= 0)
        assert(points >= races)
        self.points = points
        self.races = races
    }
    
    init(result: Result?,
         isLongSeries: Bool,
         competitorsInStartingArea: Int,
         competitorsInSeries: Int) {
        guard let result else {
            points = 0
            races = 0
            return
        }
        switch result {
        case .finished(let position):
            points = position
            races = 1
        case .dnc:
            points = 0
            races = 0
        default:
            points = competitorsInStartingArea + 1
            races = 1
        }
    }

    var description: String {
        return (races == 0) ? "-" : LowAveragedPoints.format.string(from: NSNumber(value: Double(points) / Double(races) as Double))!
    }
    
    var debugDescription: String {
        return "\(points)/\(races)"
    }
}

func + (lhs: LowAveragedPoints, rhs: LowAveragedPoints) -> LowAveragedPoints {
    return LowAveragedPoints(points: lhs.points + rhs.points, races: lhs.races + rhs.races)
}

func += (lhs: inout LowAveragedPoints, rhs: LowAveragedPoints) {
    lhs.points += rhs.points
    lhs.races += rhs.races
}

func == (lhs: LowAveragedPoints, rhs: LowAveragedPoints) -> Bool {
    switch (lhs.races, rhs.races) {
    case (0, 0):
        return true
    case (0, _), (_, 0):
        return false
    default:
        return (lhs.points * rhs.races) == (rhs.points * lhs.races)
    }
}

func < (lhs: LowAveragedPoints, rhs: LowAveragedPoints) -> Bool {
    switch (lhs.races, rhs.races) {
    case (0, 0), (0, _):
        return false
    case (_, 0):
        return true
    default:
        return (lhs.points * rhs.races) < (rhs.points * lhs.races)
    }
}
