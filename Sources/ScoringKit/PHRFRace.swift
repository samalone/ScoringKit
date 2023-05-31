//
//  File.swift
//  
//
//  Created by Stuart A. Malone on 5/31/23.
//

import Foundation

public typealias PHRFResult = RaceResult<Date>

public protocol PHRFRace {
    associatedtype CompetitorType: PHRFCompetitor
    
    var startTime: Date { get }
    
    /// The average PHRF rating of the competitors for scoring purposes.
    /// Note that depending on the local scoring system, this may not be the same
    /// as the average PHRF rating of the competitors in this particular race.
    var averageRating: PHRFRating { get }
    
    /// An additional factor based on wind conditions that is added to the competitor's rating (and the averageRating)
    /// when computing the time correction factor for a finish.
    var conditionsFactor: PHRFRating { get }
    
    var results: [CompetitorType: PHRFResult] { get }
}

public extension PHRFRace {
    func elapsedTime(of competitor: CompetitorType) -> TimeInterval? {
        guard let result = results[competitor] else { return nil }
        guard case .finished(let finishTime) = result else { return nil }
        return finishTime.timeIntervalSince(startTime)
    }
    
    func correctedTime(of competitor: CompetitorType) -> TimeInterval? {
        guard let elapsedTime = elapsedTime(of: competitor) else { return nil }
        return elapsedTime * Double(averageRating + conditionsFactor) / Double(competitor.rating + conditionsFactor)
    }
}

struct PHRFRaceAdapter<PHRFRaceType: PHRFRace>: Race {
    typealias CompetitorType = PHRFRaceType.CompetitorType
    
    var results: [PHRFRaceType.CompetitorType : RaceResult<Int>] = [:]
    
    class CorrectedTime {
        let competitor: CompetitorType
        let time: TimeInterval
        var position: Int = 0
        
        init(competitor: CompetitorType, time: TimeInterval) {
            self.competitor = competitor
            self.time = time
        }
    }
    
    init(phrf: PHRFRaceType) {
        var correctedTimes: [CorrectedTime] = []
        for result in phrf.results {
            if let ct = phrf.correctedTime(of: result.key) {
                correctedTimes.append(CorrectedTime(competitor: result.key, time: ct))
            }
        }
        correctedTimes.sort { $0.time < $1.time }
        var prevTime: CorrectedTime? = nil
        for (index, thisTime) in correctedTimes.enumerated() {
            if let prevTime, prevTime.time == thisTime.time {
                thisTime.position = prevTime.position
            }
            else {
                thisTime.position = index + 1
                prevTime = thisTime
            }
        }
        
        for result in phrf.results {
            let newResult: RaceResult<Int>
            switch result.value {
            case .racing:
                newResult = .racing
            case .finished:
                newResult = .finished(position: correctedTimes.first(where: {$0.competitor == result.key})!.position)
            case .dnc:
                newResult = .dnc
            case .dns:
                newResult = .dns
            case .ocs:
                newResult = .ocs
            case .bfd:
                newResult = .bfd
            case .scp:
                newResult = .scp
            case .dnf:
                newResult = .dnf
            case .raf:
                newResult = .raf
            case .dsq:
                newResult = .dsq
            case .dne:
                newResult = .dne
            case .dgm:
                newResult = .dgm
            case .rdg:
                newResult = .rdg
            case .zfp:
                newResult = .zfp
            }
            results[result.key] = newResult
        }
    }
}
