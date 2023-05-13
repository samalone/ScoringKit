//
//  Points.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

/// "Points" are an abstract measurement of a competitor's standing in a regatta.
/// Several different point systems are available, but all adhere to this protocol.
public protocol Points: Comparable, CustomStringConvertible, CustomDebugStringConvertible {
    static var systemName: String { get }
    
    init()
    init(result: RaceResult?,
         isLongSeries: Bool,
         competitorsInStartingArea: Int,
         competitorsInSeries: Int)
    
    static func +(lhs: Self, rhs: Self) -> Self
    
    static func +=(lhs: inout Self, rhs: Self)
}
