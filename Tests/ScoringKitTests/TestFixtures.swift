import Foundation
@testable import ScoringKit

// MARK: - Test Types

struct Skipper: Competitor, Identifiable {
    var id: String { name }
    var name: String
    
    var html: String {
        name.addingUnicodeEntities()
    }
}

struct TestRace: Race {
    var results: [Skipper: RaceResult]
    
    init(results: [Skipper: RaceResult]) {
        self.results = results
    }
}

// MARK: - Test Data

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
let sam = Skipper(name: "Sam")
let daveLeblanc = Skipper(name: "Dave LeBlanc")
let bob = Skipper(name: "Bob Shaw")

// MARK: - Test Scoring Configurations

let frozenFewRegatta = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
let frozenFewSeries = SeriesScoring(scoringSystem: .lowPoint, longSeries: true, qualify: .percent(n: 60, rounded: .up), exclude: .percent(n: 40, rounded: .down))
let highPointSeries = SeriesScoring(scoringSystem: .highPointPercentage, longSeries: false, qualify: .none, exclude: .none)

// MARK: - Helper Functions

func regattaColumns() -> [TableColumn<TestRace>] {
    var raceNumber = 0
    return [ .place, .competitor(header: "Skipper", html: {$0.html}), .race({ _ in
        raceNumber += 1
        return "\(raceNumber)"
    }), .racesSailed, .bestThrowout, .score]
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func invert(skipperResults: [Skipper: [RaceResult]]) -> [TestRace] {
    guard let raceCount = skipperResults.values.map({$0.count}).max() else {
        return []
    }
    return (0..<raceCount).map { raceIndex in
        var results: [Skipper: RaceResult] = [:]
        for skipperResult in skipperResults {
            results[skipperResult.key] = skipperResult.value[safe: raceIndex] ?? .dnc
        }
        return TestRace(results: results)
    }
}

