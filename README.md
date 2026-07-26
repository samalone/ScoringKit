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
.package(url: "https://github.com/samalone/ScoringKit.git", from: "0.1.0"),
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
  the places below. (Not applied under high point percentage, where a shared
  place simply earns the same score.)
- **A8.1, A8.2** — series ties are broken on best-to-worst race scores, then on
  the last race and backwards.
- **A2** — worst scores excluded, earliest race first among equals.

Each competitor's `RaceScore` carries a `status` of `.ok`, `.tied` or `.error`,
so you can flag a race where places were duplicated or skipped.

## Scoring crews rather than boats

`N` — the number of entries in a race — normally comes from the results
themselves. When the competitors you score aren't the entries that raced, give
your `Race` its own `competitorsInStartingArea`.

The case this exists for: scoring every sailor aboard a boat individually. Each
sailor is a competitor holding their boat's finishing place, but the fleet is
still boats. Without the override the denominator would follow the head count,
and the same finish would score differently depending on how many people came
sailing that day.

```swift
struct CrewedRace: Race {
    let results: [Sailor: RaceResult]   // one entry per sailor
    let competitorsInStartingArea: Int  // ...but N is the number of boats
}

// Three boats. Ana and Ben win together; both score 3/3, not 3/6.
let race = CrewedRace(results: [ana: 1, ben: 1, cy: 2, dee: 2, eli: 3, fay: 3],
                      competitorsInStartingArea: 3)
```

Because high point percentage doesn't split points for a shared place, every
sailor aboard earns exactly their boat's score, however many of them there are.

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
