//
//  ScoringSystem.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/12/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation
import HTMLString

private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
    var (a, b) = (abs(a), abs(b))
    while b != 0 {
        (a, b) = (b, a % b)
    }
    return a
}

private func leastCommonMultiple(_ a: Int, _ b: Int) -> Int {
    let divisor = greatestCommonDivisor(a, b)
    return (divisor == 0) ? 0 : abs(a / divisor * b)
}

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
    
    /// Adjusts points for tied boats per the RRS A7 rule.
    /// "If boats are tied at the finishing line... the points for the place for which the boats
    /// have tied and for the place(s) immediately below shall be added together and divided equally."
    ///
    /// A7 is written generally and is not scoped to the low point system — A4 is what
    /// makes low point the default system, and A7 sits alongside it. US Sailing's
    /// Scoring a Long Series X4, the page that publishes the high point percentage
    /// system, likewise scores race ties under A7. So all four systems split points.
    ///
    /// Splitting a place makes a race score fractional, and the systems carry that
    /// differently. Low point and bonus point total a series by adding proper
    /// fractions, so a race can be left over whatever denominator the split needs.
    /// The averaged and high point systems instead accumulate numerators and
    /// denominators — total/races and earned/possible — which only comes out right
    /// when every race is written over the same scale: 7/8 + 4/4 is 11/12, not the
    /// 15/16 it should be. Those two therefore get every race of the series scaled
    /// by a common multiple of the tie sizes, so a race with split points still
    /// weighs exactly one race.
    func adjustPointsForTies<RaceType: Race>(races: [RaceType], scores: [RaceType.CompetitorType: [RaceScore]]) {
        guard !races.isEmpty, !scores.isEmpty else { return }

        // Collect the ties race by race: the place the boats tied for, and their scores.
        let ties: [[(place: Int, tiedScores: [RaceScore])]] = races.indices.map { raceIndex in
            var placeGroups: [Int: [RaceScore]] = [:]
            for raceScores in scores.values {
                let raceScore = raceScores[raceIndex]
                guard case let .finished(place) = raceScore.result else { continue }
                placeGroups[place, default: []].append(raceScore)
            }
            return placeGroups.filter({ $0.value.count > 1 })
                .map({ (place: $0.key, tiedScores: $0.value) })
        }

        // The common scale for the accumulating systems. Least common multiple is
        // commutative, so this does not depend on the order the ties were collected.
        let scale = scoringSystem.accumulatesTotals
            ? ties.joined().reduce(1, { leastCommonMultiple($0, $1.tiedScores.count) })
            : 1

        for raceIndex in races.indices {
            let competitorsInStartingArea = races[raceIndex].competitorsInStartingArea

            if scale > 1 {
                for raceScores in scores.values {
                    raceScores[raceIndex].points = raceScores[raceIndex].points.scaled(by: scale)
                }
            }

            for (place, tiedScores) in ties[raceIndex] {
                // Add together the points for the tied place and the places
                // immediately below it. They share a denominator, so the sum does too.
                let count = tiedScores.count
                let total = (place ..< (place + count))
                    .map({ scoringSystem.points(forFinishingPlace: $0, competitorsInStartingArea: competitorsInStartingArea) })
                    .reduce(Points(), { $0.addingFraction($1) })

                // Divide them equally. Low point and bonus point keep the split over
                // its own denominator; the accumulating systems restate it over the
                // series scale, which is always a multiple of the number tied.
                let factor = scoringSystem.accumulatesTotals ? scale / count : 1
                let splitPoints = Points(numerator: total.numerator * factor,
                                         denominator: total.denominator * count * factor)
                for raceScore in tiedScores {
                    raceScore.points = splitPoints
                }
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
        
        // Adjust points for ties per the RRS A7 rule.
        adjustPointsForTies(races: races, scores: competitorRaceScores)
        
        // Go through the results of each race, marking any ties or obvious scoring errors.
        tagResultStatus(scores: competitorRaceScores)
        
        excludeWorstScores(competitorRaceScores: competitorRaceScores, exclusions: exclusions)
        
        var scores: [SeriesScore<RaceType.CompetitorType>] = []
        for competitor in competitors {
            let raceScores = competitorRaceScores[competitor]!
            // Low point and bonus point add their race scores as proper fractions
            // (which A7 tie splitting can make of them). The averaged and high point
            // systems accumulate instead, to get total/races and earned/possible.
            let countedPoints = raceScores.map({$0.excluded ? Points() : $0.points})
            let totalPoints = scoringSystem.accumulatesTotals
                ? countedPoints.reduce(Points(), +)
                : countedPoints.reduce(Points()) { $0.addingFraction($1) }
            let sailed: Int = raceScores.map({($0.result == .dnc) ? 0 : 1}).reduce(0, +)
            let qualified = (sailed >= racesToQualify)
            scores.append(SeriesScore(competitor: competitor, racesSailed: sailed, totalPoints: totalPoints, qualified: qualified, raceScores: raceScores))
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
    
    private enum ColumnAlignment {
        case left
        case center
        case right
    }
    
    public func toMarkdown<RaceType: Race>(races: [RaceType],
                                           scores: [SeriesScore<RaceType.CompetitorType>],
                                           columns: [TableColumn<RaceType>],
                                           competitorFormatter: (RaceType.CompetitorType) -> String,
                                           debug: Bool = false) -> String {
        // Helper to escape pipe characters in markdown table cells
        func escapeMarkdownCell(_ text: String) -> String {
            return text.replacingOccurrences(of: "|", with: "\\|")
        }
        
        // Helper to count visible characters (excluding markdown formatting that doesn't render)
        // HTML comments don't count, but escape sequences like \| count as 1 visible character
        func visibleWidth(_ text: String) -> Int {
            var workingText = text
            
            // Remove HTML comments first
            while let commentStart = workingText.range(of: "<!--") {
                if let commentEnd = workingText.range(of: "-->", range: commentStart.upperBound..<workingText.endIndex) {
                    workingText.removeSubrange(commentStart.lowerBound..<commentEnd.upperBound)
                } else {
                    break
                }
            }
            
            // Remove strikethrough markers (~~text~~) - remove all ~~
            workingText = workingText.replacingOccurrences(of: "~~", with: "")
            
            // Remove italic markers (*text*) - remove all single asterisks
            // We need to preserve escaped asterisks, so handle them carefully
            var cleanedText = ""
            var i = workingText.startIndex
            while i < workingText.endIndex {
                if workingText[i] == "\\" && workingText.index(after: i) < workingText.endIndex {
                    // Escape sequence - keep both characters for now
                    cleanedText.append(workingText[i])
                    i = workingText.index(after: i)
                    cleanedText.append(workingText[i])
                    i = workingText.index(after: i)
                } else if workingText[i] == "*" {
                    // Skip italic markers
                    i = workingText.index(after: i)
                } else {
                    cleanedText.append(workingText[i])
                    i = workingText.index(after: i)
                }
            }
            
            // Now count visible characters, accounting for escape sequences
            var width = 0
            i = cleanedText.startIndex
            while i < cleanedText.endIndex {
                if cleanedText[i] == "\\" && cleanedText.index(after: i) < cleanedText.endIndex {
                    // Escaped character - count as 1 visible character
                    width += 1
                    i = cleanedText.index(i, offsetBy: 2)
                } else {
                    width += 1
                    i = cleanedText.index(after: i)
                }
            }
            return width
        }
        
        // PASS 1: Collect all cell values and determine column widths
        var allRows: [[String]] = []
        var alignments: [ColumnAlignment] = []
        
        // Build header row
        var headerCells: [String] = []
        for column in columns {
            switch column {
            case .competitor(let header, _):
                headerCells.append(header)
                alignments.append(.left)
            case .race(let raceNamer):
                for race in races {
                    headerCells.append(escapeMarkdownCell(raceNamer(race)))
                    alignments.append(.center)
                }
            case .score:
                headerCells.append("Score")
                alignments.append(.center)
            case .place:
                headerCells.append("")
                alignments.append(.right)
            case .racesSailed:
                headerCells.append("Races sailed")
                alignments.append(.center)
            case .bestThrowout:
                headerCells.append("Best throwout")
                alignments.append(.center)
            }
        }
        allRows.append(headerCells)
        
        // Build data rows
        for score in scores {
            var rowCells: [String] = []
            
            for column in columns {
                switch column {
                case .competitor:
                    var competitorText = escapeMarkdownCell(competitorFormatter(score.competitor))
                    if !score.qualified {
                        competitorText = "*" + competitorText + "*"
                    }
                    rowCells.append(competitorText)
                    
                case .race:
                    for raceScore in score.raceScores {
                        var cellText = escapeMarkdownCell(scoringSystem.describe(score: raceScore, debug: debug))
                        
                        if raceScore.excluded {
                            cellText = "~~" + cellText + "~~"
                        }
                        
                        switch raceScore.status {
                        case .tied:
                            cellText = "<!-- tied -->" + cellText
                        case .error:
                            cellText = "<!-- error -->" + cellText
                        case .ok:
                            break
                        }
                        
                        rowCells.append(cellText)
                    }
                    
                case .score:
                    var scoreText = ""
                    if !((scoringSystem == .lowPoint) && !score.qualified) {
                        scoreText = escapeMarkdownCell(scoringSystem.describe(score.totalPoints, debug: debug))
                    }
                    if !score.qualified && scoreText.isEmpty {
                        scoreText = "-"
                    }
                    rowCells.append(scoreText)
                    
                case .place:
                    let rankText = escapeMarkdownCell(score.rank.map { String($0) } ?? "")
                    rowCells.append(rankText)
                    
                case .racesSailed:
                    rowCells.append(escapeMarkdownCell(String(score.racesSailed)))
                    
                case .bestThrowout:
                    var throwoutText = ""
                    if !((scoringSystem == .lowPoint) && !score.qualified) {
                        if let bestThrowout = score.raceScores.filter({$0.excluded}).sorted(by: {scoringSystem.betterScore($0.points, $1.points)}).first {
                            throwoutText = escapeMarkdownCell(scoringSystem.describe(score: bestThrowout, debug: debug))
                        }
                    }
                    rowCells.append(throwoutText)
                }
            }
            
            allRows.append(rowCells)
        }
        
        // Calculate column widths
        var columnWidths: [Int] = Array(repeating: 0, count: alignments.count)
        for row in allRows {
            for (colIndex, cell) in row.enumerated() {
                if colIndex < columnWidths.count {
                    columnWidths[colIndex] = max(columnWidths[colIndex], visibleWidth(cell))
                }
            }
        }
        
        // Ensure center-aligned columns have minimum width of 3 (required for :-: marker)
        for (colIndex, alignment) in alignments.enumerated() {
            if colIndex < columnWidths.count && alignment == .center {
                columnWidths[colIndex] = max(3, columnWidths[colIndex])
            }
        }
        
        // Helper to pad a cell based on alignment
        func padCell(_ text: String, width: Int, alignment: ColumnAlignment) -> String {
            let visibleLen = visibleWidth(text)
            let padding = max(0, width - visibleLen)
            
            switch alignment {
            case .left:
                return text + String(repeating: " ", count: padding)
            case .right:
                return String(repeating: " ", count: padding) + text
            case .center:
                let leftPad = padding / 2
                let rightPad = padding - leftPad
                return String(repeating: " ", count: leftPad) + text + String(repeating: " ", count: rightPad)
            }
        }
        
        // PASS 2: Generate formatted markdown table
        var result = ""
        
        // Header row
        var formattedHeaderCells: [String] = []
        for (colIndex, cell) in headerCells.enumerated() {
            if colIndex < columnWidths.count && colIndex < alignments.count {
                formattedHeaderCells.append(padCell(cell, width: columnWidths[colIndex], alignment: alignments[colIndex]))
            } else {
                formattedHeaderCells.append(cell)
            }
        }
        result += "| " + formattedHeaderCells.joined(separator: " | ") + " |\n"
        
        // Alignment row - each alignment marker should match the column width
        var alignmentCells: [String] = []
        for (colIndex, alignment) in alignments.enumerated() {
            if colIndex < columnWidths.count {
                let width = columnWidths[colIndex] // Width already adjusted for center columns
                switch alignment {
                case .left:
                    // :--- format, total width should be 'width'
                    alignmentCells.append(":" + String(repeating: "-", count: max(1, width - 1)))
                case .center:
                    // :---: format, dashes in middle, total width should be 'width'
                    // width is guaranteed to be at least 3 for center columns
                    let dashCount = width - 2 // Width >= 3, so dashCount >= 1
                    alignmentCells.append(":" + String(repeating: "-", count: dashCount) + ":")
                case .right:
                    // ---: format, total width should be 'width'
                    alignmentCells.append(String(repeating: "-", count: max(1, width - 1)) + ":")
                }
            } else {
                alignmentCells.append("---")
            }
        }
        result += "| " + alignmentCells.joined(separator: " | ") + " |\n"
        
        // Data rows
        for rowIndex in 1..<allRows.count {
            let row = allRows[rowIndex]
            var formattedCells: [String] = []
            for (colIndex, cell) in row.enumerated() {
                if colIndex < columnWidths.count && colIndex < alignments.count {
                    formattedCells.append(padCell(cell, width: columnWidths[colIndex], alignment: alignments[colIndex]))
                } else {
                    formattedCells.append(cell)
                }
            }
            result += "| " + formattedCells.joined(separator: " | ") + " |\n"
        }
        
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
