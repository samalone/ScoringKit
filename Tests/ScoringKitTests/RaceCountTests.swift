import Foundation
import Testing
@testable import ScoringKit

// MARK: - RoundingDirection Tests

@Test func roundingDirectionName() {
    #expect(RoundingDirection.up.name == "Rounded up")
    #expect(RoundingDirection.down.name == "Rounded down")
    #expect(RoundingDirection.nearest.name == "Rounded to nearest")
}

@Test func roundingDirectionRoundingRule() {
    #expect(RoundingDirection.up.roundingRule == FloatingPointRoundingRule.up)
    #expect(RoundingDirection.down.roundingRule == FloatingPointRoundingRule.down)
    #expect(RoundingDirection.nearest.roundingRule == FloatingPointRoundingRule.toNearestOrAwayFromZero)
}

@Test func roundingDirectionCaseIterable() {
    let allCases = RoundingDirection.allCases
    #expect(allCases.count == 3)
    #expect(allCases.contains(.up))
    #expect(allCases.contains(.down))
    #expect(allCases.contains(.nearest))
}

// MARK: - RacesToQualify Tests

@Test func racesToQualifyCalculateAll() {
    let qualify = RacesToQualify.all
    #expect(qualify.calculate(numberOfRaces: 5) == 5)
    #expect(qualify.calculate(numberOfRaces: 10) == 10)
    #expect(qualify.calculate(numberOfRaces: 0) == 0)
}

@Test func racesToQualifyCalculateNone() {
    let qualify = RacesToQualify.none
    #expect(qualify.calculate(numberOfRaces: 5) == 0)
    #expect(qualify.calculate(numberOfRaces: 10) == 0)
    #expect(qualify.calculate(numberOfRaces: 0) == 0)
}

@Test func racesToQualifyCalculateFixed() {
    let qualify = RacesToQualify.fixed(n: 3)
    #expect(qualify.calculate(numberOfRaces: 5) == 3)
    #expect(qualify.calculate(numberOfRaces: 10) == 3)
    #expect(qualify.calculate(numberOfRaces: 2) == 2) // min(3, 2) = 2
    #expect(qualify.calculate(numberOfRaces: 0) == 0) // min(3, 0) = 0
}

@Test func racesToQualifyCalculatePercentUp() {
    let qualify = RacesToQualify.percent(n: 75, rounded: .up)
    // 10 races * 75% = 7.5, rounded up = 8
    #expect(qualify.calculate(numberOfRaces: 10) == 8)
    // 5 races * 75% = 3.75, rounded up = 4
    #expect(qualify.calculate(numberOfRaces: 5) == 4)
    // 3 races * 75% = 2.25, rounded up = 3
    #expect(qualify.calculate(numberOfRaces: 3) == 3)
}

@Test func racesToQualifyCalculatePercentDown() {
    let qualify = RacesToQualify.percent(n: 75, rounded: .down)
    // 10 races * 75% = 7.5, rounded down = 7
    #expect(qualify.calculate(numberOfRaces: 10) == 7)
    // 5 races * 75% = 3.75, rounded down = 3
    #expect(qualify.calculate(numberOfRaces: 5) == 3)
    // 3 races * 75% = 2.25, rounded down = 2
    #expect(qualify.calculate(numberOfRaces: 3) == 2)
}

@Test func racesToQualifyCalculatePercentNearest() {
    let qualify = RacesToQualify.percent(n: 75, rounded: .nearest)
    // 10 races * 75% = 7.5, rounded to nearest = 8
    #expect(qualify.calculate(numberOfRaces: 10) == 8)
    // 5 races * 75% = 3.75, rounded to nearest = 4
    #expect(qualify.calculate(numberOfRaces: 5) == 4)
    // 3 races * 75% = 2.25, rounded to nearest = 2
    #expect(qualify.calculate(numberOfRaces: 3) == 2)
}

@Test func racesToQualifyName() {
    #expect(RacesToQualify.all.name == "All")
    #expect(RacesToQualify.none.name == "None")
    #expect(RacesToQualify.fixed(n: 5).name == "Fixed")
    #expect(RacesToQualify.percent(n: 75, rounded: .up).name == "Percent")
}

@Test func racesToQualifyAppropriateRange() {
    #expect(RacesToQualify.all.appropriateRange == nil)
    #expect(RacesToQualify.none.appropriateRange == nil)
    #expect(RacesToQualify.fixed(n: 5).appropriateRange == 0...20)
    #expect(RacesToQualify.percent(n: 75, rounded: .up).appropriateRange == 0...100)
}

@Test func racesToQualifyUnitSuffix() {
    #expect(RacesToQualify.all.unitSuffix == "")
    #expect(RacesToQualify.none.unitSuffix == "")
    #expect(RacesToQualify.fixed(n: 5).unitSuffix == "")
    #expect(RacesToQualify.percent(n: 75, rounded: .up).unitSuffix == "%")
}

// MARK: - RacesToExclude Tests

@Test func racesToExcludeCalculateNone() {
    let exclude = RacesToExclude.none
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 0)
    #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 0)
}

