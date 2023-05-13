//
//  RaceLimit.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/31/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public enum RaceLimit {
    case none
    case upTo(Int)
    case abovePercent(Int)
    case belowPercent(Int)
    
    public static func fromRawValues(_ rawValue: Int, limit: Int) -> RaceLimit {
        switch rawValue {
        case 0:
            return .none
        case 1:
            return .upTo(limit)
        case 2:
            return .abovePercent(limit)
        case 3:
            return .belowPercent(limit)
        default:
            fatalError()
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .none:
            return 0
        case .upTo:
            return 1
        case .abovePercent:
            return 2
        case .belowPercent:
            return 3
        }
    }
    
    public var limit: Int {
        switch self {
        case .none:
            return 0
        case .upTo(let x):
            return x
        case .abovePercent(let x):
            return x
        case .belowPercent(let x):
            return x
        }
    }
    
    public func calculate(_ numberOfRaces: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .upTo(let x):
            return min(x, numberOfRaces - 1)
        case .abovePercent(let x):
            return Int(ceil(Double(numberOfRaces) * Double(x) / 100.0))
        case .belowPercent(let x):
            return Int(floor(Double(numberOfRaces) * Double(x) / 100.0))
        }
    }
}
