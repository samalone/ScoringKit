import Foundation
import Testing
@testable import ScoringKit

/// A race whose competitors are the sailors aboard rather than the boats that
/// raced. Every sailor is a competitor carrying their boat's finishing place,
/// and the boat is the entry: the thing the fleet is counted in and the thing
/// an A7 tie is between.
struct CrewedRace: Race {
    var results: [Skipper: RaceResult]

    /// The boat each sailor sailed in this race. Sailors who stayed home are
    /// absent, and are their own entry.
    var boats: [Skipper: String]

    func entry(for competitor: Skipper) -> String {
        boats[competitor] ?? competitor.name
    }
}

/// Builds a crewed race from each boat's result and the crew aboard it.
func crewedRace(_ boats: [(result: RaceResult, crew: [Skipper])]) -> CrewedRace {
    var results: [Skipper: RaceResult] = [:]
    var assignment: [Skipper: String] = [:]
    for (index, boat) in boats.enumerated() {
        for sailor in boat.crew {
            results[sailor] = boat.result
            assignment[sailor] = "Boat \(index + 1)"
        }
    }
    return CrewedRace(results: results, boats: assignment)
}

/// A race that says nothing about entries but sets *N* itself.
struct FixedNRace: Race {
    var results: [Skipper: RaceResult]
    var competitorsInStartingArea: Int
}

@Suite("Race protocol")
struct RaceTests {

    @Suite("competitorsInStartingArea default")
    struct DefaultTests {
        @Test("Counts every result that is not DNC")
        func countsNonDNC() {
            let race = TestRace(results: [jeff: 1, wayne: 2, bill: .dnf, mitch: .dnc])
            #expect(race.competitorsInStartingArea == 3)
        }

        @Test("An empty race has nobody in the starting area")
        func empty() {
            #expect(TestRace(results: [:]).competitorsInStartingArea == 0)
        }

        @Test("A competitor that declares no entry is its own entry")
        func competitorIsItsOwnEntry() {
            let race = TestRace(results: [jeff: 1, wayne: 2])
            #expect(race.entry(for: jeff) == jeff)
        }
    }

    @Suite("Entries")
    struct EntryTests {
        /// N is the fleet, and the fleet is boats. Six sailors on three boats is
        /// a fleet of three — the head count must not reach the denominator.
        @Test("N counts entries, not competitors")
        func nCountsEntries() {
            let race = crewedRace([(1, [jeff, wayne]), (2, [bill, mitch]), (3, [sam, zack])])
            #expect(race.competitorsInStartingArea == 3)
        }

        @Test("A boat that did not come out is not in the starting area")
        func dncIsNotInTheStartingArea() {
            let race = crewedRace([(1, [jeff, wayne]), (2, [bill, mitch]), (.dnc, [sam, zack])])
            #expect(race.competitorsInStartingArea == 2)
        }

        @Test("Scoring uses the entries, not the number of results")
        func entriesReachScoring() throws {
            // Six sailors across three boats. Boat placings: 1st, 2nd, 3rd.
            let race = crewedRace([(1, [jeff, wayne]), (2, [bill, mitch]), (3, [sam, zack])])
            let scores = highPointSeries.calculateScores([race])

            func points(_ skipper: Skipper) throws -> Points {
                let score = try #require(scores.first(where: { $0.competitor == skipper }))
                return score.totalPoints
            }

            // (N - place + 1) / N against N = 3 boats, not N = 6 sailors.
            for winner in [jeff, wayne] {
                #expect(try points(winner).numerator == 3)
                #expect(try points(winner).denominator == 3)
            }
            for second in [bill, mitch] {
                #expect(try points(second).numerator == 2)
                #expect(try points(second).denominator == 3)
            }
            for third in [sam, zack] {
                #expect(try points(third).numerator == 1)
                #expect(try points(third).denominator == 3)
            }
        }

        @Test("Competitors sharing a place score identically")
        func sharedPlacesAreNotATie() throws {
            // A boat's crew is one entry, so A7 does not split between them and a
            // sailor earns exactly their boat's points however many are aboard.
            let evenCrews = crewedRace([(1, [jeff, wayne]), (2, [bill, mitch])])
            let lopsidedCrews = crewedRace([(1, [jeff, wayne, sam, george]), (2, [bill])])

            for race in [evenCrews, lopsidedCrews] {
                let scores = highPointSeries.calculateScores([race])
                let winner = try #require(scores.first(where: { $0.competitor == jeff }))
                #expect(winner.totalPoints.numerator == 2)
                #expect(winner.totalPoints.denominator == 2)
            }
        }

