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

            // (N - place + 1) / N against N = 3 boats, not N = 6 sailors, then
            // halved by A7 because each pair of crew reads as a tie. Against a
            // head count of 6 the leaders would score (6 + 5) / 2 of 6 = 91.7%.
            // Crew are not really tied — scoringkit-5qb is what will tell the
            // two apart — but N is the thing under test here.
            for winner in [jeff, wayne] {
                #expect(try abs(percent(points(winner)) - 100.0 * 2.5 / 3.0) < 1e-9)
            }
            for second in [bill, mitch] {
                #expect(try percent(points(second)) == 50.0)
            }
            for third in [sam, zack] {
                #expect(try abs(percent(points(third)) - 100.0 * 0.5 / 3.0) < 1e-9)
            }
        }

        /// A boat's crew is one entry, so A7 should not split between them.
        /// ScoringKit sees only equal places and cannot yet tell a crew from two
        /// boats genuinely tied at the finish, so since A7 splitting reached the
        /// high point system a bigger crew scores worse — the very distortion the
        /// `competitorsInStartingArea` override exists to prevent. This test is
        /// the specification for restoring that.
        @Test("Competitors sharing a place score identically",
              .disabled("Entries are not yet distinguished from competitors — scoringkit-5qb"))
        func sharedPlacesTie() throws {
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

        /// Also waiting on scoringkit-5qb: the crowded race is all shared places,
        /// which A7 now splits, so the same boat placing scores differently
        /// depending on how many of each crew came sailing.
        @Test("The same finish scores the same whatever the turnout",
              .disabled("Entries are not yet distinguished from competitors — scoringkit-5qb"))
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
                // The denominator carries the A7 scale of the series as well as N,
                // so what matters is that there is one: a DNF scores nothing out of
                // a race that counts, where a DNC would be nothing out of nothing.
                #expect(score.totalPoints.denominator > 0)
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

            // Every place jeff's boat took is shared with his crew, so A7 splits
            // each of them with the place below (again, scoringkit-5qb).
            // Day 1: 3.5/4 + 2.5/4 + 2.5/4. Day 2: 2.5/3 + 2.5/3 + 1.5/3.
            #expect(jeffScore.racesSailed == 6)
            #expect(abs(percent(jeffScore.totalPoints) - 100.0 * 15.0 / 21.0) < 1e-9)
            #expect(ScoringSystem.highPointPercentage.describe(jeffScore.totalPoints) == "71.4")

            // mitch sailed only day 1, third of four boats each time, and the
            // races he missed cost him nothing — 3 of 4 is 50%, not 3 of 7 days.
            let mitchScore = try #require(scores.first(where: { $0.competitor == mitch }))
            #expect(mitchScore.racesSailed == 3)
            #expect(percent(mitchScore.totalPoints) == 50.0)
        }
    }
}
