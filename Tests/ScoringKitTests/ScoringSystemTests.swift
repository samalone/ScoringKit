import Foundation
import Testing
@testable import ScoringKit

// MARK: - Enum and CaseIterable Tests

@Test func scoringSystemCaseIterable() {
    let allCases = ScoringSystem.allCases
    #expect(allCases.count == 4)
    #expect(allCases.contains(.lowPoint))
    #expect(allCases.contains(.bonusPoint))
    #expect(allCases.contains(.lowPointAveraged))
    #expect(allCases.contains(.highPointPercentage))
}

@Test func scoringSystemName() {
    #expect(ScoringSystem.lowPoint.name == "Low point")
    #expect(ScoringSystem.bonusPoint.name == "Bonus point")
    #expect(ScoringSystem.lowPointAveraged.name == "Low point averaged")
    #expect(ScoringSystem.highPointPercentage.name == "High point percentage")
}

// MARK: - computeScore Tests - Low Point

@Test func computeScoreLowPointFinished() {
    let system = ScoringSystem.lowPoint
    let result = RaceResult.finished(position: 1)
    let points = system.computeScore(result: result, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 1)
    #expect(points.denominator == 1)
}

@Test func computeScoreLowPointDNC() {
    let system = ScoringSystem.lowPoint
    let result = RaceResult.dnc
    let points = system.computeScore(result: result, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points.numerator == 9) // competitorsInSeries + 1
    #expect(points.denominator == 1)
}

@Test func computeScoreLowPointOtherResultsRegatta() {
    let system = ScoringSystem.lowPoint
    // For regatta (not long series), uses competitorsInSeries
    let points1 = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points1.numerator == 9) // competitorsInSeries + 1
    
    let points2 = system.computeScore(result: .dsq, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points2.numerator == 9)
}

@Test func computeScoreLowPointOtherResultsLongSeries() {
    let system = ScoringSystem.lowPoint
    // For long series, uses competitorsInStartingArea
    let points1 = system.computeScore(result: .dnf, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points1.numerator == 11) // competitorsInStartingArea + 1
    
    let points2 = system.computeScore(result: .dsq, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points2.numerator == 11)
}

// MARK: - computeScore Tests - Bonus Point

@Test func computeScoreBonusPointFinished() {
    let system = ScoringSystem.bonusPoint
    // Bonus points: 1st=0, 2nd=30, 3rd=57, 4th=80, 5th=100, 6th=117, 7th=130, 8th+=130+10*(n-7)
    #expect(system.computeScore(result: .finished(position: 1), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 0)
    #expect(system.computeScore(result: .finished(position: 2), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 30)
    #expect(system.computeScore(result: .finished(position: 3), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 57)
    #expect(system.computeScore(result: .finished(position: 4), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 80)
    #expect(system.computeScore(result: .finished(position: 5), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 100)
    #expect(system.computeScore(result: .finished(position: 6), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 117)
    #expect(system.computeScore(result: .finished(position: 7), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 130)
    #expect(system.computeScore(result: .finished(position: 8), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 140) // 130 + 10*(8-7)
    #expect(system.computeScore(result: .finished(position: 10), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 160) // 130 + 10*(10-7)
}

@Test func computeScoreBonusPointDNC() {
    let system = ScoringSystem.bonusPoint
    let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
    // Should use bonusPoints(position: 9) = 130 + 10*(9-7) = 150
    #expect(points.numerator == 150)
}

@Test func computeScoreBonusPointOtherResults() {
    let system = ScoringSystem.bonusPoint
    // For regatta
    let points1 = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points1.numerator == 150) // bonusPoints(position: 9) = 130 + 10*(9-7) = 150
    
    // For long series
    let points2 = system.computeScore(result: .dnf, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
    #expect(points2.numerator == 170) // bonusPoints(position: 11) = 130 + 10*(11-7) = 170
}

// MARK: - computeScore Tests - Low Point Averaged