        @Test("The same finish scores the same whatever the turnout")
        func turnoutDoesNotDistort() throws {
            // Last of four boats is 1/4 whether four sailors or ten showed up.
            let thin = crewedRace([(1, [jeff]), (2, [wayne]), (3, [bill]), (4, [mitch])])
            let crowded = crewedRace([(1, [jeff, wayne, sam]),
                                      (2, [bill, george]),
                                      (3, [zack, rich]),
                                      (4, [mitch, bob, daveLeblanc])])

            for race in [thin, crowded] {
                let scores = highPointSeries.calculateScores([race])
                let last = try #require(scores.first(where: { $0.competitor == mitch }))
                #expect(last.totalPoints.numerator == 1)
                #expect(last.totalPoints.denominator == 4)
            }
        }

        /// The distinction this all exists for: two boats at one place are tied
        /// and split under A7, while one boat's crew at one place is not.
        @Test("Genuinely tied entries split, crews do not")
        func tiedEntriesSplitWithinACrewedRace() throws {
            // Three boats: two tied for first, one third. Seven sailors aboard.
            let race = crewedRace([(1, [jeff, wayne, sam]),
                                   (1, [bill, mitch]),
                                   (3, [zack, rich])])
            let scores = highPointSeries.calculateScores([race])

            func score(_ skipper: Skipper) throws -> SeriesScore<Skipper> {
                try #require(scores.first(where: { $0.competitor == skipper }))
            }

            // N = 3 boats. The tied boats split first and second: (3 + 2) / 2 of 3.
            for tied in [jeff, wayne, sam, bill, mitch] {
                #expect(try abs(percent(score(tied).totalPoints) - 100.0 * 2.5 / 3.0) < 1e-9,
                        "\(tied.name) is on a boat tied for first")
                #expect(try score(tied).raceScores[0].status == .tied)
            }
            // The next boat takes third, and its crew of two is not a tie.
            for third in [zack, rich] {
                #expect(try abs(percent(score(third).totalPoints) - 100.0 / 3.0) < 1e-9)
                #expect(try score(third).raceScores[0].status == .ok)
            }
        }

        /// A tie makes a race's points fractional, and the high point total is
        /// earned over possible, so the scale that keeps the races equally
        /// weighted has to survive the crewed race it was computed from.
        @Test("A crewed series mixing a tied race with an untied one totals correctly")
        func crewedSeriesWithATiedRace() throws {
            let races = [
                // Three boats, two tied for first: (3 + 2) / 2 of 3.
                crewedRace([(1, [jeff, wayne]), (1, [bill, mitch]), (3, [sam])]),
                // The same three boats, no tie.
                crewedRace([(1, [jeff, wayne]), (2, [bill, mitch]), (3, [sam])])
            ]
            let scores = highPointSeries.calculateScores(races)

            // jeff: 2.5 of 3 then 3 of 3 = 5.5 of 6
            let jeffScore = try #require(scores.first(where: { $0.competitor == jeff }))
            #expect(abs(percent(jeffScore.totalPoints) - 100.0 * 5.5 / 6.0) < 1e-9)
            // wayne sails with jeff, so he scores what jeff scores.
            let wayneScore = try #require(scores.first(where: { $0.competitor == wayne }))
            #expect(percent(wayneScore.totalPoints) == percent(jeffScore.totalPoints))
            // sam was third both times: 1 of 3 twice.
            let samScore = try #require(scores.first(where: { $0.competitor == sam }))
            #expect(abs(percent(samScore.totalPoints) - 100.0 / 3.0) < 1e-9)
        }

        @Test("A crew is not flagged as tied")
        func crewIsNotFlaggedTied() throws {
            let race = crewedRace([(1, [jeff, wayne]), (2, [bill, mitch]), (3, [sam])])
            let scores = highPointSeries.calculateScores([race])
            for score in scores {
                #expect(score.raceScores[0].status == .ok, "\(score.competitor.name) sails with their crew, not against them")
            }
        }

        @Test("Low point scores a crew their boat's place")
        func lowPointCrew() throws {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let race = crewedRace([(1, [jeff, wayne, sam]), (2, [bill, mitch]), (3, [zack])])
            let scores = scoring.calculateScores([race])

            for winner in [jeff, wayne, sam] {
                #expect(value(scores.first(where: { $0.competitor == winner })!.totalPoints) == 1.0)
            }
            for second in [bill, mitch] {
                #expect(value(scores.first(where: { $0.competitor == second })!.totalPoints) == 2.0)
            }
        }

