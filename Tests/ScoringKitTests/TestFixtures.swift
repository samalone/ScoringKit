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

/// The numeric value of a Points fraction.
///
/// A7 tie splitting can leave the same value written with different numerators
/// and denominators (7/2 and 14/4 are both 3.5), so tests that care about the
/// value rather than its representation compare through this.
func value(_ points: Points) -> Double {
    guard points.denominator != 0 else { return 0 }
    return Double(points.numerator) / Double(points.denominator)
}

/// A high point percentage score, 0...100.
func percent(_ points: Points) -> Double {
    100.0 * value(points)
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

