//
//  ScoringSystem.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/12/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation
import HTMLString

public struct SeriesScoring: Codable, Sendable {
    public var scoringSystem: ScoringSystem
    // The RRS section A9 specifies slighly different handling
    // of boats that competed but did not finish
    // for regattas and long series.
    // This flag controls which version is used.
    public var longSeries: Bool
    public var qualify: RacesToQualify
    public var exclude: RacesToExclude
    
    public init(scoringSystem: ScoringSystem, longSeries: Bool, qualify: RacesToQualify, exclude: RacesToExclude) {
        self.scoringSystem = scoringSystem
        self.longSeries = longSeries
        self.exclude = exclude
        self.qualify = qualify
    }
    
    func collectCompetitors<RaceType: Race>(_ races: [RaceType]) -> Set<RaceType.CompetitorType> {
        var competitors: Set<RaceType.CompetitorType> = Set()
        for race in races {
            for result in race.results {
                competitors.insert(result.key)
            }
        }
        return competitors
    }
    
    func collectRaceScores<RaceType: Race>(races: [RaceType], competitorsInSeries: Int) -> [RaceType.CompetitorType: [RaceScore]] {
        var competitorRaceScores: [RaceType.CompetitorType: [RaceScore]] = [:]
        let numberOfRaces = races.count
        for (raceIndex, race) in races.enumerated() {
            let competitorsInStartingArea = race.competitorsInStartingArea
            let dncPoints = scoringSystem.computeScore(result: .dnc,
                                                       isLongSeries: longSeries,
                                                       competitorsInStartingArea: competitorsInStartingArea,
                                                       competitorsInSeries: competitorsInSeries)
            for (competitor, result) in race.results {
                var competitorResults = competitorRaceScores[competitor] ?? Array<RaceScore>(repeating: RaceScore(result: .dnc, points: dncPoints), count: numberOfRaces)
                competitorResults[raceIndex] = RaceScore(result: result, points: scoringSystem.computeScore(result: result,
                                                                                                            isLongSeries: longSeries,
                                                                                                            competitorsInStartingArea: competitorsInStartingArea,
                                                                                                            competitorsInSeries: competitorsInSeries))
                competitorRaceScores[competitor] = competitorResults
            }
        }
        return competitorRaceScores
    }
    
    func excludeWorstScores<CompetitorType: Competitor>(competitorRaceScores: [CompetitorType: [RaceScore]], exclusions: Int) {
        guard exclusions > 0 else { return }
        
        // 90.3 (b) When a scoring system provides for excluding one or more race scores from a boat’s series score, the score for disqualification under rule 2; rule 30.3’s last sentence; rule 42 if rule P2.2 or P2.3 applies; or rule 69.2(c)(2) shall not be excluded. The next-worse score shall be excluded instead.
        
        // A2: Each boat’s series score shall be the total of her race scores excluding her worst score. (The sailing instructions may make a different arrangement by providing, for example, that no score will be excluded, that two or more scores will be excluded, or that a specified number of scores will be excluded if a specified number of races are completed. A race is completed if scored; see rule 90.3(a).) If a boat has two or more equal worst scores, the score(s) for the race(s) sailed earliest in the series shall be excluded. The boat with the lowest series score wins and others shall be ranked accordingly.
        
        // This code relies on RaceScore being a class so that changes to .excluded
        // affect the places array, not just the worstPlaces array.
        
        for places in competitorRaceScores.values {
            let worstPlaces = places.filter({scoringSystem.canExclude(result: $0.result)})
                .sorted(by: {scoringSystem.betterScore($1.points, $0.points)})
            for i in 0 ..< min(exclusions, worstPlaces.count) {
                worstPlaces[i].excluded = true
            }
            
        }
    }
    
    func tagResultStatus<CompetitorType: Competitor>(scores: [CompetitorType: [RaceScore]]) {
        guard scores.count > 0 else { return }
        guard let raceCount = scores.randomElement()?.value.count, raceCount > 0 else { return }
        for raceIndex in 0 ..< raceCount {
            let raceScores = scores.values.compactMap { raceScores -> RaceScore? in
                    let score = raceScores[raceIndex]
                    guard case .finished = score.result else { return nil }
                    return score
                }
                .sorted { a, b in
                    guard case let .finished(aPosition) = a.result else { return false }
                    guard case let .finished(bPosition) = b.result else { return true }
                    return aPosition < bPosition
                }
            var previousPosition = 0
            var previousScore: RaceScore? = nil
            var currentPosition = 1
            for raceScore in raceScores {
                guard case let .finished(position) = raceScore.result else { continue }
                if position > currentPosition {
                    raceScore.status = .error
                }
                else if position == previousPosition {
                    if previousScore?.status == .error {
                        raceScore.status = .error
                    }
                    else {
                        raceScore.status = .tied
                        previousScore?.status = .tied
                    }
                }
                previousScore = raceScore
                previousPosition = position
                currentPosition += 1
            }
        }
    }
    
