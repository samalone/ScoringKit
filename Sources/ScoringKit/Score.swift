//
//  Score.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/3/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import CoreData

public protocol GenericScore {
    var competitor: any Competitor { get }
    var racesSailed: Int { get }
    var qualified: Bool { get }
    var rank: Int? { get set }
    
    var totalPointsDescription: String { get }
    var totalPointsDebugDescription: String { get }
    
    var genericRaceScores: [GenericRaceScore] { get }
}

extension GenericScore {
    var textRank: String {
        if let rank = rank {
            return rank.description
        }
        else {
            return "NQ"
        }
    }
    
    public var htmlTableRow: String {
        var row = "<tr><td>\(competitor.name)</td>"
        for raceScore in genericRaceScores {
            let classes = raceScore.excluded ? "n t" : "n"
            row += "<td class='\(classes)'>\(raceScore.result)</td>"
        }
        row += "<td class='n'>\(totalPointsDescription)</td><td class='n'>\(textRank)</td></tr>"
        return row
    }
    
    public var plainText: String {
        return "\(textRank): \(competitor.name) \(totalPointsDescription)"
    }
}

public struct Score<PointsType:Points>: GenericScore {
    public let competitor: any Competitor
    public let racesSailed: Int
    public let totalPoints: PointsType
    public let qualified: Bool
    public var rank: Int? = nil
    public let raceScores: [RaceScore<PointsType>]
    
    public var totalPointsDescription: String {
        return totalPoints.description
    }
    
    public var totalPointsDebugDescription: String {
        return totalPoints.debugDescription
    }
    
    public var genericRaceScores: [GenericRaceScore] {
        return raceScores.map { $0 as GenericRaceScore }
    }
}