@Test func racesToExcludeCalculateUpTo() {
    let exclude = RacesToExclude.upTo(n: 2)
    // Can exclude up to 2, but not more than numberOfRaces - 1
    #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 2)
    #expect(exclude.calculate(numberOfRaces: 2, neededToQualify: 1) == 1) // min(2, 2-1) = 1
    #expect(exclude.calculate(numberOfRaces: 1, neededToQualify: 1) == 0) // min(2, 1-1) = 0
}

@Test func racesToExcludeCalculatePercentUp() {
    let exclude = RacesToExclude.percent(n: 20, rounded: .up)
    // 10 races * 20% = 2.0, rounded up = 2, min(2, 10-1) = 2
    #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
    // 5 races * 20% = 1.0, rounded up = 1, min(1, 5-1) = 1
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 1)
    // 3 races * 20% = 0.6, rounded up = 1, min(1, 3-1) = 1
    #expect(exclude.calculate(numberOfRaces: 3, neededToQualify: 2) == 1)
}

@Test func racesToExcludeCalculatePercentDown() {
    let exclude = RacesToExclude.percent(n: 20, rounded: .down)
    // 10 races * 20% = 2.0, rounded down = 2, min(2, 10-1) = 2
    #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
    // 5 races * 20% = 1.0, rounded down = 1, min(1, 5-1) = 1
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 1)
    // 3 races * 20% = 0.6, rounded down = 0, min(0, 3-1) = 0
    #expect(exclude.calculate(numberOfRaces: 3, neededToQualify: 2) == 0)
}

@Test func racesToExcludeCalculateNotNeededToQualify() {
    let exclude = RacesToExclude.notNeededToQualify
    // 10 races, need 5 to qualify, can exclude 10 - 5 = 5
    #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 5)
    // 5 races, need 3 to qualify, can exclude 5 - 3 = 2
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 2)
    // 5 races, need 5 to qualify, can exclude 5 - 5 = 0
    #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 5) == 0)
}

@Test func racesToExcludeName() {
    #expect(RacesToExclude.none.name == "None")
    #expect(RacesToExclude.upTo(n: 2).name == "Up to")
    #expect(RacesToExclude.percent(n: 20, rounded: .up).name == "Percent")
    #expect(RacesToExclude.notNeededToQualify.name == "Not needed to qualify")
}

@Test func racesToExcludeAppropriateRange() {
    #expect(RacesToExclude.none.appropriateRange == nil)
    #expect(RacesToExclude.notNeededToQualify.appropriateRange == nil)
    #expect(RacesToExclude.upTo(n: 2).appropriateRange == 0...10)
    #expect(RacesToExclude.percent(n: 20, rounded: .up).appropriateRange == 0...99)
}

@Test func racesToExcludeUnitSuffix() {
    #expect(RacesToExclude.none.unitSuffix == "")
    #expect(RacesToExclude.notNeededToQualify.unitSuffix == "")
    #expect(RacesToExclude.upTo(n: 2).unitSuffix == "")
    #expect(RacesToExclude.percent(n: 20, rounded: .up).unitSuffix == "%")
}

// MARK: - Codable Tests

@Test func roundingDirectionCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    for direction in RoundingDirection.allCases {
        let encoded = try encoder.encode(direction)
        let decoded = try decoder.decode(RoundingDirection.self, from: encoded)
        #expect(decoded == direction)
    }
}

@Test func racesToQualifyCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let cases: [RacesToQualify] = [
        .all,
        .none,
        .fixed(n: 5),
        .percent(n: 75, rounded: .up),
        .percent(n: 60, rounded: .down),
        .percent(n: 50, rounded: .nearest)
    ]
    
    for qualify in cases {
        let encoded = try encoder.encode(qualify)
        let decoded = try decoder.decode(RacesToQualify.self, from: encoded)
        #expect(decoded == qualify)
    }
}

@Test func racesToExcludeCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let cases: [RacesToExclude] = [
        .none,
        .upTo(n: 2),
        .percent(n: 20, rounded: .up),
        .percent(n: 30, rounded: .down),
        .notNeededToQualify
    ]
    
    for exclude in cases {
        let encoded = try encoder.encode(exclude)
        let decoded = try decoder.decode(RacesToExclude.self, from: encoded)
        #expect(decoded == exclude)
    }
}

// MARK: - Hashable Tests

@Test func racesToQualifyHashable() {
    let set1: Set<RacesToQualify> = [.all, .none, .fixed(n: 5)]
    let set2: Set<RacesToQualify> = [.all, .none, .fixed(n: 5)]
    #expect(set1 == set2)
    
    // Different values should be different
    let set3: Set<RacesToQualify> = [.all, .none, .fixed(n: 3)]
    #expect(set1 != set3)
}

@Test func racesToExcludeHashable() {
    let set1: Set<RacesToExclude> = [.none, .upTo(n: 2), .notNeededToQualify]
    let set2: Set<RacesToExclude> = [.none, .upTo(n: 2), .notNeededToQualify]
    #expect(set1 == set2)
    
    // Different values should be different
    let set3: Set<RacesToExclude> = [.none, .upTo(n: 3), .notNeededToQualify]
    #expect(set1 != set3)
}
