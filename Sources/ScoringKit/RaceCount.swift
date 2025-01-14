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
    /// Must sail at least a fixed number of races
    case fixed(n: Int)
    
    case percent(n: Int, rounded: RoundingDirection)
    
    public static let all = RacesToQualify.percent(n: 100, rounded: .nearest)
    public static let none = RacesToQualify.fixed(n: 0)
        
    public func calculate(numberOfRaces: Int) -> Int {
        switch self {
        case .percent(let n, let rounded):
            return Int((Double(numberOfRaces) * Double(n) / 100.0).rounded(rounded.roundingRule))
        case .fixed(let n):
            return min(n, numberOfRaces)
        }
    }
    
    public var name: String {
        switch self {
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
        case .fixed:
            return ""
        case .percent:
            return "%"
        }
    }
}

public enum RacesToExclude: Codable, Sendable, Hashable {
    case upTo(n: Int)
    case percent(n: Int, rounded: RoundingDirection)
    case notNeededToQualify
    
    public static let none = RacesToExclude.upTo(n: 0)
    
    public func calculate(numberOfRaces: Int, neededToQualify: Int) -> Int {
        switch self {
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
        case .notNeededToQualify:
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
        case .notNeededToQualify, .upTo:
            return ""
        case .percent:
            return "%"
        }
    }
}