@Test func computeScoreLowPointAveragedFinished() {
    let system = ScoringSystem.lowPointAveraged
    let points = system.computeScore(result: .finished(position: 3), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 3)
    #expect(points.denominator == 1)
}

@Test func computeScoreLowPointAveragedDNC() {
    let system = ScoringSystem.lowPointAveraged
    let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 0)
    #expect(points.denominator == 0)
}

@Test func computeScoreLowPointAveragedOtherResults() {
    let system = ScoringSystem.lowPointAveraged
    let points = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 11) // competitorsInStartingArea + 1
    #expect(points.denominator == 1)
}

// MARK: - computeScore Tests - High Point Percentage

@Test func computeScoreHighPointPercentageFinished() {
    let system = ScoringSystem.highPointPercentage
    // For position 1 in race with 10 competitors: (10 - 1 + 1) / 10 = 10/10 = 100%
    let points1 = system.computeScore(result: .finished(position: 1), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points1.numerator == 10)
    #expect(points1.denominator == 10)
    
    // For position 2: (10 - 2 + 1) / 10 = 9/10 = 90%
    let points2 = system.computeScore(result: .finished(position: 2), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points2.numerator == 9)
    #expect(points2.denominator == 10)
    
    // For position 5: (10 - 5 + 1) / 10 = 6/10 = 60%
    let points3 = system.computeScore(result: .finished(position: 5), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points3.numerator == 6)
    #expect(points3.denominator == 10)
}

@Test func computeScoreHighPointPercentageDNC() {
    let system = ScoringSystem.highPointPercentage
    let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 0)
    #expect(points.denominator == 0)
}

@Test func computeScoreHighPointPercentageOtherResults() {
    let system = ScoringSystem.highPointPercentage
    let points = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
    #expect(points.numerator == 0)
    #expect(points.denominator == 10)
}

// MARK: - betterScore Tests

@Test func betterScoreLowPoint() {
    let system = ScoringSystem.lowPoint
    #expect(system.betterScore(Points(1), Points(2))) // 1 < 2
    #expect(!system.betterScore(Points(2), Points(1))) // 2 < 1 is false
    #expect(!system.betterScore(Points(1), Points(1))) // 1 < 1 is false
}

@Test func betterScoreBonusPoint() {
    let system = ScoringSystem.bonusPoint
    #expect(system.betterScore(Points(30), Points(57))) // 30 < 57
    #expect(!system.betterScore(Points(100), Points(80))) // 100 < 80 is false
}

@Test func betterScoreLowPointAveraged() {
    let system = ScoringSystem.lowPointAveraged
    // 1/2 < 2/3? 1*3 = 3, 2*2 = 4, so 3 < 4, yes
    #expect(system.betterScore(Points(numerator: 1, denominator: 2), Points(numerator: 2, denominator: 3)))
    
    // Both zero denominators
    #expect(!system.betterScore(Points(), Points()))
    
    // Left zero denominator
    #expect(!system.betterScore(Points(), Points(5)))
    
    // Right zero denominator
    #expect(system.betterScore(Points(5), Points()))
}

@Test func betterScoreHighPointPercentage() {
    let system = ScoringSystem.highPointPercentage
    // 9/10 > 6/10? 9*10 = 90, 6*10 = 60, so 90 > 60, yes (higher is better)
    #expect(system.betterScore(Points(numerator: 9, denominator: 10), Points(numerator: 6, denominator: 10)))
    
    // Both zero denominators
    #expect(!system.betterScore(Points(), Points()))
    
    // Left zero denominator
    #expect(!system.betterScore(Points(), Points(numerator: 5, denominator: 10)))
    
    // Right zero denominator
    #expect(system.betterScore(Points(numerator: 5, denominator: 10), Points()))
}

// MARK: - sameScore Tests

