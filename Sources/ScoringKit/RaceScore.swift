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

public class RaceScore {
    // The result is copied from the Results for a particular competitor,
    // and does not change during the scoring process.
    public let result: RaceResult
    
    // Points may be adjusted for ties per US Sailing A7 rule.
    public var points: Points

    // These fields are computed as part of the scoring process,
    // and may change during different phases of scoring.
    public var excluded: Bool = false
    public var status: ResultStatus = .ok
    
    init() {
        self.result = .dnc
        self.points = Points()
    }
    
    init(result: RaceResult, points: Points) {
        self.result = result
        self.points = points
    }
    
}
