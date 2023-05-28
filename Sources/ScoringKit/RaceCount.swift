//
//  RaceCount.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/31/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public enum RacesToQualify: Codable {
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
}

public enum RacesToExclude: Codable {
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
}
