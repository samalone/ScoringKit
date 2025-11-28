import Testing
@testable import ScoringKit

@Suite("RaceScore Tests")
struct RaceScoreTests {
    
    @Suite("Initializers")
    struct InitializerTests {
        @Test func defaultInitializer() {
            let score = RaceScore()
            #expect(score.result == .dnc)
            #expect(score.points.numerator == 0)
            #expect(score.points.denominator == 0)
            #expect(score.excluded == false)
            #expect(score.status == .ok)
        }
        
        @Test func parameterizedInitializer() {
            let result = RaceResult.finished(position: 3)
            let points = Points(42)
            let score = RaceScore(result: result, points: points)
            
            #expect(score.result == result)
            #expect(score.points.numerator == 42)
            #expect(score.points.denominator == 1)
            #expect(score.excluded == false)
            #expect(score.status == .ok)
        }
        
        @Test func withSpecialResult() {
            let result = RaceResult.dnf
            let points = Points(numerator: 10, denominator: 1)
            let score = RaceScore(result: result, points: points)
            
            #expect(score.result == .dnf)
            #expect(score.points.numerator == 10)
            #expect(score.points.denominator == 1)
        }
        
        @Test func withFractionalPoints() {
            let result = RaceResult.finished(position: 1)
            let points = Points(numerator: 3, denominator: 4)
            let score = RaceScore(result: result, points: points)
            
            #expect(score.result == .finished(position: 1))
            #expect(score.points.numerator == 3)
            #expect(score.points.denominator == 4)
        }
    }
    
    @Suite("Property Modification")
    struct PropertyModificationTests {
        @Test func excludedProperty() {
            let score = RaceScore(result: .finished(position: 1), points: Points(5))
            
            #expect(score.excluded == false)
            score.excluded = true
            #expect(score.excluded == true)
            score.excluded = false
            #expect(score.excluded == false)
        }
        
        @Test func statusProperty() {
            let score = RaceScore(result: .finished(position: 1), points: Points(5))
            
            #expect(score.status == .ok)
            score.status = .tied
            #expect(score.status == .tied)
            score.status = .error
            #expect(score.status == .error)
            score.status = .ok
            #expect(score.status == .ok)
        }
    }
    
    @Suite("ResultStatus Cases")
    struct ResultStatusTests {
        @Test func allCases() {
            let score = RaceScore(result: .finished(position: 1), points: Points(5))
            
            score.status = .ok
            #expect(score.status == .ok)
            
            score.status = .tied
            #expect(score.status == .tied)
            
            score.status = .error
            #expect(score.status == .error)
        }
    }
    
    @Suite("Different RaceResult Cases")
    struct DifferentResultsTests {
        @Test func allResults() {
            let results: [RaceResult] = [
                .finished(position: 1), .finished(position: 42),
                .dnc, .dns, .ocs, .bfd, .scp, .dnf, .raf, .dsq, .dne, .dgm, .rdg, .zfp, .racing
            ]
            
            for result in results {
                let score = RaceScore(result: result, points: Points(10))
                #expect(score.result == result)
                #expect(score.points.numerator == 10)
                #expect(score.points.denominator == 1)
            }
        }
    }
    
    @Suite("Reference Type Behavior")
    struct ReferenceTypeTests {
        @Test func sharedReference() {
            let score1 = RaceScore(result: .finished(position: 1), points: Points(5))
            let score2 = score1
            
            score2.excluded = true
            score2.status = .tied
            
            #expect(score1.excluded == true)
            #expect(score1.status == .tied)
            #expect(score2.excluded == true)
            #expect(score2.status == .tied)
        }
    }
    
    @Suite("Immutable Properties")
    struct ImmutablePropertiesTests {
        @Test func resultAndPoints() {
            let score = RaceScore(result: .finished(position: 1), points: Points(5))
            
            #expect(score.result == .finished(position: 1))
            #expect(score.points.numerator == 5)
            #expect(score.points.denominator == 1)
            
            let originalPoints = score.points
            #expect(originalPoints.numerator == 5)
            #expect(originalPoints.denominator == 1)
        }
    }
}
