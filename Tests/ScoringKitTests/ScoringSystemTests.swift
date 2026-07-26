import Foundation
import Testing
@testable import ScoringKit

@Suite("ScoringSystem Tests")
struct ScoringSystemTests {
    
    @Suite("Enum and Properties")
    struct EnumTests {
        @Test func caseIterable() {
            let allCases = ScoringSystem.allCases
            #expect(allCases.count == 4)
            #expect(allCases.contains(.lowPoint))
            #expect(allCases.contains(.bonusPoint))
            #expect(allCases.contains(.lowPointAveraged))
            #expect(allCases.contains(.highPointPercentage))
        }
        
        @Test func name() {
            #expect(ScoringSystem.lowPoint.name == "Low point")
            #expect(ScoringSystem.bonusPoint.name == "Bonus point")
            #expect(ScoringSystem.lowPointAveraged.name == "Low point averaged")
            #expect(ScoringSystem.highPointPercentage.name == "High point percentage")
        }
        
        @Test func canDebugProperty() {
            #expect(!ScoringSystem.lowPoint.canDebug)
            #expect(ScoringSystem.bonusPoint.canDebug)
            #expect(ScoringSystem.lowPointAveraged.canDebug)
            #expect(ScoringSystem.highPointPercentage.canDebug)
        }
    }
    
    @Suite("computeScore - Low Point")
    struct ComputeScoreLowPointTests {
        @Test func finished() {
            let system = ScoringSystem.lowPoint
            let result = RaceResult.finished(position: 1)
            let points = system.computeScore(result: result, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 1)
            #expect(points.denominator == 1)
        }
        
        @Test func dnc() {
            let system = ScoringSystem.lowPoint
            let result = RaceResult.dnc
            let points = system.computeScore(result: result, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points.numerator == 9) // competitorsInSeries + 1
            #expect(points.denominator == 1)
        }
        
        @Test func otherResultsRegatta() {
            let system = ScoringSystem.lowPoint
            // For regatta (not long series), uses competitorsInSeries
            let points1 = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points1.numerator == 9) // competitorsInSeries + 1
            
            let points2 = system.computeScore(result: .dsq, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points2.numerator == 9)
        }
        
