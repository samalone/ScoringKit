# ScoringKit

A Swift package for scoring sailboat racing series under the
[Racing Rules of Sailing](https://www.sailing.org/inside-world-sailing/rules-regulations/)
Appendix A, including the US Sailing
[high point percentage](https://www.ussailing.org/competition/rules-officiating/racing-rules/scoring-a-long-series/)
system.

You supply the finishing places; ScoringKit computes the race scores, applies
throwouts and qualification requirements, breaks ties, and ranks the series.

## Installation

```swift
.package(url: "https://github.com/samalone/ScoringKit.git", from: "0.2.0"),
```

then add `ScoringKit` to your target's dependencies. Requires Swift 5.9+,
macOS 10.15+ / iOS 13+.

## Quick start

Two protocols connect ScoringKit to your data. A `Competitor` is whatever you
score — a skipper, a boat, a sailor — and needs only to be `Hashable`. A `Race`
maps competitors to results.

```swift
import ScoringKit

struct Skipper: Competitor, Identifiable {
    let id: String
    let name: String
}

struct FleetRace: Race {
    let results: [Skipper: RaceResult]
}

let ana = Skipper(id: "ana", name: "Ana Rodriguez")
let ben = Skipper(id: "ben", name: "Ben Tran")
let cy  = Skipper(id: "cy",  name: "Cy Lindstrom")

let races = [
    FleetRace(results: [ana: 1, ben: 2, cy: 3]),
    FleetRace(results: [ana: 2, ben: 1, cy: .dnf]),
    FleetRace(results: [ana: 1, ben: 3, cy: 2]),
]

let scoring = SeriesScoring(scoringSystem: .lowPoint,
                            longSeries: true,
                            qualify: .percent(n: 60, rounded: .up),
                            exclude: .upTo(n: 1))

for score in scoring.calculateScores(races) {
    print(score.textRank,
          score.competitor.name,
          scoring.scoringSystem.describe(score.totalPoints))
}
```

`calculateScores` returns `[SeriesScore]` already sorted, best first, with
`rank`, `racesSailed`, `totalPoints`, `qualified`, and a `raceScores` array
holding the per-race breakdown.

Results can be written as integers or as strings — `RaceResult` conforms to
`ExpressibleByIntegerLiteral` and `ExpressibleByStringLiteral`, so `1` and
`"DNF"` both work inline. Use `try RaceResult(userInput)` when the text comes
from outside your program; the literal form traps on bad input.

## Scoring systems

| `ScoringSystem` | Race score |
| --- | --- |
| `.lowPoint` | Finishing place; lowest total wins (RRS A4). |
| `.bonusPoint` | 0, 3, 5.7, 8, 10, 11.7, 13, then +1 per place. |
| `.lowPointAveraged` | Low point, but a series score is the average of the races sailed. |
| `.highPointPercentage` | `(N − place + 1) / N`, accumulated as earned/possible; highest percentage wins. |

`describe(_:)` formats a `Points` value for the system in question — a place for
low point, a percentage for high point. `Points` deliberately isn't `Equatable`
or `Comparable`, because whether a bigger number is better depends on the
system; read `numerator` and `denominator` if you need the raw fraction.

Under high point percentage a race a competitor didn't enter scores `0/0`, so
missing races costs nothing as long as they sail enough to qualify. That is why
`qualify` matters more than `exclude` for that system.

## Qualifying and throwouts

```swift
RacesToQualify.all                              // must sail everything
RacesToQualify.none                             // no requirement
RacesToQualify.fixed(n: 5)
RacesToQualify.percent(n: 60, rounded: .up)

RacesToExclude.none
RacesToExclude.upTo(n: 1)                       // drop the worst score
RacesToExclude.percent(n: 40, rounded: .down)
RacesToExclude.notNeededToQualify
```

Competitors who fall short of the qualification requirement sort to the bottom,
get `rank == nil`, and report `textRank == "NQ"`. Both enums also expose `name`,
`appropriateRange` and `unitSuffix` to drive a settings UI.

RRS 90.3(b) is honoured: a DNE, BFD or DGM is never thrown out — the next-worst
score is excluded instead.

## Rules implemented

- **A4 / A9** — race scores, and the long-series vs. regatta treatment of boats
  that started but did not finish. Set `longSeries` accordingly.
- **A7** — boats tied at the finishing line share the points for their place and
  the places below. A7 is not scoped to the low point system, so all four
  systems split: two boats tied for first in a fleet of four take 1.5 points
  each under low point, and 3.5 of 4 — 87.5% — under high point percentage.
- **A8.1, A8.2** — series ties are broken on best-to-worst race scores, then on
  the last race and backwards.
- **A2** — worst scores excluded, earliest race first among equals.

Each competitor's `RaceScore` carries a `status` of `.ok`, `.tied` or `.error`,
so you can flag a race where places were duplicated or skipped.

## Scoring crews rather than boats

An **entry** is the thing that races; a **competitor** is the thing that gets
scored. Usually they're the same, and you need do nothing.

They come apart when several competitors share one entry — scoring every sailor
aboard a boat individually, say, so each sailor is a competitor carrying their
boat's finishing place while the fleet is still boats. Tell a `Race` which entry
each competitor raced in:

```swift
struct CrewedRace: Race {
    let results: [Sailor: RaceResult]  // one result per sailor...
    let boats: [Sailor: BoatID]        // ...and the boat each of them sailed

    func entry(for sailor: Sailor) -> BoatID { boats[sailor]! }
}

// Three boats, six sailors. Ana and Ben win together; both score 3 of 3.
let race = CrewedRace(results: [ana: 1, ben: 1, cy: 2, dee: 2, eli: 3, fay: 3],
                      boats: [ana: x, ben: x, cy: y, dee: y, eli: z, fay: z])
```

Two things follow from that. `N` becomes the number of distinct entries that
competed, so the denominator counts boats rather than heads and the same finish
scores the same however many people came sailing that day. And A7 applies
between entries: two boats at one place are tied and split the points for their
places, while one boat's crew at one place are not tied and take their boat's
points undivided — so a crew of four scores exactly what a crew of two would.
`RaceScore.status` follows the same rule, and reports `.tied` only for boats
that really tied.

`N` can still be set by hand with `competitorsInStartingArea` when the fleet
isn't the entries in `results`.

## Rendering results

`toHTML` and `toMarkdown` build a scoring table from a column list:

```swift
var raceNumber = 0
let columns: [TableColumn<FleetRace>] = [
    .place,
    .competitor(header: "Skipper", html: { $0.name }),
    .race({ _ in raceNumber += 1; return "R\(raceNumber)" }),
    .racesSailed,
    .bestThrowout,
    .score,
]

let html = scoring.toHTML(races: races, scores: scores, columns: columns)
```

Pass `debug: true` to show the underlying fractions alongside each score.
`toMarkdown` takes an additional `competitorFormatter` for plain-text cells.

## License

MIT. See [LICENSE](LICENSE).
