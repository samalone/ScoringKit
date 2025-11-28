import Foundation
import Testing
@testable import ScoringKit

@Suite("RaceCount Tests")
struct RaceCountTests {
    
    @Suite("RoundingDirection")
    struct RoundingDirectionTests {
        @Test func name() {
            #expect(RoundingDirection.up.name == "Rounded up")
            #expect(RoundingDirection.down.name == "Rounded down")
            #expect(RoundingDirection.nearest.name == "Rounded to nearest")
        }
        
        @Test func roundingRule() {
            #expect(RoundingDirection.up.roundingRule == FloatingPointRoundingRule.up)
            #expect(RoundingDirection.down.roundingRule == FloatingPointRoundingRule.down)
            #expect(RoundingDirection.nearest.roundingRule == FloatingPointRoundingRule.toNearestOrAwayFromZero)
        }
        
        @Test func caseIterable() {
            let allCases = RoundingDirection.allCases
            #expect(allCases.count == 3)
            #expect(allCases.contains(.up))
            #expect(allCases.contains(.down))
            #expect(allCases.contains(.nearest))
        }
        
        @Test func codable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            for direction in RoundingDirection.allCases {
                let encoded = try encoder.encode(direction)
                let decoded = try decoder.decode(RoundingDirection.self, from: encoded)
                #expect(decoded == direction)
            }
        }
    }
    
    @Suite("RacesToQualify")
    struct RacesToQualifyTests {
        @Test func calculateAll() {
            let qualify = RacesToQualify.all
            #expect(qualify.calculate(numberOfRaces: 5) == 5)
            #expect(qualify.calculate(numberOfRaces: 10) == 10)
            #expect(qualify.calculate(numberOfRaces: 0) == 0)
        }
        
        @Test func calculateNone() {
            let qualify = RacesToQualify.none
            #expect(qualify.calculate(numberOfRaces: 5) == 0)
            #expect(qualify.calculate(numberOfRaces: 10) == 0)
            #expect(qualify.calculate(numberOfRaces: 0) == 0)
        }
        
        @Test func calculateFixed() {
            let qualify = RacesToQualify.fixed(n: 3)
            #expect(qualify.calculate(numberOfRaces: 5) == 3)
            #expect(qualify.calculate(numberOfRaces: 10) == 3)
            #expect(qualify.calculate(numberOfRaces: 2) == 2)
            #expect(qualify.calculate(numberOfRaces: 0) == 0)
        }
        
        @Test func calculatePercentUp() {
            let qualify = RacesToQualify.percent(n: 75, rounded: .up)
            #expect(qualify.calculate(numberOfRaces: 10) == 8)
            #expect(qualify.calculate(numberOfRaces: 5) == 4)
            #expect(qualify.calculate(numberOfRaces: 3) == 3)
        }
        
        @Test func calculatePercentDown() {
            let qualify = RacesToQualify.percent(n: 75, rounded: .down)
            #expect(qualify.calculate(numberOfRaces: 10) == 7)
            #expect(qualify.calculate(numberOfRaces: 5) == 3)
            #expect(qualify.calculate(numberOfRaces: 3) == 2)
        }
        
        @Test func calculatePercentNearest() {
            let qualify = RacesToQualify.percent(n: 75, rounded: .nearest)
            #expect(qualify.calculate(numberOfRaces: 10) == 8)
            #expect(qualify.calculate(numberOfRaces: 5) == 4)
            #expect(qualify.calculate(numberOfRaces: 3) == 2)
        }
        
        @Test func name() {
            #expect(RacesToQualify.all.name == "All")
            #expect(RacesToQualify.none.name == "None")
            #expect(RacesToQualify.fixed(n: 5).name == "Fixed")
            #expect(RacesToQualify.percent(n: 75, rounded: .up).name == "Percent")
        }
        
        @Test func appropriateRange() {
            #expect(RacesToQualify.all.appropriateRange == nil)
            #expect(RacesToQualify.none.appropriateRange == nil)
            #expect(RacesToQualify.fixed(n: 5).appropriateRange == 0...20)
            #expect(RacesToQualify.percent(n: 75, rounded: .up).appropriateRange == 0...100)
        }
        
        @Test func unitSuffix() {
            #expect(RacesToQualify.all.unitSuffix == "")
            #expect(RacesToQualify.none.unitSuffix == "")
            #expect(RacesToQualify.fixed(n: 5).unitSuffix == "")
            #expect(RacesToQualify.percent(n: 75, rounded: .up).unitSuffix == "%")
        }
        
        @Test func codable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            let cases: [RacesToQualify] = [
                .all, .none, .fixed(n: 5),
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
        
        @Test func hashable() {
            let set1: Set<RacesToQualify> = [.all, .none, .fixed(n: 5)]
            let set2: Set<RacesToQualify> = [.all, .none, .fixed(n: 5)]
            #expect(set1 == set2)
            
            let set3: Set<RacesToQualify> = [.all, .none, .fixed(n: 3)]
            #expect(set1 != set3)
        }
    }
    
    @Suite("RacesToExclude")
    struct RacesToExcludeTests {
        @Test func calculateNone() {
            let exclude = RacesToExclude.none
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 0)
            #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 0)
        }
        
        @Test func calculateUpTo() {
            let exclude = RacesToExclude.upTo(n: 2)
            #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 2)
            #expect(exclude.calculate(numberOfRaces: 2, neededToQualify: 1) == 1)
            #expect(exclude.calculate(numberOfRaces: 1, neededToQualify: 1) == 0)
        }
        
        @Test func calculatePercentUp() {
            let exclude = RacesToExclude.percent(n: 20, rounded: .up)
            #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 1)
            #expect(exclude.calculate(numberOfRaces: 3, neededToQualify: 2) == 1)
        }
        
        @Test func calculatePercentDown() {
            let exclude = RacesToExclude.percent(n: 20, rounded: .down)
            #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 2)
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 1)
            #expect(exclude.calculate(numberOfRaces: 3, neededToQualify: 2) == 0)
        }
        
        @Test func calculateNotNeededToQualify() {
            let exclude = RacesToExclude.notNeededToQualify
            #expect(exclude.calculate(numberOfRaces: 10, neededToQualify: 5) == 5)
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 3) == 2)
            #expect(exclude.calculate(numberOfRaces: 5, neededToQualify: 5) == 0)
        }
        
        @Test func name() {
            #expect(RacesToExclude.none.name == "None")
            #expect(RacesToExclude.upTo(n: 2).name == "Up to")
            #expect(RacesToExclude.percent(n: 20, rounded: .up).name == "Percent")
            #expect(RacesToExclude.notNeededToQualify.name == "Not needed to qualify")
        }
        
        @Test func appropriateRange() {
            #expect(RacesToExclude.none.appropriateRange == nil)
            #expect(RacesToExclude.notNeededToQualify.appropriateRange == nil)
            #expect(RacesToExclude.upTo(n: 2).appropriateRange == 0...10)
            #expect(RacesToExclude.percent(n: 20, rounded: .up).appropriateRange == 0...99)
        }
        
        @Test func unitSuffix() {
            #expect(RacesToExclude.none.unitSuffix == "")
            #expect(RacesToExclude.notNeededToQualify.unitSuffix == "")
            #expect(RacesToExclude.upTo(n: 2).unitSuffix == "")
            #expect(RacesToExclude.percent(n: 20, rounded: .up).unitSuffix == "%")
        }
        
        @Test func codable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            let cases: [RacesToExclude] = [
                .none, .upTo(n: 2),
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
        
        @Test func hashable() {
            let set1: Set<RacesToExclude> = [.none, .upTo(n: 2), .notNeededToQualify]
            let set2: Set<RacesToExclude> = [.none, .upTo(n: 2), .notNeededToQualify]
            #expect(set1 == set2)
            
            let set3: Set<RacesToExclude> = [.none, .upTo(n: 3), .notNeededToQualify]
            #expect(set1 != set3)
        }
    }
}
