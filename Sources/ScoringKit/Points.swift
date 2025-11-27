//
//  Points.swift
//  
//
//  Created by Stuart A. Malone on 5/7/23.
//

import Foundation

/// "Points" are an abstract measurement of a competitor's standing in a regatta.
/// Although all scoring systems use the same structure to store Points, the interpretation
/// and manipulation of Points depends on the scoring system.
///
/// Note that we intentionally do no make Points Equatable or Comparable, because
/// the meaning of equality and comparison depends on the scoring system.
public struct Points {
    public var numerator: Int
    public var denominator: Int
    
    init() {
        numerator = 0
        denominator = 0
    }
    
    init(_ n: Int) {
        numerator = n
        denominator = 1
    }
    
    init(numerator: Int, denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }
    
    /// Adds points by accumulating numerators and denominators.
    /// Used by highPointPercentage to calculate (total earned / total possible).
    static func +(lhs: Points, rhs: Points) -> Points {
        return Points(numerator: lhs.numerator + rhs.numerator,
                      denominator: lhs.denominator + rhs.denominator)
    }
    
    static func += (lhs: inout Points, rhs: Points) {
        lhs.numerator += rhs.numerator
        lhs.denominator += rhs.denominator
    }
    
    /// Adds points as proper fractions: a/b + c/d = (ad + bc) / bd
    /// Used by lowPoint/bonusPoint when A7 tie splitting creates fractional scores.
    func addingFraction(_ other: Points) -> Points {
        // Handle zero denominators (empty points)
        if self.denominator == 0 {
            return other
        }
        if other.denominator == 0 {
            return self
        }
        
        // Same denominator: a/n + b/n = (a+b)/n
        if self.denominator == other.denominator {
            return Points(numerator: self.numerator + other.numerator,
                          denominator: self.denominator)
        }
        
        // Different denominators: a/b + c/d = (ad + bc) / bd
        return Points(numerator: self.numerator * other.denominator + other.numerator * self.denominator,
                      denominator: self.denominator * other.denominator)
    }
}
