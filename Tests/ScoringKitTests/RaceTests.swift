import Foundation
import Testing
@testable import ScoringKit

/// A race whose *N* is supplied by the caller rather than derived from the
/// number of results, exercising the `Race.competitorsInStartingArea`
/// requirement. This is the crewed-boat case: every sailor aboard a boat is a
/// competitor holding that boat's finishing place, but the fleet is boats.
struct CrewedRace: Race {
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
            // Six sailors across three boats. Boat placings: 1st, 2nd, 3rd.
            let race = CrewedRace(
                results: [jeff: 1, wayne: 1, bill: 2, mitch: 2, sam: 3, zack: 3],
                competitorsInStartingArea: 3)
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
        func sharedPlacesTie() throws {
            // High point deliberately does not apply the A7 tie split, so a
            // boat's whole crew earns exactly the boat's points however many
            // of them are aboard.
            let evenCrews = CrewedRace(
                results: [jeff: 1, wayne: 1, bill: 2, mitch: 2],
                competitorsInStartingArea: 2)
            let lopsidedCrews = CrewedRace(
                results: [jeff: 1, wayne: 1, sam: 1, george: 1, bill: 2],
                competitorsInStartingArea: 2)

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
            let thin = CrewedRace(
                results: [jeff: 1, wayne: 2, bill: 3, mitch: 4],
                competitorsInStartingArea: 4)
            let crowded = CrewedRace(
                results: [jeff: 1, wayne: 1, sam: 1,
                          bill: 2, george: 2,
                          zack: 3, rich: 3,
                          mitch: 4, bob: 4, daveLeblanc: 4],
                competitorsInStartingArea: 4)

            for race in [thin, crowded] {
                let scores = highPointSeries.calculateScores([race])
                let last = try #require(scores.first(where: { $0.competitor == mitch }))
                #expect(last.totalPoints.numerator == 1)
                #expect(last.totalPoints.denominator == 4)
            }
        }

        @Test("A boat that competed but did not finish scores 0/N for its crew")
        func didNotFinish() throws {
            let race = CrewedRace(
                results: [jeff: 1, wayne: 1, bill: 2, mitch: .dnf, sam: .dnf],
                competitorsInStartingArea: 3)
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
                CrewedRace(
                    results: [jeff: race == 1 ? 1 : 2, wayne: race == 1 ? 1 : 2,
                              bill: race == 1 ? 2 : 1, mitch: 3, sam: 4],
                    competitorsInStartingArea: 4)
            }
            // Day 2: only three boats; jeff's boat 1st, 1st, 2nd. He is on a
            // boat with george now, and mitch stayed home.
            let dayTwo = (1...3).map { race in
                CrewedRace(
                    results: [jeff: race == 3 ? 2 : 1, george: race == 3 ? 2 : 1,
                              bill: race == 3 ? 1 : 2, sam: 3],
                    competitorsInStartingArea: 3)
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
}
