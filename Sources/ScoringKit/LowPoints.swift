//
//  LowPoints.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/25/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public struct LowPoints: Points {
    var points: Int
    
    public static var systemName: String {
        return "Low point"
    }
    
    public init() {
        self.points = 0
    }
    
    init(points: Int) {
        assert(points >= 0)
        self.points = points
    }
    
    public init(result: Result?,
                isLongSeries: Bool,
                competitorsInStartingArea: Int,
                competitorsInSeries: Int) {
        guard let result else {
            points = competitorsInSeries + 1
            return
        }
        switch result {
        case .finished(let position):
            points = position
        case .dnc:
            points = competitorsInSeries + 1
        default:
            points = isLongSeries ? (competitorsInStartingArea + 1) : (competitorsInSeries + 1)
        }
    }
    
    public var description: String {
        return points.description
    }
    
    public var debugDescription: String {
        return points.description
    }
}

public func + (lhs: LowPoints, rhs: LowPoints) -> LowPoints {
    return LowPoints(points: lhs.points + rhs.points)
}

public func += (lhs: inout LowPoints, rhs: LowPoints) {
    lhs.points += rhs.points
}

public func == (lhs: LowPoints, rhs: LowPoints) -> Bool {
    return lhs.points == rhs.points
}

public func < (lhs: LowPoints, rhs: LowPoints) -> Bool {
    return lhs.points < rhs.points
}
