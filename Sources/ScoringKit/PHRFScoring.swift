//
//  PHRFScoring.swift
//  
//
//  Created by Stuart A. Malone on 5/31/23.
//

import Foundation

public struct PHRFScoring {
    public let seriesScoring: SeriesScoring
    
    public init(seriesScoring: SeriesScoring) {
        self.seriesScoring = seriesScoring
    }
    
    public func calculateScores<RaceType: PHRFRace>(_ races: [RaceType]) -> [SeriesScore<RaceType.CompetitorType>] {
        return []
    }

}
