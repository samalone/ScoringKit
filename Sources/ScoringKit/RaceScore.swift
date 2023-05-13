//
//  RaceScore.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/21/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

// The score for a competitor in a particular race.
// This is essentially an intermediate step in calculating scores for
// a regatta or long series, but it is useful to standardize it both
// for code sharing and to display the calculations.

public class RaceScore<PointsType:Points> {
    // These two fields are copied from the Results for a particular competitor,
    // and do not change during the scoring process.
    public let result: RaceResult
    public let points: PointsType

    // These fields are computed as part of the scoring process,
    // and may change during different phases of scoring.
    public var excluded: Bool = false
    
    init() {
        self.result = .dnc
        self.points = PointsType()
    }
    
    init(race: any Race, result: RaceResult?, isLongSeries: Bool,
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

extension RaceScore: Equatable {
    public static func ==<PointsType> (a: RaceScore<PointsType>, b: RaceScore<PointsType>) -> Bool {
        return a.points == b.points
    }
}

extension RaceScore: Comparable {
    public static func < <PointsType> (a: RaceScore<PointsType>, b: RaceScore<PointsType>) -> Bool {
        return a.points < b.points
    }
}
