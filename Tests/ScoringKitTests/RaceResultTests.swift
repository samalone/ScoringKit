import Foundation
import Testing
@testable import ScoringKit

// MARK: - String Initializer Tests

@Test func stringInitializerFinished() {
    #expect(RaceResult("1") == .finished(position: 1))
    #expect(RaceResult("42") == .finished(position: 42))
    #expect(RaceResult("999") == .finished(position: 999))
}

@Test func stringInitializerSpecialCases() {
    #expect(RaceResult("DNC") == .dnc)
    #expect(RaceResult("DNS") == .dns)
    #expect(RaceResult("OCS") == .ocs)
    #expect(RaceResult("BFD") == .bfd)
    #expect(RaceResult("SCP") == .scp)
    #expect(RaceResult("DNF") == .dnf)
    #expect(RaceResult("RAF") == .raf)
    #expect(RaceResult("DSQ") == .dsq)
    #expect(RaceResult("DNE") == .dne)
    #expect(RaceResult("DGM") == .dgm)
    #expect(RaceResult("RDG") == .rdg)
    #expect(RaceResult("ZFP") == .zfp)
    #expect(RaceResult("") == .racing)
}

@Test func stringInitializerCaseInsensitive() {
    #expect(RaceResult("dnc") == .dnc)
    #expect(RaceResult("Dnc") == .dnc)
    #expect(RaceResult("dNc") == .dnc)
    #expect(RaceResult("dnf") == .dnf)
    #expect(RaceResult("dsq") == .dsq)
}

@Test func stringInitializerInvalid() {
    // Test that invalid strings return nil
    // Use an array to avoid string literal initializer
    let invalidStrings = ["INVALID", "XYZ", "abc123"]
    for invalidString in invalidStrings {
        let result: RaceResult? = RaceResult(invalidString)
        #expect(result == nil, "\(invalidString) should return nil")
    }
}

// MARK: - allSpecial Tests

@Test func allSpecialProperty() {
    let expected: Set<RaceResult> = [
        .dnc, .dnf, .dns,
        .ocs, .bfd, .scp,
        .raf, .dsq, .dne,
        .rdg, .zfp
    ]
    let actual = Set(RaceResult.allSpecial)
    #expect(actual == expected)
    #expect(RaceResult.allSpecial.count == 11)
}

// MARK: - isExcludable Tests

@Test func isExcludableFalse() {
    #expect(!RaceResult.dne.isExcludable)
    #expect(!RaceResult.bfd.isExcludable)
    #expect(!RaceResult.dgm.isExcludable)
}

@Test func isExcludableTrue() {
    #expect(RaceResult.finished(position: 1).isExcludable)
    #expect(RaceResult.dnc.isExcludable)
    #expect(RaceResult.dns.isExcludable)
    #expect(RaceResult.ocs.isExcludable)
    #expect(RaceResult.scp.isExcludable)
    #expect(RaceResult.dnf.isExcludable)
    #expect(RaceResult.raf.isExcludable)
    #expect(RaceResult.dsq.isExcludable)
    #expect(RaceResult.rdg.isExcludable)
    #expect(RaceResult.zfp.isExcludable)
    #expect(RaceResult.racing.isExcludable)
}

// MARK: - CustomStringConvertible Tests

@Test func descriptionFinished() {
    #expect(RaceResult.finished(position: 1).description == "1")
    #expect(RaceResult.finished(position: 42).description == "42")
    #expect(RaceResult.finished(position: 999).description == "999")
}

@Test func descriptionSpecialCases() {
    #expect(RaceResult.dnc.description == "DNC")
    #expect(RaceResult.dns.description == "DNS")
    #expect(RaceResult.ocs.description == "OCS")
    #expect(RaceResult.bfd.description == "BFD")
    #expect(RaceResult.scp.description == "SCP")
    #expect(RaceResult.dnf.description == "DNF")
    #expect(RaceResult.raf.description == "RAF")
    #expect(RaceResult.dsq.description == "DSQ")
    #expect(RaceResult.dne.description == "DNE")
    #expect(RaceResult.dgm.description == "DGM")
    #expect(RaceResult.rdg.description == "RDG")
    #expect(RaceResult.zfp.description == "ZFP")
    #expect(RaceResult.racing.description == "")
}

// MARK: - ExpressibleByStringLiteral Tests

@Test func stringLiteralInitializer() {
    let result1: RaceResult = "DNC"
    #expect(result1 == .dnc)
    
    let result2: RaceResult = "1"
    #expect(result2 == .finished(position: 1))
    
    let result3: RaceResult = ""
    #expect(result3 == .racing)
    
    let result4: RaceResult = "INVALID"
    #expect(result4 == .racing) // Falls back to .racing for invalid strings
}

// MARK: - ExpressibleByIntegerLiteral Tests

@Test func integerLiteralInitializer() {
    let result1: RaceResult = 1
    #expect(result1 == .finished(position: 1))
    
    let result2: RaceResult = 42
    #expect(result2 == .finished(position: 42))
    
    let result3: RaceResult = 999
    #expect(result3 == .finished(position: 999))
}

