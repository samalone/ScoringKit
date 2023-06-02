//
//  PHRFTests.swift
//  
//
//  Created by Stuart A. Malone on 6/1/23.
//

import XCTest
@testable import ScoringKit

extension Date: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self = df.date(from: value)!
    }
    
}

struct Boat: PHRFCompetitor {
    var name: String
    var rating: PHRFRating
    
    var html: String {
        return name
    }
}

extension Array where Element == Int {
    func avg() -> Int? {
        guard count > 0 else { return nil }
        return Int(round(Double(reduce(0, +)) / Double(count)))
    }
}

let bigBlue = Boat(name: "Big Blue", rating: 216)

struct PRace: PHRFRace {
    
    var startTime: Date = "2019-10-03 11:10:00"
    
    var averageRating: PHRFRating = 209
    
    var conditionsFactor: PHRFRating = 550
    
    var results: [Boat : PHRFResult] = [:]
    
    init(startTime: Date, conditionsFactor: PHRFRating, results: [Boat : String]) {
        self.startTime = startTime
        self.conditionsFactor = conditionsFactor
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        df.defaultDate = startTime
        for pair in results {
            self.results[pair.key] = PHRFResult(pair.value, format: df)!
        }
    }
    
}

func format(_ value: TimeInterval) -> String {
    let tif = DateComponentsFormatter()
    tif.allowedUnits = [.hour, .minute, .second]
    tif.unitsStyle = .positional
    
    let frac = NumberFormatter()
    frac.maximumIntegerDigits = 0
    frac.minimumFractionDigits = 2
    frac.maximumFractionDigits = 2
    frac.alwaysShowsDecimalSeparator = true
    
    let part = NSNumber(value: value.truncatingRemainder(dividingBy: 1))
    
    return tif.string(from: value)! + frac.string(from: part)!
}

final class PHRFTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This example is taken from https://www.regattanetwork.com/clubmgmt/applet_race_scores.php?regatta_id=18673&race_num=1&fleet=PHRF+Racing+2
        let race = PRace(startTime: "2023-06-06 18:20:00", conditionsFactor: 550, results: [
            bigBlue: "19:20:00"
        ])
        let races = [PHRFRaceAdapter(phrf: race)]
        for pair in race.results {
            let tcf = race.timeCorrectionFactor(of: pair.key)
            let ct = race.correctedTime(of: pair.key)!
            let ctf = format(ct)
            print("\(pair.key.name): \(ctf) \(tcf)")
        }
        let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
        let scores = scoring.calculateScores(races)
        let html = scoring.toHTML(races: races, scores: scores, columns: [.place, .competitor("Boat"), .score])
        print(html)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
