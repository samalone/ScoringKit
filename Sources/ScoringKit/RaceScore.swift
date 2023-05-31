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
    // These two fields are copied from the Results for a particular competitor,
    // and do not change during the scoring process.
    public let result: RaceResult<Int>
    public let points: Points

    // These fields are computed as part of the scoring process,
    // and may change during different phases of scoring.
    public var excluded: Bool = false
    public var status: ResultStatus = .ok
    
    init() {
        self.result = .dnc
        self.points = Points()
    }
    
    init(result: RaceResult<Int>, points: Points) {
        self.result = result
        self.points = points
    }
    
}
