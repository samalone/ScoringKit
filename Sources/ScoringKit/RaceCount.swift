//
//  RaceCount.swift
//  Roundings
//
//  Created by Stuart A. Malone on 12/31/15.
//  Copyright © 2015 Llamagraphics, Inc. All rights reserved.
//

import Foundation

public enum RaceCount: Codable {
    case none
    case all
    case upTo(n: Int)
    case roundUp(percent: Int)
    case roundDown(percent: Int)
        
    public func calculate(_ numberOfRaces: Int) -> Int {
        switch self {
        case .none:
            return 0
        case .all:
            return numberOfRaces
        case .upTo(let n):
            return min(n, numberOfRaces - 1)
        case .roundUp(let percent):
            return Int(ceil(Double(numberOfRaces) * Double(percent) / 100.0))
        case .roundDown(let percent):
            return Int(floor(Double(numberOfRaces) * Double(percent) / 100.0))
        }
    }
}