@Test func sameScoreLowPoint() {
    let system = ScoringSystem.lowPoint
    #expect(system.sameScore(Points(5), Points(5)))
    #expect(!system.sameScore(Points(5), Points(6)))
}

@Test func sameScoreBonusPoint() {
    let system = ScoringSystem.bonusPoint
    #expect(system.sameScore(Points(30), Points(30)))
    #expect(!system.sameScore(Points(30), Points(57)))
}

@Test func sameScoreLowPointAveraged() {
    let system = ScoringSystem.lowPointAveraged
    // 1/2 == 2/4? 1*4 = 4, 2*2 = 4, yes
    #expect(system.sameScore(Points(numerator: 1, denominator: 2), Points(numerator: 2, denominator: 4)))
    
    // Both zero denominators
    #expect(system.sameScore(Points(), Points()))
    
    // Left zero denominator
    #expect(!system.sameScore(Points(), Points(5)))
    
    // Right zero denominator
    #expect(!system.sameScore(Points(5), Points()))
}

@Test func sameScoreHighPointPercentage() {
    let system = ScoringSystem.highPointPercentage
    // 9/10 == 18/20? 9*20 = 180, 18*10 = 180, yes
    #expect(system.sameScore(Points(numerator: 9, denominator: 10), Points(numerator: 18, denominator: 20)))
    
    // Both zero denominators
    #expect(system.sameScore(Points(), Points()))
    
    // Left zero denominator
    #expect(!system.sameScore(Points(), Points(numerator: 5, denominator: 10)))
    
    // Right zero denominator
    #expect(!system.sameScore(Points(numerator: 5, denominator: 10), Points()))
}

// MARK: - canExclude Tests

@Test func canExcludeLowPoint() {
    let system = ScoringSystem.lowPoint
    #expect(system.canExclude(result: .dnc))
    #expect(system.canExclude(result: .dnf))
    #expect(system.canExclude(result: .dsq))
    #expect(!system.canExclude(result: .dne)) // DNE is not excludable
    #expect(!system.canExclude(result: .bfd)) // BFD is not excludable
    #expect(!system.canExclude(result: .dgm)) // DGM is not excludable
}

@Test func canExcludeBonusPoint() {
    let system = ScoringSystem.bonusPoint
    #expect(system.canExclude(result: .dnc))
    #expect(system.canExclude(result: .dnf))
    #expect(!system.canExclude(result: .dne))
}

@Test func canExcludeLowPointAveraged() {
    let system = ScoringSystem.lowPointAveraged
    #expect(!system.canExclude(result: .dnc)) // DNC not excludable in averaged
    #expect(system.canExclude(result: .dnf))
    #expect(!system.canExclude(result: .dne))
}

@Test func canExcludeHighPointPercentage() {
    let system = ScoringSystem.highPointPercentage
    #expect(!system.canExclude(result: .dnc)) // DNC not excludable in high point
    #expect(system.canExclude(result: .dnf))
    #expect(!system.canExclude(result: .dne))
}

// MARK: - canDebug Tests

@Test func canDebugProperty() {
    #expect(!ScoringSystem.lowPoint.canDebug)
    #expect(ScoringSystem.bonusPoint.canDebug)
    #expect(ScoringSystem.lowPointAveraged.canDebug)
    #expect(ScoringSystem.highPointPercentage.canDebug)
}

// MARK: - describe(points:debug:) Tests

@Test func describeLowPoint() {
    let system = ScoringSystem.lowPoint
    #expect(system.describe(Points(5)) == "5")
    #expect(system.describe(Points(42)) == "42")
    #expect(system.describe(Points(0)) == "0")
}

@Test func describeBonusPoint() {
    let system = ScoringSystem.bonusPoint
    // Bonus points are stored as integers (e.g., 30 for 2nd place), displayed with 2 decimal places
    // to accommodate fractional points from tie splitting (e.g., 6.85 for tied 3rd/4th)
    #expect(system.describe(Points(30)) == "3.00")
    #expect(system.describe(Points(57)) == "5.70")
    #expect(system.describe(Points(100)) == "10.00")
    
    // Fractional points from tie (57+80)/2 = 137/2 = 6.85
    #expect(system.describe(Points(numerator: 137, denominator: 2)) == "6.85")
}

