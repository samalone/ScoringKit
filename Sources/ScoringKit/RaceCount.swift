//
//  RaceCount.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/31/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public enum RoundingDirection: Codable, Sendable, Hashable, CaseIterable {
    case up
    case down
    case nearest
    
    public var name: String {
        switch self {
        case .up:
            return "Rounded up"
        case .down:
            return "Rounded down"
        case .nearest:
            return "Rounded to nearest"
        }
    }
    
    public var roundingRule: FloatingPointRoundingRule {
        switch self {
        case .up:
            return .up
        case .down:
            return .down
        case .nearest:
            return .toNearestOrAwayFromZero
        }
    }
}

public enum RacesToQualify: Codable, Sendable, Hashable {
    /// Must sail all races
    case all
    
    /// No qualification requirement
    case none
    
    /// Must sail at least a fixed number of races
    case fixed(n: Int)
    
    case percent(n: Int, rounded: RoundingDirection)
        
    public func calculate(numberOfRaces: Int) -> Int {
        switch self {
        case .all:
            return numberOfRaces
        case .none:
            return 0
        case .percent(let n, let rounded):
            return Int((Double(numberOfRaces) * Double(n) / 100.0).rounded(rounded.roundingRule))
        case .fixed(let n):
            return min(n, numberOfRaces)
        }
    }
    
    public var name: String {
        switch self {
        case .all:
            return "All"
        case .none:
            return "None"
        case .percent:
            return "Percent"
        case .fixed:
            return "Fixed"
        }
    }
    
    // Return an appropriate range for the argument.
    // Useful when displaying a UI.
    public var appropriateRange: ClosedRange<Int>? {
        switch self {
        case .all, .none:
            return nil
        case .fixed:
            return 0...20
        case .percent:
            return 0...100
        }
    }
    
    // Return a string indicating the units of the argument.
    // Useful when displaying a UI.
    public var unitSuffix: String {
        switch self {
        case .all, .none, .fixed:
            return ""
        case .percent:
            return "%"
        }
    }
}

public enum RacesToExclude: Codable, Sendable, Hashable {
    case none
    case upTo(n: Int)
    case percent(n: Int, rounded: RoundingDirection)
    case notNeededToQualify
    
    public func calculate(numberOfRaces: Int, neededToQualify: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .upTo(let n):
            return min(n, numberOfRaces - 1)
        case .percent(let percent, let rounded):
            return min(Int((Double(numberOfRaces) * Double(percent) / 100.0).rounded(rounded.roundingRule)),
                       numberOfRaces - 1)
        case .notNeededToQualify:
            return numberOfRaces - neededToQualify
        }
    }
    
    public var name: String {
        switch self {
        case .none:
            return "None"
        case .upTo:
            return "Up to"
        case .percent:
            return "Percent"
        case .notNeededToQualify:
            return "Not needed to qualify"
        }
    }
    
    // Return an appropriate range for the argument.
    // Useful when displaying a UI.
    public var appropriateRange: ClosedRange<Int>? {
        switch self {
        case .none, .notNeededToQualify:
            return nil
        case .upTo:
            return 0...10
        case .percent:
            return 0...99
        }
    }
    
    // Return a string indicating the units of the argument.
    // Useful when displaying a UI.
    public var unitSuffix: String {
        switch self {
        case .none, .notNeededToQualify, .upTo:
            return ""
        case .percent:
            return "%"
        }
    }
}