    public func calculateScores<RaceType: Race>(_ races: [RaceType]) -> [SeriesScore<RaceType.CompetitorType>] {
        let racesToQualify = qualify.calculate(numberOfRaces: races.count)
        let exclusions = exclude.calculate(numberOfRaces: races.count, neededToQualify: racesToQualify)
        let competitors = collectCompetitors(races)
        let competitorRaceScores = collectRaceScores(races: races, competitorsInSeries: competitors.count)
        
        // Go through the results of each race, marking any ties or obvious scoring errors.
        tagResultStatus(scores: competitorRaceScores)
        
        excludeWorstScores(competitorRaceScores: competitorRaceScores, exclusions: exclusions)
        
        var scores: [SeriesScore<RaceType.CompetitorType>] = []
        for competitor in competitors {
            let totalPoints = competitorRaceScores[competitor]!.map({$0.excluded ? Points() : $0.points}).reduce(Points(), +)
            let sailed: Int = competitorRaceScores[competitor]!.map({($0.result == .dnc) ? 0 : 1}).reduce(0, +)
            let qualified = (sailed >= racesToQualify)
            scores.append(SeriesScore(competitor: competitor, racesSailed: sailed, totalPoints: totalPoints, qualified: qualified, raceScores: competitorRaceScores[competitor]!))
        }
        sortScores(&scores)
        for i in scores.indices {
            if scores[i].qualified {
                scores[i].rank = i + 1
            }
        }
        return scores
    }

    func compareBestScores(_ scores0: [RaceScore], to scores1: [RaceScore]) -> ComparisonResult {
        assert(scores0.count == scores1.count)
        // A8.1: If there is a series-score tie between two or more boats, each boat’s race scores shall be listed in order of best to worst, and at the first point(s) where there is a difference the tie shall be broken in favour of the boat(s) with the best score(s). No excluded scores shall be used.
        let scores0 = scores0.filter({ !$0.excluded }).sorted(by: {scoringSystem.betterScore($0.points, $1.points)})
        let scores1 = scores1.filter({ !$0.excluded }).sorted(by: {scoringSystem.betterScore($0.points, $1.points)})
        for i in 0..<min(scores0.count, scores1.count) {
            if scoringSystem.betterScore(scores0[i].points, scores1[i].points) {
                return .orderedAscending
            }
            else if scoringSystem.betterScore(scores1[i].points, scores0[i].points) {
                return .orderedDescending
            }
        }
        if scores0.count > scores1.count {
            return .orderedAscending
        }
        if scores1.count > scores0.count {
            return .orderedDescending
        }
        return .orderedSame
    }
    
    func compareLastScores(_ scores0: [RaceScore], to scores1: [RaceScore]) -> ComparisonResult {
        assert(scores0.count == scores1.count)
        // A8.2: If a tie remains between two or more boats, they shall be ranked in order of their scores in the last race. Any remaining ties shall be broken by using the tied boats’ scores in the next-to-last race and so on until all ties are broken. These scores shall be used even if some of them are excluded scores.
        for i in scores0.indices.reversed() {
            if scoringSystem.betterScore(scores0[i].points, scores1[i].points) {
                return .orderedAscending
            }
            else if scoringSystem.betterScore(scores1[i].points, scores0[i].points) {
                return .orderedDescending
            }
        }
        return .orderedSame
    }
    
    func sortScores<CompetitorType: Competitor>(_ scores: inout [SeriesScore<CompetitorType>]) {
        scores.sort {
            if $0.qualified && !$1.qualified {
                return true
            }
            else if $1.qualified && !$0.qualified {
                return false
            }
            if scoringSystem.betterScore($0.totalPoints, $1.totalPoints) {
                return true
            }
            else if scoringSystem.betterScore($1.totalPoints, $0.totalPoints) {
                return false
            }
            else {
                let scores0 = $0.raceScores
                let scores1 = $1.raceScores
                switch compareBestScores(scores0, to: scores1) {
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                case .orderedSame:
                    switch compareLastScores(scores0, to: scores1) {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame:
                        return false
                    }
                }
            }
        }
    }
    
