//
//  SeriesScore.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/3/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

public struct SeriesScore<CompetitorType: Competitor> {
    public let competitor: CompetitorType
    public let racesSailed: Int
    public let totalPoints: Points
    public let qualified: Bool
    public var rank: Int? = nil
    public let raceScores: [RaceScore]
    
    var textRank: String {
        if let rank = rank {
            return rank.description
        }
        else {
            return "NQ"
        }
    }
}
