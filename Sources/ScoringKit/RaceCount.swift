//
//  RaceCount.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/31/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public enum RacesToQualify: Codable, Sendable, Hashable {
    /// Everyone is qualified regardless of races sailed
    case none
    
    /// Must sail all races to qualify
    case all
    
    /// Must sail at least a fixed number of races
    case fixed(n: Int)

    case roundUp(percent: Int)
    case roundDown(percent: Int)
    case roundNearest(percent: Int)
        
    public func calculate(numberOfRaces: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .all:
            return numberOfRaces
        case .fixed(let n):
            return min(n, numberOfRaces)
        case .roundUp(let percent):
            return Int(ceil(Double(numberOfRaces) * Double(percent) / 100.0))
        case .roundDown(let percent):
            return Int(floor(Double(numberOfRaces) * Double(percent) / 100.0))
        case .roundNearest(let percent):
            return Int(round(Double(numberOfRaces) * Double(percent) / 100.0))
        }
    }
    
    public var name: String {
        switch self {
        case .none:
            return "None"
        case .all:
            return "All"
        case .fixed:
            return "Fixed"
        case .roundUp:
            return "Round up"
        case .roundDown:
            return "Round down"
        case .roundNearest:
            return "Round to nearest"
        }
    }
    
    // Return an appropriate range for the argument.
    // Useful when displaying a UI.
    public var appropriateRange: ClosedRange<Int>? {
        switch self {
        case .none, .all:
            return nil
        case .fixed:
            return 1...20
        case .roundUp, .roundDown, .roundNearest:
            return 1...99
        }
    }
    
    // Return a string indicating the units of the argument.
    // Useful when displaying a UI.
    public var units: String {
        switch self {
        case .none, .all:
            return ""
        case .fixed:
            return ""
        case .roundUp, .roundDown, .roundNearest:
            return "%"
        }
    }
}

public enum RacesToExclude: Codable, Sendable, Hashable {
    case none
    case upTo(n: Int)
    case roundUp(percent: Int)
    case roundDown(percent: Int)
    case roundNearest(percent: Int)
    case notNeededToQualify
    
    public func calculate(numberOfRaces: Int, neededToQualify: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .upTo(let n):
            return min(n, numberOfRaces - 1)
        case .roundUp(let percent):
            return Int(ceil(Double(numberOfRaces) * Double(percent) / 100.0))
        case .roundDown(let percent):
            return Int(floor(Double(numberOfRaces) * Double(percent) / 100.0))
        case .roundNearest(let percent):
            return Int(round(Double(numberOfRaces) * Double(percent) / 100.0))
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
        case .roundUp:
            return "Round up"
        case .roundDown:
            return "Round down"
        case .roundNearest:
            return "Round to nearest"
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
            return 1...10
        case .roundUp, .roundDown, .roundNearest:
            return 1...99
        }
    }
    
    // Return a string indicating the units of the argument.
    // Useful when displaying a UI.
    public var units: String {
        switch self {
        case .none, .notNeededToQualify:
            return ""
        case .upTo:
            return ""
        case .roundUp, .roundDown, .roundNearest:
            return "%"
        }
    }
}
