//
//  Race.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

public protocol Race {
    associatedtype CompetitorType: Competitor

    /// What an entry is identified by. Defaults to the competitor, since one
    /// competitor per entry is the ordinary case.
    associatedtype EntryID: Hashable = CompetitorType

    var results: [CompetitorType: RaceResult] { get }

    /// The entry a competitor raced in.
    ///
    /// An entry is the thing that races; a competitor is the thing that gets
    /// scored. Usually they are the same thing and you need not implement this.
    ///
    /// They come apart when several competitors share one entry — scoring each
    /// sailor aboard a boat individually, say, which puts one result per sailor
    /// in `results`, all of them holding their boat's finishing place. Say so
    /// here and the scorer can tell that from two boats genuinely tied at that
    /// place: crew sail together and score their boat's points, while tied
    /// entries share the points for their places under RRS A7. Without it a
    /// crew reads as a tie, and the more of them aboard the worse they score.
    func entry(for competitor: CompetitorType) -> EntryID

    /// The number of entries that competed in this race — the *N* of RRS A4,
    /// A9 and the high point percentage system.
    ///
    /// The default counts the distinct entries that did not score DNC, so it
    /// follows `entry(for:)` and counts boats rather than heads. Override it
    /// when the fleet is not the entries in `results` — when some of the boats
    /// on the course are scored elsewhere, say.
    var competitorsInStartingArea: Int { get }
}

public extension Race where EntryID == CompetitorType {
    func entry(for competitor: CompetitorType) -> CompetitorType {
        return competitor
    }
}

public extension Race {
    var competitorsInStartingArea: Int {
        return Set(results.filter({ $0.value != .dnc }).map({ entry(for: $0.key) })).count
    }
}
