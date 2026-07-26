import Foundation
import Testing
@testable import ScoringKit

@Suite("SeriesScoring Tests")
struct SeriesScoringTests {
    
    @Suite("Initializer and Codable")
    struct InitializerTests {
        @Test func initializer() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            #expect(scoring.scoringSystem == .lowPoint)
            #expect(scoring.longSeries == false)
            #expect(scoring.qualify == .none)
            #expect(scoring.exclude == .none)
        }
        
        @Test func codable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: true, qualify: .percent(n: 75, rounded: .up), exclude: .upTo(n: 2))
            let encoded = try encoder.encode(scoring)
            let decoded = try decoder.decode(SeriesScoring.self, from: encoded)
            
            #expect(decoded.scoringSystem == scoring.scoringSystem)
            #expect(decoded.longSeries == scoring.longSeries)
            #expect(decoded.qualify == scoring.qualify)
            #expect(decoded.exclude == scoring.exclude)
        }
    }
    
    @Suite("calculateScores - Basic Functionality")
    struct BasicFunctionalityTests {
        @Test func emptyRaces() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races: [TestRace] = []
            let scores = scoring.calculateScores(races)
            #expect(scores.isEmpty)
        }
        
        @Test func singleRace() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores.count == 2)
            #expect(scores[0].competitor == jeff)
            #expect(scores[0].racesSailed == 1)
            #expect(scores[0].totalPoints.numerator == 1)
            #expect(scores[1].competitor == wayne)
            #expect(scores[1].racesSailed == 1)
            #expect(scores[1].totalPoints.numerator == 2)
        }
        
        @Test func multipleRaces() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 2, wayne: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores.count == 2)
            #expect(scores[0].totalPoints.numerator == 3)
            #expect(scores[1].totalPoints.numerator == 3)
            #expect(scores[0].racesSailed == 2)
            #expect(scores[1].racesSailed == 2)
        }
    }
    
    @Suite("Qualification")
    struct QualificationTests {
        @Test func qualificationAll() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.qualified)
            #expect(!wayneScore.qualified)
        }
        
        @Test func qualificationFixed() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .fixed(n: 2), exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.qualified)
            #expect(wayneScore.qualified)
        }
        
        @Test func qualificationPercent() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .percent(n: 50, rounded: .up), exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.qualified)
            #expect(wayneScore.qualified)
        }
    }
    
    @Suite("Exclusion")
    struct ExclusionTests {
        @Test func exclusionUpTo() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10]),
                TestRace(results: [jeff: 2])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.totalPoints.numerator == 3)
            #expect(jeffScore.raceScores.filter { $0.excluded }.count == 1)
        }
        
        @Test func exclusionPercent() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .percent(n: 25, rounded: .up))
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10]),
                TestRace(results: [jeff: 2]),
                TestRace(results: [jeff: 3])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.raceScores.filter { $0.excluded }.count == 1)
        }
        
        @Test func exclusionNotNeededToQualify() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .fixed(n: 2), exclude: .notNeededToQualify)
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 2]),
                TestRace(results: [jeff: 10])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.raceScores.filter { $0.excluded }.count == 1)
        }
        
        @Test func exclusionNone() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10]),
                TestRace(results: [jeff: 2])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.raceScores.filter { $0.excluded }.count == 0)
            #expect(jeffScore.totalPoints.numerator == 13)
        }
    }
    
    @Suite("Different Scoring Systems")
    struct ScoringSystemTests {
        @Test func bonusPoint() {
            let scoring = SeriesScoring(scoringSystem: .bonusPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores[0].totalPoints.numerator == 0)
            #expect(scores[1].totalPoints.numerator == 30)
        }
        
        @Test func lowPointAveraged() {
            let scoring = SeriesScoring(scoringSystem: .lowPointAveraged, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores[0].totalPoints.numerator == 1)
            #expect(scores[1].totalPoints.numerator == 2)
        }
        
        @Test func highPointPercentage() {
            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores[0].totalPoints.numerator == 2)
            #expect(scores[0].totalPoints.denominator == 2)
            #expect(scores[1].totalPoints.numerator == 1)
            #expect(scores[1].totalPoints.denominator == 2)
        }
    }
    
    @Suite("Long Series vs Regatta")
    struct SeriesTypeTests {
        @Test func longSeries() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: true, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: .dnf])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.totalPoints.numerator == 2)
        }
        
        @Test func regatta() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: .dnf])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.totalPoints.numerator == 2)
        }
    }
    
    @Suite("Ranking")
    struct RankingTests {
        @Test func basicRanking() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2, bill: 3])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores[0].rank == 1)
            #expect(scores[1].rank == 2)
            #expect(scores[2].rank == 3)
        }
        
        @Test func rankingNotQualified() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.rank == 1)
            #expect(wayneScore.rank == nil)
        }
    }
    
    @Suite("Tie Breaking")
    struct TieBreakingTests {
        @Test func tieBreakingByBestScores() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 2, wayne: 1]),
                TestRace(results: [jeff: 3, wayne: 3])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores.count == 2)
        }
        
        @Test func tieBreakingByLastRace() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 1]),
                TestRace(results: [jeff: 2, wayne: 2]),
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            #expect(scores[0].competitor == jeff)
            #expect(scores[1].competitor == wayne)
        }
    }
    
    @Suite("DNC Handling")
    struct DNCHandlingTests {
        @Test func dncNotCountedAsSailed() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .fixed(n: 1), exclude: .none)
            let races = [
                TestRace(results: [jeff: .dnc, wayne: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.racesSailed == 0)
            #expect(!jeffScore.qualified)
            #expect(wayneScore.racesSailed == 1)
            #expect(wayneScore.qualified)
        }
    }
    
    @Suite("toHTML")
    struct HTMLOutputTests {
        @Test func basic() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns())
            
            #expect(html.contains("<table"))
            #expect(html.contains("Jeff"))
            #expect(html.contains("Wayne"))
        }
        
        @Test func withExclusions() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10])
            ]
            let scores = scoring.calculateScores(races)
            let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns())
            
            #expect(html.contains("<del>"))
        }
        
        @Test func withDebug() {
            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
            
            #expect(html.contains("1 2/2") || html.contains("2/2"))
        }
    }
    
    @Suite("toMarkdown")
    struct MarkdownOutputTests {
        @Test func basic() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            let scores = scoring.calculateScores(races)
            let markdown = scoring.toMarkdown(races: races, scores: scores, columns: regattaColumns(), competitorFormatter: { $0.name })
            
            #expect(markdown.contains("|"))
            #expect(markdown.contains("Jeff"))
            #expect(markdown.contains("Wayne"))
            #expect(markdown.contains("---"))
        }
        
        @Test func withExclusions() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10])
            ]
            let scores = scoring.calculateScores(races)
            let markdown = scoring.toMarkdown(races: races, scores: scores, columns: regattaColumns(), competitorFormatter: { $0.name })
            
            #expect(markdown.contains("~~"))
        }
        
        @Test func withNotQualified() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 1])
            ]
            let scores = scoring.calculateScores(races)
            let markdown = scoring.toMarkdown(races: races, scores: scores, columns: regattaColumns(), competitorFormatter: { $0.name })
            
            #expect(markdown.contains("*Wayne*") || markdown.contains("*wayne*"))
        }
    }
    
    @Suite("sampleCSS")
    struct CSSTests {
        @Test func css() {
            let css = SeriesScoring.sampleCSS
            #expect(css.contains("body"))
            #expect(css.contains("race-scores"))
            #expect(css.contains("font-family"))
            #expect(css.contains("border-collapse"))
        }
    }
    
    @Suite("Edge Cases")
    struct EdgeCaseTests {
        @Test func competitorNotInAllRaces() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [jeff: 1, wayne: 2]),
                TestRace(results: [jeff: 2]),
                TestRace(results: [jeff: 3, wayne: 1])
            ]
            let scores = scoring.calculateScores(races)
            
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            let wayneScore = scores.first(where: { $0.competitor == wayne })!
            
            #expect(jeffScore.raceScores.count == 3)
            #expect(wayneScore.raceScores.count == 3)
            #expect(wayneScore.raceScores[1].result == .dnc)
        }
        
        @Test func multipleExclusions() {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 2))
            let races = [
                TestRace(results: [jeff: 1]),
                TestRace(results: [jeff: 10]),
                TestRace(results: [jeff: 9]),
                TestRace(results: [jeff: 2])
            ]
            let scores = scoring.calculateScores(races)
            let jeffScore = scores.first(where: { $0.competitor == jeff })!
            
            #expect(jeffScore.raceScores.filter { $0.excluded }.count == 2)
            #expect(jeffScore.totalPoints.numerator == 3)
        }
    }
    
    @Suite("Integration Tests")
    struct IntegrationTests {
        @Test func example() throws {
            let races = [
                TestRace(results: [jeff: 1, wayne: 2])
            ]
            
            let scores = frozenFewRegatta.calculateScores(races)
            
            #expect(scores.count == 2)
            
            #expect(scores[0].competitor == jeff)
            #expect(scores[0].qualified)
            #expect(scores[0].racesSailed == 1)
            #expect(scores[0].rank == 1)
            #expect(scores[0].totalPoints.numerator == 1)
            #expect(scores[0].totalPoints.denominator == 1)
            
            #expect(scores[1].competitor == wayne)
            #expect(scores[1].qualified)
            #expect(scores[1].racesSailed == 1)
            #expect(scores[1].rank == 2)
            #expect(scores[1].totalPoints.numerator == 2)
            #expect(scores[1].totalPoints.denominator == 1)
            
            let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns())
            print(html)
        }
        
        @Test func realRace() throws {
            let races = [
                TestRace(results: [bill: 1, chrisCrane: 3, chrisLee: 4, jim: 6, george: 2, jeff: 5, rich: 7]),
                TestRace(results: [bill: 1, chrisCrane: 2, chrisLee: 6, jim: 4, george: 5, jeff: 3, rich: 7]),
                TestRace(results: [bill: 2, chrisCrane: 3, chrisLee: 1, jim: 6, george: 7, jeff: 5, rich: 4]),
                TestRace(results: [bill: 1, chrisCrane: 2, chrisLee: 3, jim: 4, george: 7, jeff: 6, rich: 5]),
                TestRace(results: [bill: 1, chrisCrane: 2, chrisLee: 5, jim: 3, george: 4, jeff: 6, rich: 7]),
                TestRace(results: [bill: 1, chrisCrane: 4, chrisLee: 5, jim: 2, george: 6, jeff: 7, rich: 3]),
            ]
            
            let scores = frozenFewRegatta.calculateScores(races)
            let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns())
            print(html)
        }
        
        @Test func highWinds() throws {
            let races = [
                TestRace(results: [bill: 3, chrisLee: 1, jim: 6, zack: 2, jeff: 5, chrisCrane: 4, wayne: 8, rich: 7, mitch: 9]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: 8, rich: 7, mitch: .dnf]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 2, zack: 4, jeff: 5, chrisCrane: .dnf, wayne: .dnf, rich: .dnf, mitch: 6]),
                TestRace(results: [bill: 2, chrisLee: 3, jim: 1, zack: 4, jeff: 5, chrisCrane: .dnc, wayne: 6, rich: .dnc, mitch: .dnc]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: .dnf, rich: .dnc, mitch: .dnc]),
            ]
            
            let scores = frozenFewRegatta.calculateScores(races)
            let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
            print(html)
        }
        
        @Test func highWindsHighPoint() throws {
            let races = [
                TestRace(results: [bill: 3, chrisLee: 1, jim: 6, zack: 2, jeff: 5, chrisCrane: 4, wayne: 8, rich: 7, mitch: 9]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: 8, rich: 7, mitch: .dnf]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 2, zack: 4, jeff: 5, chrisCrane: .dnf, wayne: .dnf, rich: .dnf, mitch: 6]),
                TestRace(results: [bill: 2, chrisLee: 3, jim: 1, zack: 4, jeff: 5, chrisCrane: .dnc, wayne: 6, rich: .dnc, mitch: .dnc]),
                TestRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: .dnf, rich: .dnc, mitch: .dnc]),
            ]
            
            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: true, qualify: .percent(n: 75, rounded: .up), exclude: .upTo(n: 1))
            let scores = scoring.calculateScores(races)
            let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
            print(html)
        }
        
        @Test func seriesScoringCoding() throws {
            let foo = String(data: try JSONEncoder().encode(frozenFewSeries), encoding: .utf8)!
            print(foo)
        }
        
        @Test func tiesAndErrors() throws {
            let races = [
                TestRace(results: [bill: 1, jim: 1, chrisCrane: 3, jeff: 4]),
                TestRace(results: [bill: 1, jim: 3, chrisCrane: 3, jeff: 4])
            ]
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .all, exclude: .none)
            let scores = scoring.calculateScores(races)
            let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
            print(html)
        }
        
        @Test func tie() throws {
            let skipperResults: [Skipper: [RaceResult]] = [
                chrisCrane: [2, 1, 1, 4, 4, 1],
                sam: [1, 4, 5, 3, 3, 2],
                chrisLee: [8, 8, 3, 2, 1, 3],
                jeff: [3, 3, 2, 5, 6, 6],
                george: [4, 2, 4, 6, 5, 8],
                daveLeblanc: [6, 5, 6, 7, 2, 5],
                rich: [5, 7, 10, 1, 8, 7],
                zack: [7, 6, 7, 8, 7, 4],
                bob: [9, 10, 8, 9, 9, 9],
                mitch: [10, 9, 9, 10, 10, "DNF"],
             ]
            let races = invert(skipperResults: skipperResults)
            let scoring = frozenFewRegatta
            for _ in 0 ..< 100 {
                let scores = scoring.calculateScores(races)
                #expect(scores[2].competitor == chrisLee)
                #expect(scores[3].competitor == jeff)
            }
        }
    }
}