@Test func describeLowPointAveraged() {
    let system = ScoringSystem.lowPointAveraged
    #expect(system.describe(Points(numerator: 3, denominator: 4)) == "0.75")
    #expect(system.describe(Points(numerator: 1, denominator: 2)) == "0.50")
    #expect(system.describe(Points()) == "-") // Zero denominator
    
    // With debug
    #expect(system.describe(Points(numerator: 3, denominator: 4), debug: true) == "3/4 0.75")
}

@Test func describeHighPointPercentage() {
    let system = ScoringSystem.highPointPercentage
    #expect(system.describe(Points(numerator: 9, denominator: 10)) == "90.0")
    #expect(system.describe(Points(numerator: 5, denominator: 10)) == "50.0")
    #expect(system.describe(Points()) == "-") // Zero denominator
    
    // With debug
    #expect(system.describe(Points(numerator: 9, denominator: 10), debug: true) == "9/10 90.0")
}

// MARK: - describe(score:debug:) Tests

@Test func describeScoreLowPoint() {
    let system = ScoringSystem.lowPoint
    let score1 = RaceScore(result: .finished(position: 1), points: Points(1))
    #expect(system.describe(score: score1) == "1")
    
    let score2 = RaceScore(result: .dnf, points: Points(10))
    #expect(system.describe(score: score2) == "DNF 10")
    
    let score3 = RaceScore(result: .racing, points: Points(0))
    #expect(system.describe(score: score3) == "")
}

@Test func describeScoreBonusPoint() {
    let system = ScoringSystem.bonusPoint
    let score1 = RaceScore(result: .finished(position: 2), points: Points(30))
    #expect(system.describe(score: score1) == "2")
    
    let score2 = RaceScore(result: .dnf, points: Points(150))
    #expect(system.describe(score: score2) == "DNF 15.00")
}

@Test func describeScoreLowPointAveraged() {
    let system = ScoringSystem.lowPointAveraged
    let score1 = RaceScore(result: .finished(position: 3), points: Points(3))
    #expect(system.describe(score: score1) == "3")
    
    let score2 = RaceScore(result: .dnc, points: Points())
    #expect(system.describe(score: score2) == "DNC")
    
    let score3 = RaceScore(result: .dnf, points: Points(10))
    #expect(system.describe(score: score3) == "DNF")
    
    // With debug
    let score4 = RaceScore(result: .dnf, points: Points(10))
    #expect(system.describe(score: score4, debug: true) == "DNF 10")
}

@Test func describeScoreHighPointPercentage() {
    let system = ScoringSystem.highPointPercentage
    let score1 = RaceScore(result: .finished(position: 1), points: Points(numerator: 10, denominator: 10))
    #expect(system.describe(score: score1) == "1")
    
    // With debug
    #expect(system.describe(score: score1, debug: true) == "1 10/10")
    
    let score2 = RaceScore(result: .dnc, points: Points())
    #expect(system.describe(score: score2) == "DNC")
    
    let score3 = RaceScore(result: .dnf, points: Points(numerator: 0, denominator: 10))
    #expect(system.describe(score: score3) == "DNF 0")
    
    // With debug
    #expect(system.describe(score: score3, debug: true) == "DNF 0/10")
    
    let score4 = RaceScore(result: .racing, points: Points())
    #expect(system.describe(score: score4) == "")
}

// MARK: - Codable Tests

@Test func scoringSystemCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    for system in ScoringSystem.allCases {
        let encoded = try encoder.encode(system)
        let decoded = try decoder.decode(ScoringSystem.self, from: encoded)
        #expect(decoded == system)
    }
}

