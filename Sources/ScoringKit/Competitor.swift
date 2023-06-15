//
//  Competitor.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

/// A Competitor is simply an identifier for someone competing in a race.
/// It could be a skipper or a vessel.
/// It needs to be Hashable so it can be a Dictionary key.
public protocol Competitor: Equatable, Hashable {
}