@Suite("US Sailing Appendix A Examples")
struct USSailingAppendixATests {
    
    @Suite("A7 - Race Ties")
    struct A7RaceTiesTests {
        @Test func twoBoatsTiedForThird() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatC: 1, boatD: 2, boatA: 3, boatB: 3])
            ]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!
            let scoreD = scores.first(where: { $0.competitor == boatD })!
            
            #expect(scoreA.raceScores[0].status == .tied)
            #expect(scoreB.raceScores[0].status == .tied)
            
            // Per US Sailing A7: (3 + 4) / 2 = 7/2 = 3.5
            #expect(scoreA.raceScores[0].points.numerator == 7)
            #expect(scoreA.raceScores[0].points.denominator == 2)
            #expect(scoreB.raceScores[0].points.numerator == 7)
            #expect(scoreB.raceScores[0].points.denominator == 2)
            
            #expect(scoreC.raceScores[0].points.numerator == 1)
            #expect(scoreC.raceScores[0].points.denominator == 1)
            #expect(scoreD.raceScores[0].points.numerator == 2)
            #expect(scoreD.raceScores[0].points.denominator == 1)
            
            #expect(scoreA.totalPoints.numerator == 7)
            #expect(scoreA.totalPoints.denominator == 2)
        }
        
        @Test func threeWayTie() {
            let boat1 = Skipper(name: "Boat 1")
            let boat2 = Skipper(name: "Boat 2")
            let boat3 = Skipper(name: "Boat 3")
            let boat4 = Skipper(name: "Boat 4")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boat1: 1, boat2: 2, boat3: 2, boat4: 2])
            ]
            let scores = scoring.calculateScores(races)
            
            let score1 = scores.first(where: { $0.competitor == boat1 })!
            let score2 = scores.first(where: { $0.competitor == boat2 })!
            let score3 = scores.first(where: { $0.competitor == boat3 })!
            let score4 = scores.first(where: { $0.competitor == boat4 })!
            
            #expect(score1.raceScores[0].points.numerator == 1)
            #expect(score1.raceScores[0].points.denominator == 1)
            
            // (2+3+4)/3 = 9/3
            #expect(score2.raceScores[0].points.numerator == 9)
            #expect(score2.raceScores[0].points.denominator == 3)
            #expect(score3.raceScores[0].points.numerator == 9)
            #expect(score3.raceScores[0].points.denominator == 3)
            #expect(score4.raceScores[0].points.numerator == 9)
            #expect(score4.raceScores[0].points.denominator == 3)
        }
        
        @Test func bonusPointTies() {
            let boat1 = Skipper(name: "Boat 1")
            let boat2 = Skipper(name: "Boat 2")
            let boat3 = Skipper(name: "Boat 3")
            let boat4 = Skipper(name: "Boat 4")
            
            let scoring = SeriesScoring(scoringSystem: .bonusPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boat1: 1, boat2: 2, boat3: 3, boat4: 3])
            ]
            let scores = scoring.calculateScores(races)
            
            let score1 = scores.first(where: { $0.competitor == boat1 })!
            let score2 = scores.first(where: { $0.competitor == boat2 })!
            let score3 = scores.first(where: { $0.competitor == boat3 })!
            let score4 = scores.first(where: { $0.competitor == boat4 })!
            
            #expect(score1.raceScores[0].points.numerator == 0)
            #expect(score1.raceScores[0].points.denominator == 1)
            
            #expect(score2.raceScores[0].points.numerator == 30)
            #expect(score2.raceScores[0].points.denominator == 1)
            
            // (57+80)/2 = 137/2
            #expect(score3.raceScores[0].points.numerator == 137)
            #expect(score3.raceScores[0].points.denominator == 2)
            #expect(score4.raceScores[0].points.numerator == 137)
            #expect(score4.raceScores[0].points.denominator == 2)
        }
        
        @Test func allTiedForFirst() {
            let boat1 = Skipper(name: "Boat 1")
            let boat2 = Skipper(name: "Boat 2")
            let boat3 = Skipper(name: "Boat 3")

            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boat1: 1, boat2: 1, boat3: 1])
            ]
            let scores = scoring.calculateScores(races)

            // (1+2+3)/3 = 6/3
            for score in scores {
                #expect(score.raceScores[0].points.numerator == 6)
                #expect(score.raceScores[0].points.denominator == 3)
            }
        }

        // A7 is not scoped to the low point system. US Sailing's Scoring a Long
        // Series X4 scores race ties under A7 for the high point percentage
        // system too, so every system splits the tied places.

        @Test func highPointTwoBoatsTiedForFirst() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3, boatD: 4])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!
            let scoreD = scores.first(where: { $0.competitor == boatD })!

            #expect(scoreA.raceScores[0].status == .tied)
            #expect(scoreB.raceScores[0].status == .tied)

            // N = 4, so first scores 4 and second scores 3: (4 + 3) / 2 = 3.5 of 4.
            #expect(percent(scoreA.raceScores[0].points) == 87.5)
            #expect(percent(scoreB.raceScores[0].points) == 87.5)

            // The next boat takes third place, not second: 2 of 4.
            #expect(percent(scoreC.raceScores[0].points) == 50.0)
            #expect(percent(scoreD.raceScores[0].points) == 25.0)

            #expect(percent(scoreA.totalPoints) == 87.5)
            #expect(percent(scoreC.totalPoints) == 50.0)
        }

        @Test func highPointThreeWayTie() {
            let boat1 = Skipper(name: "Boat 1")
            let boat2 = Skipper(name: "Boat 2")
            let boat3 = Skipper(name: "Boat 3")
            let boat4 = Skipper(name: "Boat 4")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boat1: 1, boat2: 2, boat3: 2, boat4: 2])
            ]
            let scores = scoring.calculateScores(races)

            let score1 = scores.first(where: { $0.competitor == boat1 })!
            let score2 = scores.first(where: { $0.competitor == boat2 })!
            let score3 = scores.first(where: { $0.competitor == boat3 })!
            let score4 = scores.first(where: { $0.competitor == boat4 })!

            #expect(percent(score1.raceScores[0].points) == 100.0)

            // Places 2, 3 and 4 score 3, 2 and 1 of 4: (3 + 2 + 1) / 3 = 2 of 4.
            #expect(percent(score2.raceScores[0].points) == 50.0)
            #expect(percent(score3.raceScores[0].points) == 50.0)
            #expect(percent(score4.raceScores[0].points) == 50.0)
        }

        /// The high point series total is earned/possible, so a race whose points
        /// turned fractional must not end up weighted differently from the rest.
        @Test func highPointSeriesMixingTiedAndUntiedRaces() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3, boatD: 4]),
                TestRace(results: [boatA: 1, boatB: 2, boatC: 3, boatD: 4])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!

            // A: 3.5 of 4 then 4 of 4 = 7.5 of 8 = 93.75%
            #expect(percent(scoreA.totalPoints) == 93.75)
            // B: 3.5 of 4 then 3 of 4 = 6.5 of 8 = 81.25%
            #expect(percent(scoreB.totalPoints) == 81.25)
            // C: 2 of 4 twice = 4 of 8 = 50%
            #expect(percent(scoreC.totalPoints) == 50.0)

            #expect(scoreA.rank == 1)
            #expect(scoreB.rank == 2)
            #expect(scoreC.rank == 3)
        }

        /// Races have different fleet sizes, and a boat that misses a race is
        /// scored only on the races she sails, so the tie must not disturb
        /// either weighting.
        @Test func highPointTieWithVaryingFleetSizes() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                // N = 4, A and B tied for first.
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3, boatD: 4]),
                // N = 3, no tie, D did not come to the starting area.
                TestRace(results: [boatA: 2, boatB: 1, boatC: 3, boatD: .dnc])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreD = scores.first(where: { $0.competitor == boatD })!

            // A: 3.5 of 4 then 2 of 3 = 5.5 of 7
            #expect(abs(percent(scoreA.totalPoints) - 100.0 * 5.5 / 7.0) < 1e-9)
            // D: 1 of 4 in the only race she sailed
            #expect(percent(scoreD.totalPoints) == 25.0)
        }

        @Test func lowPointAveragedTie() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .lowPointAveraged, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatC: 1, boatD: 2, boatA: 3, boatB: 3])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!
            let scoreD = scores.first(where: { $0.competitor == boatD })!

            #expect(scoreA.raceScores[0].status == .tied)
            #expect(scoreB.raceScores[0].status == .tied)

            // (3 + 4) / 2 = 3.5
            #expect(value(scoreA.raceScores[0].points) == 3.5)
            #expect(value(scoreB.raceScores[0].points) == 3.5)
            #expect(value(scoreC.raceScores[0].points) == 1.0)
            #expect(value(scoreD.raceScores[0].points) == 2.0)

            // The series score is the average of the race scores.
            #expect(value(scoreA.totalPoints) == 3.5)
            #expect(value(scoreC.totalPoints) == 1.0)
        }

        /// The averaged system divides by the number of races counted, so a race
        /// with split points still has to count as exactly one race.
        @Test func lowPointAveragedSeriesMixingTiedAndUntiedRaces() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .lowPointAveraged, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatC: 1, boatD: 2, boatA: 3, boatB: 3]),
                TestRace(results: [boatA: 1, boatB: 2, boatC: 3, boatD: 4])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!

            // A: (3.5 + 1) / 2 = 2.25
            #expect(value(scoreA.totalPoints) == 2.25)
            // B: (3.5 + 2) / 2 = 2.75
            #expect(value(scoreB.totalPoints) == 2.75)
            // C: (1 + 3) / 2 = 2
            #expect(value(scoreC.totalPoints) == 2.0)

            // Lowest average wins: C (2), A (2.25), B (2.75)
            #expect(scoreC.rank == 1)
            #expect(scoreA.rank == 2)
            #expect(scoreB.rank == 3)
        }

        /// A boat that misses a race is scored on the races she sails, so a DNC
        /// must stay out of the average even when another race has split points.
        @Test func lowPointAveragedTieWithDNC() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")

            let scoring = SeriesScoring(scoringSystem: .lowPointAveraged, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3]),
                TestRace(results: [boatA: 2, boatB: 1, boatC: .dnc])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!

            // A: ((1 + 2) / 2 + 2) / 2 = 1.75
            #expect(value(scoreA.totalPoints) == 1.75)
            // C: her one race, 3
            #expect(value(scoreC.totalPoints) == 3.0)
        }

        /// An excluded race drops out of both the earned and the possible points,
        /// which has to stay true of a race whose points a tie made fractional.
        @Test func highPointTieWithAThrowout() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3, boatD: 4]),
                TestRace(results: [boatA: 4, boatB: 2, boatC: 3, boatD: 1]),
                TestRace(results: [boatA: 1, boatB: 2, boatC: 3, boatD: 4])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!

            // A throws out her 1 of 4 and keeps 3.5 of 4 and 4 of 4 = 7.5 of 8
            #expect(scoreA.raceScores[1].excluded)
            #expect(percent(scoreA.totalPoints) == 93.75)
            // B throws out a 3 of 4 and keeps 3.5 of 4 and 3 of 4 = 6.5 of 8
            #expect(percent(scoreB.totalPoints) == 81.25)
        }

        /// Ties of different sizes in the same series have to share one common
        /// scale, or the races they belong to carry different weight.
        @Test func highPointTiesOfDifferentSizes() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")

            let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)
            let races = [
                // A and B tie for first: (4 + 3) / 2 = 3.5 of 4
                TestRace(results: [boatA: 1, boatB: 1, boatC: 3, boatD: 4]),
                // B, C and D tie for second: (3 + 2 + 1) / 3 = 2 of 4
                TestRace(results: [boatA: 1, boatB: 2, boatC: 2, boatD: 2])
            ]
            let scores = scoring.calculateScores(races)

            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!

            // A: 3.5 of 4 then 4 of 4 = 7.5 of 8 = 93.75%
            #expect(percent(scoreA.totalPoints) == 93.75)
            // B: 3.5 of 4 then 2 of 4 = 5.5 of 8 = 68.75%
            #expect(percent(scoreB.totalPoints) == 68.75)
        }

        /// Scoring is driven by dictionaries, whose iteration order varies from
        /// run to run. Splitting points must not depend on that order.
        @Test func tieSplittingIsDeterministic() {
            let skipperResults: [Skipper: [RaceResult]] = [
                chrisCrane: [1, 1, 1, 4, 4, 1],
                sam: [1, 4, 5, 3, 3, 2],
                chrisLee: [8, 8, 3, 2, 1, 3],
                jeff: [3, 3, 2, 5, 6, 6],
                george: [4, 2, 4, 6, 5, 8],
                daveLeblanc: [6, 5, 6, 7, 2, 5],
                rich: [5, 7, 10, 1, 8, 7],
                zack: [7, 6, 7, 8, 7, 4],
                bob: [9, 10, 8, 9, 9, 9],
                mitch: [10, 9, 9, 10, 10, "DNF"],
            ]
            let races = invert(skipperResults: skipperResults)

            func totals(_ scoring: SeriesScoring) -> [Skipper: Double] {
                Dictionary(uniqueKeysWithValues: scoring.calculateScores(races).map {
                    ($0.competitor, value($0.totalPoints))
                })
            }

            for system in ScoringSystem.allCases {
                let scoring = SeriesScoring(scoringSystem: system, longSeries: false, qualify: .none, exclude: .none)
                let expected = totals(scoring)
                for _ in 0 ..< 100 {
                    #expect(totals(scoring) == expected)
                }
            }
        }
    }
    
    @Suite("A8.1 - Series Tie Breaking by Best Scores")
    struct A81SeriesTieBreakingTests {
        @Test func byBestScores() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [boatA: 1, boatB: 2, boatC: 1]),
                TestRace(results: [boatA: 2, boatB: 1, boatC: 2]),
                TestRace(results: [boatA: 3, boatB: 3, boatC: 7]),
                TestRace(results: [boatA: 4, boatB: 4, boatC: 3]),
                TestRace(results: [boatA: 5, boatB: 5, boatC: 3]),
                TestRace(results: [boatA: 1, boatB: 1, boatC: 14])
            ]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!
            
            // With A7 point splitting applied
            #expect(scoreA.totalPoints.numerator == 27)
            #expect(scoreA.totalPoints.denominator == 2)
            #expect(scoreB.totalPoints.numerator == 25)
            #expect(scoreB.totalPoints.denominator == 2)
            #expect(scoreC.totalPoints.numerator == 34)
            #expect(scoreC.totalPoints.denominator == 2)
            
            // Rankings: B (12.5) < A (13.5) < C (17)
            #expect(scoreB.rank == 1)
            #expect(scoreA.rank == 2)
            #expect(scoreC.rank == 3)
        }
    }
    
    @Suite("A8.2 - Series Tie Breaking by Last Race")
    struct A82SeriesTieBreakingTests {
        @Test func byLastRace() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            let races = [
                TestRace(results: [boatA: 3, boatB: 11, boatC: 5, boatD: 4]),
                TestRace(results: [boatA: 4, boatB: 3, boatC: 15, boatD: 5]),
                TestRace(results: [boatA: 5, boatB: 4, boatC: 3, boatD: 6]),
                TestRace(results: [boatA: 10, boatB: 5, boatC: 4, boatD: 3])
            ]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            let scoreC = scores.first(where: { $0.competitor == boatC })!
            let scoreD = scores.first(where: { $0.competitor == boatD })!
            
            #expect(scoreA.totalPoints.numerator == 12)
            #expect(scoreB.totalPoints.numerator == 12)
            #expect(scoreC.totalPoints.numerator == 12)
            #expect(scoreD.totalPoints.numerator == 12)
            
            // A8.2: D(3), C(4), B(5), A(10)
            #expect(scoreD.rank == 1)
            #expect(scoreC.rank == 2)
            #expect(scoreB.rank == 3)
            #expect(scoreA.rank == 4)
        }
    }
    
    @Suite("A4.2 - Penalty Examples")
    struct A42PenaltyTests {
        @Test func zfpPenalty() {
            var boats: [Skipper] = []
            for i in 1...23 {
                boats.append(Skipper(name: "Boat \(i)"))
            }
            
            let boatA = boats[0]
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            
            var results: [Skipper: RaceResult] = [:]
            results[boatA] = .zfp
            
            var position = 1
            for boat in boats {
                if boat != boatA {
                    if position == 3 {
                        position = 4
                    }
                    results[boat] = .finished(position: position)
                    position += 1
                }
            }
            
            let races = [TestRace(results: results)]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            
            #expect(scoreA.raceScores[0].result == .zfp)
        }
        
        @Test func zfpPenaltyWithDisqualification() {
            let boatA = Skipper(name: "Boat A")
            let boatB = Skipper(name: "Boat B")
            let boatC = Skipper(name: "Boat C")
            let boatD = Skipper(name: "Boat D")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            
            let races = [
                TestRace(results: [
                    boatC: .finished(position: 1),
                    boatB: .dsq,
                    boatA: .zfp,
                    boatD: .finished(position: 4)
                ])
            ]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            let scoreB = scores.first(where: { $0.competitor == boatB })!
            
            #expect(scoreB.raceScores[0].result == .dsq)
            #expect(scoreB.raceScores[0].points.numerator == 5)
            
            #expect(scoreA.raceScores[0].result == .zfp)
        }
    }
    
    @Suite("A2 - Score Exclusion")
    struct A2ExclusionTests {
        @Test func equalWorstScoresExclusion() {
            let boatA = Skipper(name: "Boat A")
            
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .upTo(n: 1))
            
            let races = [
                TestRace(results: [boatA: 1]),
                TestRace(results: [boatA: 2]),
                TestRace(results: [boatA: 5]),
                TestRace(results: [boatA: 5])
            ]
            let scores = scoring.calculateScores(races)
            
            let scoreA = scores.first(where: { $0.competitor == boatA })!
            
            #expect(scoreA.raceScores[0].excluded == false)
            #expect(scoreA.raceScores[1].excluded == false)
            #expect(scoreA.raceScores[2].excluded == true)
            #expect(scoreA.raceScores[3].excluded == false)
            
            #expect(scoreA.totalPoints.numerator == 8)
        }
    }
}