        @Test func otherResultsLongSeries() {
            let system = ScoringSystem.lowPoint
            // For long series, uses competitorsInStartingArea
            let points1 = system.computeScore(result: .dnf, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points1.numerator == 11) // competitorsInStartingArea + 1
            
            let points2 = system.computeScore(result: .dsq, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points2.numerator == 11)
        }
    }
    
    @Suite("computeScore - Bonus Point")
    struct ComputeScoreBonusPointTests {
        @Test func finished() {
            let system = ScoringSystem.bonusPoint
            // Bonus points: 1st=0, 2nd=30, 3rd=57, 4th=80, 5th=100, 6th=117, 7th=130, 8th+=130+10*(n-7)
            #expect(system.computeScore(result: .finished(position: 1), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 0)
            #expect(system.computeScore(result: .finished(position: 2), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 30)
            #expect(system.computeScore(result: .finished(position: 3), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 57)
            #expect(system.computeScore(result: .finished(position: 4), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 80)
            #expect(system.computeScore(result: .finished(position: 5), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 100)
            #expect(system.computeScore(result: .finished(position: 6), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 117)
            #expect(system.computeScore(result: .finished(position: 7), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 130)
            #expect(system.computeScore(result: .finished(position: 8), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 140)
            #expect(system.computeScore(result: .finished(position: 10), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10).numerator == 160)
        }
        
        @Test func dnc() {
            let system = ScoringSystem.bonusPoint
            let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points.numerator == 150) // bonusPoints(position: 9)
        }
        
        @Test func otherResults() {
            let system = ScoringSystem.bonusPoint
            let points1 = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points1.numerator == 150)
            
            let points2 = system.computeScore(result: .dnf, isLongSeries: true, competitorsInStartingArea: 10, competitorsInSeries: 8)
            #expect(points2.numerator == 170)
        }
    }
    
    @Suite("computeScore - Low Point Averaged")
    struct ComputeScoreLowPointAveragedTests {
        @Test func finished() {
            let system = ScoringSystem.lowPointAveraged
            let points = system.computeScore(result: .finished(position: 3), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 3)
            #expect(points.denominator == 1)
        }
        
        @Test func dnc() {
            let system = ScoringSystem.lowPointAveraged
            let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 0)
            #expect(points.denominator == 0)
        }
        
        @Test func otherResults() {
            let system = ScoringSystem.lowPointAveraged
            let points = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 11)
            #expect(points.denominator == 1)
        }
    }
    
    @Suite("computeScore - High Point Percentage")
    struct ComputeScoreHighPointPercentageTests {
        @Test func finished() {
            let system = ScoringSystem.highPointPercentage
            let points1 = system.computeScore(result: .finished(position: 1), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points1.numerator == 10)
            #expect(points1.denominator == 10)
            
            let points2 = system.computeScore(result: .finished(position: 2), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points2.numerator == 9)
            #expect(points2.denominator == 10)
            
            let points3 = system.computeScore(result: .finished(position: 5), isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points3.numerator == 6)
            #expect(points3.denominator == 10)
        }
        
        @Test func dnc() {
            let system = ScoringSystem.highPointPercentage
            let points = system.computeScore(result: .dnc, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 0)
            #expect(points.denominator == 0)
        }
        
        @Test func otherResults() {
            let system = ScoringSystem.highPointPercentage
            let points = system.computeScore(result: .dnf, isLongSeries: false, competitorsInStartingArea: 10, competitorsInSeries: 10)
            #expect(points.numerator == 0)
            #expect(points.denominator == 10)
        }
    }
    
    @Suite("betterScore")
    struct BetterScoreTests {
        @Test func lowPoint() {
            let system = ScoringSystem.lowPoint
            #expect(system.betterScore(Points(1), Points(2)))
            #expect(!system.betterScore(Points(2), Points(1)))
            #expect(!system.betterScore(Points(1), Points(1)))
        }
        
        @Test func bonusPoint() {
            let system = ScoringSystem.bonusPoint
            #expect(system.betterScore(Points(30), Points(57)))
            #expect(!system.betterScore(Points(100), Points(80)))
        }
        
        @Test func lowPointAveraged() {
            let system = ScoringSystem.lowPointAveraged
            #expect(system.betterScore(Points(numerator: 1, denominator: 2), Points(numerator: 2, denominator: 3)))
            #expect(!system.betterScore(Points(), Points()))
            #expect(!system.betterScore(Points(), Points(5)))
            #expect(system.betterScore(Points(5), Points()))
        }
        
        @Test func highPointPercentage() {
            let system = ScoringSystem.highPointPercentage
            #expect(system.betterScore(Points(numerator: 9, denominator: 10), Points(numerator: 6, denominator: 10)))
            #expect(!system.betterScore(Points(), Points()))
            #expect(!system.betterScore(Points(), Points(numerator: 5, denominator: 10)))
            #expect(system.betterScore(Points(numerator: 5, denominator: 10), Points()))
        }
    }
    
    @Suite("sameScore")
    struct SameScoreTests {
        @Test func lowPoint() {
            let system = ScoringSystem.lowPoint
            #expect(system.sameScore(Points(5), Points(5)))
            #expect(!system.sameScore(Points(5), Points(6)))
        }
        
        @Test func bonusPoint() {
            let system = ScoringSystem.bonusPoint
            #expect(system.sameScore(Points(30), Points(30)))
            #expect(!system.sameScore(Points(30), Points(57)))
        }
        
        @Test func lowPointAveraged() {
            let system = ScoringSystem.lowPointAveraged
            #expect(system.sameScore(Points(numerator: 1, denominator: 2), Points(numerator: 2, denominator: 4)))
            #expect(system.sameScore(Points(), Points()))
            #expect(!system.sameScore(Points(), Points(5)))
            #expect(!system.sameScore(Points(5), Points()))
        }
        
        @Test func highPointPercentage() {
            let system = ScoringSystem.highPointPercentage
            #expect(system.sameScore(Points(numerator: 9, denominator: 10), Points(numerator: 18, denominator: 20)))
            #expect(system.sameScore(Points(), Points()))
            #expect(!system.sameScore(Points(), Points(numerator: 5, denominator: 10)))
            #expect(!system.sameScore(Points(numerator: 5, denominator: 10), Points()))
        }
    }
    
    @Suite("canExclude")
    struct CanExcludeTests {
        @Test func lowPoint() {
            let system = ScoringSystem.lowPoint
            #expect(system.canExclude(result: .dnc))
            #expect(system.canExclude(result: .dnf))
            #expect(system.canExclude(result: .dsq))
            #expect(!system.canExclude(result: .dne))
            #expect(!system.canExclude(result: .bfd))
            #expect(!system.canExclude(result: .dgm))
        }
        
        @Test func bonusPoint() {
            let system = ScoringSystem.bonusPoint
            #expect(system.canExclude(result: .dnc))
            #expect(system.canExclude(result: .dnf))
            #expect(!system.canExclude(result: .dne))
        }
        
        @Test func lowPointAveraged() {
            let system = ScoringSystem.lowPointAveraged
            #expect(!system.canExclude(result: .dnc))
            #expect(system.canExclude(result: .dnf))
            #expect(!system.canExclude(result: .dne))
        }
        
        @Test func highPointPercentage() {
            let system = ScoringSystem.highPointPercentage
            #expect(!system.canExclude(result: .dnc))
            #expect(system.canExclude(result: .dnf))
            #expect(!system.canExclude(result: .dne))
        }
    }
    
    @Suite("describe(points:)")
    struct DescribePointsTests {
        @Test func lowPoint() {
            let system = ScoringSystem.lowPoint
            #expect(system.describe(Points(5)) == "5")
            #expect(system.describe(Points(42)) == "42")
            #expect(system.describe(Points(0)) == "0")
        }
        
        @Test func bonusPoint() {
            let system = ScoringSystem.bonusPoint
            #expect(system.describe(Points(30)) == "3.00")
            #expect(system.describe(Points(57)) == "5.70")
            #expect(system.describe(Points(100)) == "10.00")
            #expect(system.describe(Points(numerator: 137, denominator: 2)) == "6.85")
        }
        
        @Test func lowPointAveraged() {
            let system = ScoringSystem.lowPointAveraged
            #expect(system.describe(Points(numerator: 3, denominator: 4)) == "0.75")
            #expect(system.describe(Points(numerator: 1, denominator: 2)) == "0.50")
            #expect(system.describe(Points()) == "-")
            #expect(system.describe(Points(numerator: 3, denominator: 4), debug: true) == "3/4 0.75")
        }
        
        @Test func highPointPercentage() {
            let system = ScoringSystem.highPointPercentage
            #expect(system.describe(Points(numerator: 9, denominator: 10)) == "90.0")
            #expect(system.describe(Points(numerator: 5, denominator: 10)) == "50.0")
            #expect(system.describe(Points()) == "-")
            #expect(system.describe(Points(numerator: 9, denominator: 10), debug: true) == "9/10 90.0")
        }
    }
    
    @Suite("describe(score:)")
    struct DescribeScoreTests {
        @Test func lowPoint() {
            let system = ScoringSystem.lowPoint
            #expect(system.describe(score: RaceScore(result: .finished(position: 1), points: Points(1))) == "1")
            #expect(system.describe(score: RaceScore(result: .dnf, points: Points(10))) == "DNF 10")
            #expect(system.describe(score: RaceScore(result: .racing, points: Points(0))) == "")
        }
        
        @Test func bonusPoint() {
            let system = ScoringSystem.bonusPoint
            #expect(system.describe(score: RaceScore(result: .finished(position: 2), points: Points(30))) == "2")
            #expect(system.describe(score: RaceScore(result: .dnf, points: Points(150))) == "DNF 15.00")
        }
        
        @Test func lowPointAveraged() {
            let system = ScoringSystem.lowPointAveraged
            #expect(system.describe(score: RaceScore(result: .finished(position: 3), points: Points(3))) == "3")
            #expect(system.describe(score: RaceScore(result: .dnc, points: Points())) == "DNC")
            #expect(system.describe(score: RaceScore(result: .dnf, points: Points(10))) == "DNF")
            #expect(system.describe(score: RaceScore(result: .dnf, points: Points(10)), debug: true) == "DNF 10.00")
            // The same penalty over the scale a tie elsewhere in the series imposes.
            #expect(system.describe(score: RaceScore(result: .dnf, points: Points(numerator: 20, denominator: 2)), debug: true) == "DNF 10.00")
        }
        
        @Test func highPointPercentage() {
            let system = ScoringSystem.highPointPercentage
            let score1 = RaceScore(result: .finished(position: 1), points: Points(numerator: 10, denominator: 10))
            #expect(system.describe(score: score1) == "1")
            #expect(system.describe(score: score1, debug: true) == "1 10/10")
            #expect(system.describe(score: RaceScore(result: .dnc, points: Points())) == "DNC")
            
            let score3 = RaceScore(result: .dnf, points: Points(numerator: 0, denominator: 10))
            #expect(system.describe(score: score3) == "DNF 0")
            #expect(system.describe(score: score3, debug: true) == "DNF 0/10")
            #expect(system.describe(score: RaceScore(result: .racing, points: Points())) == "")
        }
    }
    
    @Suite("Codable")
    struct CodableTests {
        @Test func encodeDecode() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            for system in ScoringSystem.allCases {
                let encoded = try encoder.encode(system)
                let decoded = try decoder.decode(ScoringSystem.self, from: encoded)
                #expect(decoded == system)
            }
        }
    }
}
