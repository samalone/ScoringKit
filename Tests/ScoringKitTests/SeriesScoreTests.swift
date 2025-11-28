import Testing
@testable import ScoringKit

@Suite("SeriesScore Tests")
struct SeriesScoreTests {
    
    @Test func textRank() throws {
        let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
        let races = [
            TestRace(results: [jeff: 1, wayne: 2])
        ]
        let scores = scoring.calculateScores(races)
        
        #expect(scores[0].textRank == "1")
        #expect(scores[1].textRank == "2")
    }
    
    @Test func textRankNotQualified() throws {
        let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
        let races = [
            TestRace(results: [jeff: 1, wayne: 2, bill: 3]),
            TestRace(results: [jeff: 1, wayne: 2]),  // bill doesn't sail this race
        ]
        let scores = scoring.calculateScores(races)
        
        let billScore = scores.first(where: { $0.competitor == bill })!
        #expect(!billScore.qualified)
        #expect(billScore.textRank == "NQ")
    }
    
    @Test func identifiable() throws {
        let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
        let races = [
            TestRace(results: [jeff: 1, wayne: 2])
        ]
        let scores = scoring.calculateScores(races)
        
        #expect(scores[0].id == jeff.id)
        #expect(scores[1].id == wayne.id)
    }
}
