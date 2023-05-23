//
//  ResultStatus.swift
//  
//
//  Created by Stuart A. Malone on 5/23/23.
//

import Foundation

/// A ResultStatus gives a quick indication of discrepancies in the scores for a race.
/// It highlights ties, and marks any blatently incorrect results as errors.
public enum ResultStatus {
    case ok
    case tied
    case error
}