    public func toHTML<RaceType: Race>(races: [RaceType],
                                       scores: [SeriesScore<RaceType.CompetitorType>],
                                       columns: [TableColumn<RaceType>],
                                       debug: Bool = false) -> String {
        var result = "<table class='race-scores'><thead><tr>"
        for column in columns {
            switch column {
            case .competitor(let header, _):
                result += "<th class='competitor'>" + header.addingUnicodeEntities() + "</th>"
            case .race(let raceNamer):
                for race in races {
                    result += "<th class='race'>" + raceNamer(race) + "</th>"
                }
            case .score:
                result += "<th class='score'>Score</th>"
            case .place:
                result += "<th class='place'></th>"
            case .racesSailed:
                result += "<th class='races-sailed'>Races sailed</th>"
            case .bestThrowout:
                result += "<th class='best-throwout'>Best throwout</th>"
            }
        }
        result += "</tr></thead><tbody>"
        
        for score in scores {
            let qualifiedClass = score.qualified ? "qualified" : "not-qualified"
            result += "<tr class='\(qualifiedClass)'>"
            for column in columns {
                switch column {
                case .competitor(_, let html):
                    result += "<td class='competitor'>" + html(score.competitor) + "</td>"
                case .race:
                    for raceScore in score.raceScores {
                        result += "<td class='points"
                        switch raceScore.status {
                        case .tied:
                            result += " tied"
                        case .error:
                            result += " error"
                        case .ok:
                            break
                        }
                        result += "'>"
                        if raceScore.excluded {
                            result += "<del>"
                        }
                        result += "<span class='score'>" + scoringSystem.describe(score: raceScore, debug: debug).addingUnicodeEntities()
                            + "</span>"
                        if raceScore.excluded {
                            result += "</del>"
                        }
                        result += "</td>"
                    }
                case .score:
                    result += "<td class='score'>"
                    if !((scoringSystem == .lowPoint) && !score.qualified) {
                        result += scoringSystem.describe(score.totalPoints, debug: debug).addingUnicodeEntities()
                    }
                    result += "</td>"
                case .place:
                    result += "<td class='place'>"
                    if let rank = score.rank {
                        result += String(rank).addingUnicodeEntities()
                    }
                    result += "</td>"
                case .racesSailed:
                    result += "<td class='races-sailed'>\(score.racesSailed)</td>"
                case .bestThrowout:
                    result += "<td class='best-throwout'>"
                    if !((scoringSystem == .lowPoint) && !score.qualified) {
                        if let bestThrowout = score.raceScores.filter({$0.excluded}).sorted(by: {scoringSystem.betterScore($0.points, $1.points)}).first {
                            result += scoringSystem.describe(score: bestThrowout, debug: debug)
                        }
                    }
                    result += "</td>"
                }
            }
            result += "</tr>"
        }
        
        result += "</tbody></table>"
        return result
    }
    
    static let sampleCSS = """
        body {
          font-family: sans-serif;
        }
        .race-scores {
          border-collapse: collapse;
          font-variant: tabular-nums;
        }
        .race-scores th {
          border-bottom: 2px solid #CCC;
        }
        .race-scores th, .race-scores td {
          padding-left: 0.5em;
          padding-right: 0.5em;
        }
        .race-scores th:first-child, .race-scores td:first-child {
          padding-left: 0;
        }
        .race-scores th:last-child, .race-scores td:last-child {
          padding-right: 0;
        }
        .competitor {
          text-align: left;
        }
        .place {
          text-align: right;
        }
        .points, .score, .place, .races-sailed, .best-throwout {
          text-align: center;
        }
        .not-qualified td {
          color: gray;
        }
        .excluded {
          background-image: linear-gradient(to bottom right,
            transparent calc(50% - 1px),
            red,
            transparent calc(50% + 1px)
          )
        }
        .tied {
          background-color: #CDF;
        }
        .error {
          background-color: #FAA;
        }
    """
}

public enum TableColumn<RaceType: Race> {
    public typealias RaceNamer = (RaceType) -> String
    
    case competitor(header: String, html: (RaceType.CompetitorType) -> String)
    case race(RaceNamer)
    case score
    case place
    case racesSailed
    case bestThrowout
}

// The default scoring system in Appendix A allows 1 exclusion and no minimum to qualify.
let defaultRegattaScoringSystem = SeriesScoring(scoringSystem: .lowPoint, longSeries: false,
                                                qualify: .none, exclude: .upTo(n: 1))
let defaultHighPointSystem = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: true,
                                           qualify: .percent(n: 75, rounded: .up), exclude: .upTo(n: 1))