// MARK: - Comparable Tests

@Test func comparableFinishedPositions() {
    #expect(RaceResult.finished(position: 1) < RaceResult.finished(position: 2))
    #expect(RaceResult.finished(position: 2) < RaceResult.finished(position: 10))
    #expect(RaceResult.finished(position: 5) < RaceResult.finished(position: 6))
    #expect(!(RaceResult.finished(position: 2) < RaceResult.finished(position: 1)))
    #expect(!(RaceResult.finished(position: 1) < RaceResult.finished(position: 1)))
}

@Test func comparableSpecialCases() {
    // Finished should come before all special cases
    #expect(RaceResult.finished(position: 1) < RaceResult.dnc)
    #expect(RaceResult.finished(position: 1) < RaceResult.dnf)
    #expect(RaceResult.finished(position: 1) < RaceResult.racing)
    
    // DNC should come before DNS
    #expect(RaceResult.dnc < RaceResult.dns)
    
    // DNS should come before OCS
    #expect(RaceResult.dns < RaceResult.ocs)
    
    // OCS should come before BFD
    #expect(RaceResult.ocs < RaceResult.bfd)
    
    // BFD should come before SCP
    #expect(RaceResult.bfd < RaceResult.scp)
    
    // SCP should come before DNF
    #expect(RaceResult.scp < RaceResult.dnf)
    
    // DNF should come before RAF
    #expect(RaceResult.dnf < RaceResult.raf)
    
    // RAF should come before DSQ
    #expect(RaceResult.raf < RaceResult.dsq)
    
    // DSQ should come before DNE
    #expect(RaceResult.dsq < RaceResult.dne)
    
    // DNE should come before DGM
    #expect(RaceResult.dne < RaceResult.dgm)
    
    // DGM should come before RDG
    #expect(RaceResult.dgm < RaceResult.rdg)
    
    // RDG should come before ZFP
    #expect(RaceResult.rdg < RaceResult.zfp)
    
    // ZFP should come before racing
    #expect(RaceResult.zfp < RaceResult.racing)
}

@Test func comparableSorting() {
    let results: [RaceResult] = [
        .racing,
        .zfp,
        .rdg,
        .dgm,
        .dne,
        .dsq,
        .raf,
        .dnf,
        .scp,
        .bfd,
        .ocs,
        .dns,
        .dnc,
        .finished(position: 3),
        .finished(position: 1),
        .finished(position: 2)
    ]
    
    let sorted = results.sorted()
    
    // Finished positions should come first, sorted by position
    #expect(sorted[0] == .finished(position: 1))
    #expect(sorted[1] == .finished(position: 2))
    #expect(sorted[2] == .finished(position: 3))
    
    // Then special cases in order
    #expect(sorted[3] == .dnc)
    #expect(sorted[4] == .dns)
    #expect(sorted[5] == .ocs)
    #expect(sorted[6] == .bfd)
    #expect(sorted[7] == .scp)
    #expect(sorted[8] == .dnf)
    #expect(sorted[9] == .raf)
    #expect(sorted[10] == .dsq)
    #expect(sorted[11] == .dne)
    #expect(sorted[12] == .dgm)
    #expect(sorted[13] == .rdg)
    #expect(sorted[14] == .zfp)
    #expect(sorted[15] == .racing)
}

// MARK: - Codable Tests

@Test func raceResultCodable() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let testCases: [RaceResult] = [
        .finished(position: 1),
        .finished(position: 42),
        .dnc,
        .dns,
        .ocs,
        .bfd,
        .scp,
        .dnf,
        .raf,
        .dsq,
        .dne,
        .dgm,
        .rdg,
        .zfp,
        .racing
    ]
    
    for result in testCases {
        let encoded = try encoder.encode(result)
        let decoded = try decoder.decode(RaceResult.self, from: encoded)
        #expect(decoded == result)
    }
}

// MARK: - Equatable Tests

@Test func equatableFinished() {
    #expect(RaceResult.finished(position: 1) == RaceResult.finished(position: 1))
    #expect(RaceResult.finished(position: 1) != RaceResult.finished(position: 2))
}

@Test func equatableSpecialCases() {
    #expect(RaceResult.dnc == RaceResult.dnc)
    #expect(RaceResult.dnf == RaceResult.dnf)
    #expect(RaceResult.dnc != RaceResult.dnf)
    #expect(RaceResult.racing == RaceResult.racing)
}

// MARK: - Hashable Tests

@Test func hashable() {
    let set1: Set<RaceResult> = [.finished(position: 1), .dnc, .dnf]
    let set2: Set<RaceResult> = [.finished(position: 1), .dnc, .dnf]
    #expect(set1 == set2)
    
    // Different values should be different
    let set3: Set<RaceResult> = [.finished(position: 2), .dnc, .dnf]
    #expect(set1 != set3)
    
    // Test that finished positions with different values are different
    let set4: Set<RaceResult> = [.finished(position: 1), .finished(position: 2)]
    #expect(set4.count == 2)
}

