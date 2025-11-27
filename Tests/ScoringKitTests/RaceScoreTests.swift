import Testing
@testable import ScoringKit

// MARK: - Initializer Tests

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

@Test func parameterizedInitializerWithSpecialResult() {
    let result = RaceResult.dnf
    let points = Points(numerator: 10, denominator: 1)
    let score = RaceScore(result: result, points: points)
    
    #expect(score.result == .dnf)
    #expect(score.points.numerator == 10)
    #expect(score.points.denominator == 1)
}

@Test func parameterizedInitializerWithFractionalPoints() {
    let result = RaceResult.finished(position: 1)
    let points = Points(numerator: 3, denominator: 4)
    let score = RaceScore(result: result, points: points)
    
    #expect(score.result == .finished(position: 1))
    #expect(score.points.numerator == 3)
    #expect(score.points.denominator == 4)
}

// MARK: - Property Modification Tests

@Test func excludedPropertyModification() {
    let score = RaceScore(result: .finished(position: 1), points: Points(5))
    
    // Initially false
    #expect(score.excluded == false)
    
    // Can be set to true
    score.excluded = true
    #expect(score.excluded == true)
    
    // Can be set back to false
    score.excluded = false
    #expect(score.excluded == false)
}

@Test func statusPropertyModification() {
    let score = RaceScore(result: .finished(position: 1), points: Points(5))
    
    // Initially .ok
    #expect(score.status == .ok)
    
    // Can be set to .tied
    score.status = .tied
    #expect(score.status == .tied)
    
    // Can be set to .error
    score.status = .error
    #expect(score.status == .error)
    
    // Can be set back to .ok
    score.status = .ok
    #expect(score.status == .ok)
}

// MARK: - All ResultStatus Cases

@Test func statusAllCases() {
    let score = RaceScore(result: .finished(position: 1), points: Points(5))
    
    score.status = .ok
    #expect(score.status == .ok)
    
    score.status = .tied
    #expect(score.status == .tied)
    
    score.status = .error
    #expect(score.status == .error)
}

// MARK: - Different RaceResult Cases

@Test func raceScoreWithDifferentResults() {
    let results: [RaceResult] = [
        .finished(position: 1),
        .finished(position: 42),
        .dnc,
        .dns,
        .ocs,
        .bfd,
        .scp,
        .dnf,
        .raf,
        .dsq,
        .dne,
        .dgm,
        .rdg,
        .zfp,
        .racing
    ]
    
    for result in results {
        let score = RaceScore(result: result, points: Points(10))
        #expect(score.result == result)
        #expect(score.points.numerator == 10)
        #expect(score.points.denominator == 1)
    }
}

// MARK: - Reference Type Behavior

@Test func referenceTypeBehavior() {
    let score1 = RaceScore(result: .finished(position: 1), points: Points(5))
    let score2 = score1
    
    // Modifying score2 should affect score1 (same reference)
    score2.excluded = true
    score2.status = .tied
    
    #expect(score1.excluded == true)
    #expect(score1.status == .tied)
    #expect(score2.excluded == true)
    #expect(score2.status == .tied)
}

// MARK: - Immutable Properties

@Test func immutableProperties() {
    let score = RaceScore(result: .finished(position: 1), points: Points(5))
    
    // result and points are let properties, so they can't be reassigned
    // This is tested implicitly - if we could reassign, the code wouldn't compile
    // But we can verify they retain their values
    #expect(score.result == .finished(position: 1))
    #expect(score.points.numerator == 5)
    #expect(score.points.denominator == 1)
    
    // However, Points is a struct, so we can't modify it through the let property
    // But we can verify the values remain unchanged
    let originalPoints = score.points
    #expect(originalPoints.numerator == 5)
    #expect(originalPoints.denominator == 1)
}

