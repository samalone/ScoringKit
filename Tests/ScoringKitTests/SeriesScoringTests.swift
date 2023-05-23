import XCTest
@testable import ScoringKit

struct Skipper: Competitor {
    var name: String
}

struct MyRace: Race {
    var results: [Skipper : RaceResult]
    
    init(results: [Skipper : RaceResult]) {
        self.results = results
    }
}

let frozenFewRegatta = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, exclude: .none, qualify: .none)
let frozenFewSeries = SeriesScoring(scoringSystem: .lowPoint, longSeries: true, exclude: .roundDown(percent: 40), qualify: .roundUp(percent: 60))
let highPointSeries = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, exclude: .none, qualify: .none)

let wayne = Skipper(name: "Wayne")
let jeff = Skipper(name: "Jeff")
let bill = Skipper(name: "Bill S.")
let chrisCrane = Skipper(name: "Chris Crane")
let chrisLee = Skipper(name: "Chris L.")
let jim = Skipper(name: "Jim M.")
let george = Skipper(name: "George S.")
let rich = Skipper(name: "Rich G.")
let zack = Skipper(name: "Zack")
let mitch = Skipper(name: "Mitch")

func regattaColumns() -> [TableColumn<MyRace>] {
    var raceNumber = 0
    return [ .place, .competitor("Skipper"), .race({ _ in
        raceNumber += 1
        return "\(raceNumber)"
    }), .racesSailed, .bestThrowout, .score]
}

let seriesColumns: [TableColumn<MyRace>] = [.place, .competitor("Skipper"), .racesSailed, .bestThrowout, .score]

final class SeriesScoringTests: XCTestCase {
    func testExample() throws {
        
        let races = [
            MyRace(results: [jeff: 1, wayne: 2])
        ]
        
        let scores = frozenFewRegatta.calculateScores(races)
        
        XCTAssertEqual(scores.count, 2)
        
        XCTAssertEqual(scores[0].competitor, jeff)
        XCTAssertTrue(scores[0].qualified)
        XCTAssertEqual(scores[0].racesSailed, 1)
        XCTAssertEqual(scores[0].rank, 1)
        XCTAssertEqual(scores[0].totalPoints.numerator, 1)
        XCTAssertEqual(scores[0].totalPoints.denominator, 1)
        
        XCTAssertEqual(scores[1].competitor, wayne)
        XCTAssertTrue(scores[1].qualified)
        XCTAssertEqual(scores[1].racesSailed, 1)
        XCTAssertEqual(scores[1].rank, 2)
        XCTAssertEqual(scores[1].totalPoints.numerator, 2)
        XCTAssertEqual(scores[1].totalPoints.denominator, 1)
        
        let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns())
        print(html)
    }
    
    func testRealRace() throws {
        let races = [
            MyRace(results: [bill: 1, chrisCrane: 3, chrisLee: 4, jim: 6, george: 2, jeff: 5, rich: 7]),
            MyRace(results: [bill: 1, chrisCrane: 2, chrisLee: 6, jim: 4, george: 5, jeff: 3, rich: 7]),
            MyRace(results: [bill: 2, chrisCrane: 3, chrisLee: 1, jim: 6, george: 7, jeff: 5, rich: 4]),
            MyRace(results: [bill: 1, chrisCrane: 2, chrisLee: 3, jim: 4, george: 7, jeff: 6, rich: 5]),
            MyRace(results: [bill: 1, chrisCrane: 2, chrisLee: 5, jim: 3, george: 4, jeff: 6, rich: 7]),
            MyRace(results: [bill: 1, chrisCrane: 4, chrisLee: 5, jim: 2, george: 6, jeff: 7, rich: 3]),
        ]
        
        let scores = frozenFewRegatta.calculateScores(races)
        let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns())
        print(html)
    }
    
    func testHighWinds() throws {
        let races = [
            MyRace(results: [bill: 3, chrisLee: 1, jim: 6, zack: 2, jeff: 5, chrisCrane: 4, wayne: 8, rich: 7, mitch: 9]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: 8, rich: 7, mitch: .dnf]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 2, zack: 4, jeff: 5, chrisCrane: .dnf, wayne: .dnf, rich: .dnf, mitch: 6]),
            MyRace(results: [bill: 2, chrisLee: 3, jim: 1, zack: 4, jeff: 5, chrisCrane: .dnc, wayne: 6, rich: .dnc, mitch: .dnc]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: .dnf, rich: .dnc, mitch: .dnc]),
        ]
        
        let scores = frozenFewRegatta.calculateScores(races)
        let html = frozenFewRegatta.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
        print(html)
    }
    
    func testHighWindsHighPoint() throws {
        let races = [
            MyRace(results: [bill: 3, chrisLee: 1, jim: 6, zack: 2, jeff: 5, chrisCrane: 4, wayne: 8, rich: 7, mitch: 9]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: 8, rich: 7, mitch: .dnf]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 2, zack: 4, jeff: 5, chrisCrane: .dnf, wayne: .dnf, rich: .dnf, mitch: 6]),
            MyRace(results: [bill: 2, chrisLee: 3, jim: 1, zack: 4, jeff: 5, chrisCrane: .dnc, wayne: 6, rich: .dnc, mitch: .dnc]),
            MyRace(results: [bill: 1, chrisLee: 3, jim: 4, zack: 5, jeff: 6, chrisCrane: 2, wayne: .dnf, rich: .dnc, mitch: .dnc]),
        ]
        
        let scoring = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: true, exclude: .upTo(n: 1), qualify: .roundUp(percent: 75))
        let scores = scoring.calculateScores(races)
        let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
        print(html)
    }
    
    func testSeriesScoringCoding() throws {
        let foo = String(data: try JSONEncoder().encode(frozenFewSeries), encoding: .utf8)!
        print(foo)
    }
    
    func testTiesAndErrors() throws {
        let races = [
            MyRace(results: [bill: 1, jim: 1, chrisCrane: 3, jeff: 4]),
            MyRace(results: [bill: 1, jim: 3, chrisCrane: 3, jeff: 4])
        ]
        
        let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, exclude: .none, qualify: .all)
        let scores = scoring.calculateScores(races)
        let html = scoring.toHTML(races: races, scores: scores, columns: regattaColumns(), debug: true)
        print(html)
    }
}
