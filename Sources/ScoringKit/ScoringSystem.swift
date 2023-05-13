//
//  ScoringSystem.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/12/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation
    
enum ComparisonResult {
    case before
    case after
    case unordered
}

public struct ScoringSystem<PointsType: Points> {
    
    // The RRS section A9 specifies slighly different handling
    // of boats that competed but did not finish
    // for regattas and long series.
    // This flag controls which version is used.
    let isLongSeries: Bool
    let excludeLimit: RaceLimit
    let qualifyLimit: RaceLimit
    
    public init(longSeries: Bool, exclude: RaceLimit, qualify: RaceLimit) {
        isLongSeries = longSeries
        excludeLimit = exclude
        qualifyLimit = qualify
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
    
    func collectRaceScores<RaceType: Race>(_ competitor: RaceType.CompetitorType, races: [RaceType], competitorsInSeries: Int, exclusions: Int) -> [RaceScore<PointsType>] {
        assert(exclusions < races.count)
        let places = races.map {
            (race) in
            RaceScore<PointsType>(race: race,
                                  result: race.results[competitor],
                                  isLongSeries: isLongSeries,
                                  competitorsInStartingArea: race.competitorsInStartingArea,
                                  competitorsInSeries: competitorsInSeries)
        }
        if exclusions > 0 {
            // 90.3 (b) When a scoring system provides for excluding one or more race scores from a boat’s series score, the score for disqualification under rule 2; rule 30.3’s last sentence; rule 42 if rule P2.2 or P2.3 applies; or rule 69.2(c)(2) shall not be excluded. The next-worse score shall be excluded instead.
            
            // A2: Each boat’s series score shall be the total of her race scores excluding her worst score. (The sailing instructions may make a different arrangement by providing, for example, that no score will be excluded, that two or more scores will be excluded, or that a specified number of scores will be excluded if a specified number of races are completed. A race is completed if scored; see rule 90.3(a).) If a boat has two or more equal worst scores, the score(s) for the race(s) sailed earliest in the series shall be excluded. The boat with the lowest series score wins and others shall be ranked accordingly.
            
            // This code relies on RaceScore being a class so that changes to .excluded
            // affect the places array, not just the worstPlaces array.
            
            let worstPlaces = places.sorted(by: compareScores)
            for i in 0 ..< exclusions {
                worstPlaces[i].excluded = true
            }
        }
        return places
    }
    
    private func compareScores(a: RaceScore<PointsType>, b: RaceScore<PointsType>) -> Bool {
        switch (a.result.isExcludable, b.result.isExcludable) {
        case (true, false):
            return true
        case (false, true):
            return false
        case (false, false), (true, true):
            if a.points > b.points {
                return true
            }
            else if a.points < b.points {
                return false
            }
            else {
                return false
            }
        }
    }
    
    func collectRaceScores<RaceType: Race>(_ competitors: Set<RaceType.CompetitorType>, races: [RaceType], exclusions: Int) -> [RaceType.CompetitorType: [RaceScore<PointsType>]] {
        var competitorRaceScores: [RaceType.CompetitorType: [RaceScore<PointsType>]] = [:]
        for skip in competitors {
            competitorRaceScores[skip] = collectRaceScores(skip, races: races, competitorsInSeries: competitors.count, exclusions: exclusions)
        }
        return competitorRaceScores
    }
    
    func placePoints<CompetitorType: Competitor>(_ result: RaceResult, competitors: Set<CompetitorType>) -> Float {
        switch result {
            case .finished(let position):
                return Float(position)
            default:
                return Float(competitors.count + 1)
        }
    }
    
    public func calculateScores<RaceType: Race>(_ races: [RaceType]) -> [SeriesScore<RaceType.CompetitorType, PointsType>] {
        print("\(races.count) races")
        let racesToQualify = qualifyLimit.calculate(races.count)
        print("\(racesToQualify) to qualify")
        let exclusions = excludeLimit.calculate(races.count)
        print("\(exclusions) throw outs")
        let competitors = collectCompetitors(races)
        let competitorRaceScores = collectRaceScores(competitors, races: races, exclusions: exclusions)
        var scores: [SeriesScore<RaceType.CompetitorType, PointsType>] = []
        for competitor in competitors {
            let totalPoints = competitorRaceScores[competitor]!.map({$0.excluded ? PointsType() : $0.points}).reduce(PointsType(), +)
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
        for score in scores {
            let q = score.qualified ? "Q" : "NQ"
            print("\(score.competitor.name) \(q) \(score.totalPointsDescription): ")
            for rs in score.raceScores {
                if rs.excluded {
                    print("(\(rs.pointsDescription)) ", terminator: "")
                }
                else {
                    print("\(rs.pointsDescription) ", terminator: "")
                }
            }
            print("")
        }
        return scores
    }

    func compareBestScores(_ scores0: [RaceScore<PointsType>], to scores1: [RaceScore<PointsType>]) -> ComparisonResult {
        assert(scores0.count == scores1.count)
        // A8.1: If there is a series-score tie between two or more boats, each boat’s race scores shall be listed in order of best to worst, and at the first point(s) where there is a difference the tie shall be broken in favour of the boat(s) with the best score(s). No excluded scores shall be used.
        let scores0 = scores0.filter({ !$0.excluded }).sorted(by: <)
        let scores1 = scores1.filter({ !$0.excluded }).sorted(by: <)
        for i in scores0.indices {
            if scores0[i] < scores1[i] {
                return .before
            }
            else if scores0[i] > scores1[i] {
                return .after
            }
        }
        return .unordered
    }
    
    func compareLastScores(_ scores0: [RaceScore<PointsType>], to scores1: [RaceScore<PointsType>]) -> ComparisonResult {
        assert(scores0.count == scores1.count)
        // A8.2: If a tie remains between two or more boats, they shall be ranked in order of their scores in the last race. Any remaining ties shall be broken by using the tied boats’ scores in the next-to-last race and so on until all ties are broken. These scores shall be used even if some of them are excluded scores.
        for i in scores0.indices.reversed() {
            if scores0[i] < scores1[i] {
                return .before
            }
            else if scores0[i] > scores1[i] {
                return .after
            }
        }
        return .unordered
    }
    
    func sortScores<CompetitorType: Competitor>(_ scores: inout [SeriesScore<CompetitorType, PointsType>]) {
        scores.sort {
            if $0.qualified && !$1.qualified {
                return true
            }
            else if $1.qualified && !$0.qualified {
                return false
            }
            if $0.totalPoints < $1.totalPoints {
                return true
            }
            else if $0.totalPoints > $1.totalPoints {
                return false
            }
            else {
                let scores0 = $0.raceScores
                let scores1 = $1.raceScores
                switch compareBestScores(scores0, to: scores1) {
                case .before:
                    return true
                case .after:
                    return false
                case .unordered:
                    switch compareLastScores(scores0, to: scores1) {
                    case .before:
                        return true
                    case .after:
                        return false
                    case .unordered:
                        return false
                    }
                }
            }
        }
    }
}

// The default scoring system in Appendix A allows 1 exclusion and no minimum to qualify.
let defaultRegattaScoringSystem = ScoringSystem<LowPoints>(longSeries: false, exclude: .upTo(1), qualify: .none)
let defaultHighPointSystem = ScoringSystem<HighPoints>(longSeries: true, exclude: .upTo(1), qualify: .abovePercent(75))
