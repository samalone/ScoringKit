import Foundation
import Testing
@testable import ScoringKit

@Suite("RaceResult Tests")
struct RaceResultTests {
    
    @Suite("String Initializer")
    struct StringInitializerTests {
        @Test func finished() throws {
            #expect(try RaceResult("1") == .finished(position: 1))
            #expect(try RaceResult("42") == .finished(position: 42))
            #expect(try RaceResult("999") == .finished(position: 999))
        }
        
        @Test func specialCases() throws {
            #expect(try RaceResult("DNC") == .dnc)
            #expect(try RaceResult("DNS") == .dns)
            #expect(try RaceResult("OCS") == .ocs)
            #expect(try RaceResult("BFD") == .bfd)
            #expect(try RaceResult("SCP") == .scp)
            #expect(try RaceResult("DNF") == .dnf)
            #expect(try RaceResult("RAF") == .raf)
            #expect(try RaceResult("DSQ") == .dsq)
            #expect(try RaceResult("DNE") == .dne)
            #expect(try RaceResult("DGM") == .dgm)
            #expect(try RaceResult("RDG") == .rdg)
            #expect(try RaceResult("ZFP") == .zfp)
            #expect(try RaceResult("") == .racing)
        }
        
        @Test func caseInsensitive() throws {
            #expect(try RaceResult("dnc") == .dnc)
            #expect(try RaceResult("Dnc") == .dnc)
            #expect(try RaceResult("dNc") == .dnc)
            #expect(try RaceResult("dnf") == .dnf)
            #expect(try RaceResult("dsq") == .dsq)
        }
        
        @Test func invalid() {
            // Use an array to avoid string literal initializer
            let invalidStrings = ["INVALID", "XYZ", "abc123"]
            for invalidString in invalidStrings {
                do {
                    _ = try RaceResult(invalidString)
                    Issue.record("\(invalidString) should throw an error")
                } catch {
                    // Expected to throw
                }
            }
        }
    }
    
    @Suite("Properties")
    struct PropertiesTests {
        @Test func allSpecial() {
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
    }
    
    @Suite("CustomStringConvertible")
    struct DescriptionTests {
        @Test func finished() {
            #expect(RaceResult.finished(position: 1).description == "1")
            #expect(RaceResult.finished(position: 42).description == "42")
            #expect(RaceResult.finished(position: 999).description == "999")
        }
        
        @Test func specialCases() {
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
    }
    
    @Suite("ExpressibleByStringLiteral")
    struct StringLiteralTests {
        @Test func initializer() {
            let result1: RaceResult = "DNC"
            #expect(result1 == .dnc)
            
            let result2: RaceResult = "1"
            #expect(result2 == .finished(position: 1))
            
            let result3: RaceResult = ""
            #expect(result3 == .racing)
        }
    }
    
    @Suite("ExpressibleByIntegerLiteral")
    struct IntegerLiteralTests {
        @Test func initializer() {
            let result1: RaceResult = 1
            #expect(result1 == .finished(position: 1))
            
            let result2: RaceResult = 42
            #expect(result2 == .finished(position: 42))
            
            let result3: RaceResult = 999
            #expect(result3 == .finished(position: 999))
        }
    }
    
    @Suite("Comparable")
    struct ComparableTests {
        @Test func finishedPositions() {
            #expect(RaceResult.finished(position: 1) < RaceResult.finished(position: 2))
            #expect(RaceResult.finished(position: 2) < RaceResult.finished(position: 10))
            #expect(RaceResult.finished(position: 5) < RaceResult.finished(position: 6))
            #expect(!(RaceResult.finished(position: 2) < RaceResult.finished(position: 1)))
            #expect(!(RaceResult.finished(position: 1) < RaceResult.finished(position: 1)))
        }
        
        @Test func specialCases() {
            #expect(RaceResult.finished(position: 1) < RaceResult.dnc)
            #expect(RaceResult.finished(position: 1) < RaceResult.dnf)
            #expect(RaceResult.finished(position: 1) < RaceResult.racing)
            #expect(RaceResult.dnc < RaceResult.dns)
            #expect(RaceResult.dns < RaceResult.ocs)
            #expect(RaceResult.ocs < RaceResult.bfd)
            #expect(RaceResult.bfd < RaceResult.scp)
            #expect(RaceResult.scp < RaceResult.dnf)
            #expect(RaceResult.dnf < RaceResult.raf)
            #expect(RaceResult.raf < RaceResult.dsq)
            #expect(RaceResult.dsq < RaceResult.dne)
            #expect(RaceResult.dne < RaceResult.dgm)
            #expect(RaceResult.dgm < RaceResult.rdg)
            #expect(RaceResult.rdg < RaceResult.zfp)
            #expect(RaceResult.zfp < RaceResult.racing)
        }
        
        @Test func sorting() {
            let results: [RaceResult] = [
                .racing, .zfp, .rdg, .dgm, .dne, .dsq, .raf, .dnf, .scp, .bfd, .ocs, .dns, .dnc,
                .finished(position: 3), .finished(position: 1), .finished(position: 2)
            ]
            
            let sorted = results.sorted()
            
            #expect(sorted[0] == .finished(position: 1))
            #expect(sorted[1] == .finished(position: 2))
            #expect(sorted[2] == .finished(position: 3))
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
    }
    
    @Suite("Codable")
    struct CodableTests {
        @Test func encodeDecode() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            let testCases: [RaceResult] = [
                .finished(position: 1), .finished(position: 42),
                .dnc, .dns, .ocs, .bfd, .scp, .dnf, .raf, .dsq, .dne, .dgm, .rdg, .zfp, .racing
            ]
            
            for result in testCases {
                let encoded = try encoder.encode(result)
                let decoded = try decoder.decode(RaceResult.self, from: encoded)
                #expect(decoded == result)
            }
        }
    }
    
    @Suite("Equatable")
    struct EquatableTests {
        @Test func finished() {
            #expect(RaceResult.finished(position: 1) == RaceResult.finished(position: 1))
            #expect(RaceResult.finished(position: 1) != RaceResult.finished(position: 2))
        }
        
        @Test func specialCases() {
            #expect(RaceResult.dnc == RaceResult.dnc)
            #expect(RaceResult.dnf == RaceResult.dnf)
            #expect(RaceResult.dnc != RaceResult.dnf)
            #expect(RaceResult.racing == RaceResult.racing)
        }
    }
    
    @Suite("Hashable")
    struct HashableTests {
        @Test func sets() {
            let set1: Set<RaceResult> = [.finished(position: 1), .dnc, .dnf]
            let set2: Set<RaceResult> = [.finished(position: 1), .dnc, .dnf]
            #expect(set1 == set2)
            
            let set3: Set<RaceResult> = [.finished(position: 2), .dnc, .dnf]
            #expect(set1 != set3)
            
            let set4: Set<RaceResult> = [.finished(position: 1), .finished(position: 2)]
            #expect(set4.count == 2)
        }
    }
}
