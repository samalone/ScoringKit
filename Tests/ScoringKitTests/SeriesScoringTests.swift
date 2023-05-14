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

let frozenFewRegatta = SeriesScoring(scoringSystem: LowPointSystem(), longSeries: false, exclude: .none, qualify: .none)
let frozenFewSeries = SeriesScoring(scoringSystem: LowPointSystem(), longSeries: true, exclude: .abovePercent(60), qualify: .abovePercent(60))

func regattaColumns() -> [TableColumn<MyRace>] {
    var raceNumber = 0
    return [ .place, .competitor("Skipper"), .race({ _ in
        raceNumber += 1
        return "\(raceNumber)"
    }), .score]
}

let seriesColumns: [TableColumn<MyRace>] = [.place, .competitor("Skipper"), .racesSailed, .score]

final class SeriesScoringTests: XCTestCase {
    func testExample() throws {
        let wayne = Skipper(name: "Wayne")
        let jeff = Skipper(name: "Jeff")
        
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
}
