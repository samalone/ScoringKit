import Testing
@testable import ScoringKit

@Test func seriesScoreTextRank() throws {
    // Test textRank for qualified competitors (rank is set)
    let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
    let races = [
        TestRace(results: [jeff: 1, wayne: 2])
    ]
    let scores = scoring.calculateScores(races)
    
    // Qualified competitor should have numeric textRank
    #expect(scores[0].textRank == "1")
    #expect(scores[1].textRank == "2")
}

@Test func seriesScoreTextRankNotQualified() throws {
    // Test textRank for non-qualified competitors (rank is nil)
    // Use a scoring system that requires sailing 75% of races (4 out of 5)
    let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .percent(n: 75, rounded: .up), exclude: .none)
    let races = [
        TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
        TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
        TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
        TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
        TestRace(results: [jeff: 1, wayne: 2]),  // bill doesn't sail this race
    ]
    let scores = scoring.calculateScores(races)
    
    // Find bill's score - he only sailed 4 of 5 races, doesn't meet 75% (4 needed)
    // Actually 75% of 5 = 3.75 rounded up = 4, so bill does qualify with 4 races
    // Let's check - jeff and wayne should be qualified with rank, bill should be qualified too
    let billScore = scores.first(where: { $0.competitor == bill })!
    #expect(billScore.qualified)  // 4 >= 4 so bill qualifies
    
    // To truly test NQ, we need a competitor who sails fewer races
    // Let's create a new scenario
    let scoring2 = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
    let races2 = [
        TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
        TestRace(results: [jeff: 1, wayne: 2]),  // bill doesn't sail this race
    ]
    let scores2 = scoring2.calculateScores(races2)
    
    // bill didn't sail all races, so should be NQ
    let billScore2 = scores2.first(where: { $0.competitor == bill })!
    #expect(!billScore2.qualified)
    #expect(billScore2.textRank == "NQ")
}

@Test func seriesScoreIdentifiable() throws {
    // Test the Identifiable conformance
    let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
    let races = [
        TestRace(results: [jeff: 1, wayne: 2])
    ]
    let scores = scoring.calculateScores(races)
    
    // The id should match the competitor's id
    #expect(scores[0].id == jeff.id)
    #expect(scores[1].id == wayne.id)
}
