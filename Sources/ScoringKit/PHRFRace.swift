//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 5/31/23.
//

import Foundation

protocol PHRFRace {
    associatedtype CompetitorType: PHRFCompetitor
    
    var startTime: Date { get }
    var results: [CompetitorType: PHRFResult] { get }
    
    /// The average PHRF rating of the competitors for scoring purposes.
    /// Note that depending on the local scoring system, this may not be the same
    /// as the average PHRF rating of the competitors in this particular race.
    var averageRating: PHRFRating { get }
    
    /// An additional factor based on wind conditions that is added to the competitor's rating (and the averageRating)
    /// when computing the time correction factor for a finish.
    var conditionsFactor: PHRFRating { get }
}
