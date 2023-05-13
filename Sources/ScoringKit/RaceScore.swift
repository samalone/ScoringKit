//
//  RaceScore.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/21/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public protocol GenericRaceScore {
    var result: Result { get }
    var excluded: Bool { get }
    
    var pointsDescription: String { get }
    var pointsDebugDescription: String { get }
}

// The score for a skipper in a particular race.
// This is essentially an intermediate step in calculating scores for
// a regatta or long series, but it is useful to standardize it both
// for code sharing and to display the calculations.

public class RaceScore<PointsType:Points>: Comparable, GenericRaceScore {
    // These two fields are copied from the Results for a particular skipper,
    // and do not change during the scoring process.
    public let result: Result
    public let points: PointsType

    // These fields are computed as part of the scoring process,
    // and may change during different phases of scoring.
    public var excluded: Bool = false
    
    init() {
        self.result = .dnc
        self.points = PointsType()
    }
    
    init(race: any Race, result: Result?, isLongSeries: Bool,
         competitorsInStartingArea: Int, competitorsInSeries: Int) {
        self.result = result ?? .dnc
        self.points = PointsType(result: result,
                                 isLongSeries: isLongSeries,
                                 competitorsInStartingArea: competitorsInStartingArea,
                                 competitorsInSeries: competitorsInSeries)
    }
    
    public var pointsDescription: String {
        return points.description
    }
    
    public var pointsDebugDescription: String {
        return points.debugDescription
    }
}

public func ==<PointsType> (a: RaceScore<PointsType>, b: RaceScore<PointsType>) -> Bool {
    return a.points == b.points
}

public func < <PointsType> (a: RaceScore<PointsType>, b: RaceScore<PointsType>) -> Bool {
    return a.points < b.points
}