        @Test("Low point splits between two tied boats, not within a crew")
        func lowPointTiedEntries() throws {
            let scoring = SeriesScoring(scoringSystem: .lowPoint, longSeries: false, qualify: .none, exclude: .none)
            let race = crewedRace([(1, [jeff, wayne]), (1, [bill, mitch]), (3, [sam])])
            let scores = scoring.calculateScores([race])

            // Two boats tied for first take (1 + 2) / 2 each; the next boat is third.
            for tied in [jeff, wayne, bill, mitch] {
                #expect(value(scores.first(where: { $0.competitor == tied })!.totalPoints) == 1.5)
            }
            #expect(value(scores.first(where: { $0.competitor == sam })!.totalPoints) == 3.0)
        }

        @Test("A boat that competed but did not finish scores 0/N for its crew")
        func didNotFinish() throws {
            let race = crewedRace([(1, [jeff, wayne]), (2, [bill]), (.dnf, [mitch, sam])])
            let scores = highPointSeries.calculateScores([race])

            for retired in [mitch, sam] {
                let score = try #require(scores.first(where: { $0.competitor == retired }))
                #expect(score.totalPoints.numerator == 0)
                #expect(score.totalPoints.denominator == 3)
                #expect(score.racesSailed == 1, "DNF still counts as a race sailed")
            }
        }

        @Test("A season totals earned over possible across differing fleet sizes")
        func seasonAccumulates() throws {
            // Day 1: four boats, three races, jeff's boat 1st, 2nd, 2nd.
            let dayOne = (1...3).map { race in
                crewedRace([(race == 1 ? 1 : 2, [jeff, wayne]),
                            (race == 1 ? 2 : 1, [bill]),
                            (3, [mitch]),
                            (4, [sam])])
            }
            // Day 2: only three boats; jeff's boat 1st, 1st, 2nd. He is on a
            // boat with george now, and mitch stayed home.
            let dayTwo = (1...3).map { race in
                crewedRace([(race == 3 ? 2 : 1, [jeff, george]),
                            (race == 3 ? 1 : 2, [bill]),
                            (3, [sam])])
            }

            let scores = highPointSeries.calculateScores(dayOne + dayTwo)
            let jeffScore = try #require(scores.first(where: { $0.competitor == jeff }))

            // Day 1: 4/4 + 3/4 + 3/4 = 10/12. Day 2: 3/3 + 3/3 + 2/3 = 8/9.
            #expect(jeffScore.totalPoints.numerator == 18)
            #expect(jeffScore.totalPoints.denominator == 21)
            #expect(jeffScore.racesSailed == 6)
            #expect(ScoringSystem.highPointPercentage.describe(jeffScore.totalPoints) == "85.7")

            // mitch sailed only day 1, and the races he missed cost him nothing.
            let mitchScore = try #require(scores.first(where: { $0.competitor == mitch }))
            #expect(mitchScore.racesSailed == 3)
            #expect(mitchScore.totalPoints.denominator == 12)
        }
    }

    @Suite("competitorsInStartingArea override")
    struct OverrideTests {
        /// The override has to reach the scoring engine, not just the call
        /// site. Before `competitorsInStartingArea` became a protocol
        /// requirement it lived only in an extension, so `collectRaceScores`
        /// statically dispatched to the default and silently ignored any
        /// override.
        @Test("Scoring uses the overridden N, not the number of results")
        func overrideReachesScoring() throws {
            let race = FixedNRace(results: [jeff: 1, wayne: 2, bill: 3], competitorsInStartingArea: 10)
            let scores = highPointSeries.calculateScores([race])
            let winner = try #require(scores.first(where: { $0.competitor == jeff }))

            // 10 of 10, not 3 of 3.
            #expect(winner.totalPoints.numerator == 10)
            #expect(winner.totalPoints.denominator == 10)
        }

        /// A race can still set N by hand, which wins over counting entries —
        /// a fleet where some boats are scored elsewhere, say.
        @Test("An explicit N wins over counting the entries")
        func overrideWinsOverEntries() throws {
            struct FixedNCrewedRace: Race {
                var results: [Skipper: RaceResult]
                var boats: [Skipper: String]
                var competitorsInStartingArea: Int
                func entry(for competitor: Skipper) -> String { boats[competitor] ?? competitor.name }
            }

            // Two boats sailed here, but the fleet on the course was five.
            let race = FixedNCrewedRace(results: [jeff: 1, wayne: 1, bill: 2],
                                        boats: [jeff: "X", wayne: "X", bill: "Y"],
                                        competitorsInStartingArea: 5)
            let scores = highPointSeries.calculateScores([race])
            let winner = try #require(scores.first(where: { $0.competitor == jeff }))

            #expect(winner.totalPoints.numerator == 5)
            #expect(winner.totalPoints.denominator == 5)
        }
    }
}
