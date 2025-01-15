import Foundation

public enum RaceResult: Codable, Equatable, Sendable, Hashable {
    case racing         // Still racing
    case finished(position: Int)  // Completed the race normally
    
    case dnc    // Did not start; did not come to the starting area
    case dns    // Did not start (other than DNC and OCS)
    case ocs    // Did not start; on the course side of the starting line and broke rule 29.1 or 30.1
    case bfd    // Disqualification under rule 30.3 (Blank Flag Disqualification)
    case scp    // Took a scoring penalty under rule 44.3
    case dnf    // Did not finish
    case raf    // Retired after finishing
    case dsq    // Disqualification
    case dne    // Disqualification not excludable under rule 88.3(b)
    case dgm    // Disqualification under rule 69.1(b)(2); not excludable
    case rdg    // Redress given
    case zfp    // 20% penalty under rule 30.2
    
    public init?(_ value: String) {
        switch value.uppercased() {
        case "": self = .racing
        case "DNC": self = .dnc
        case "DNS": self = .dns
        case "OCS": self = .ocs
        case "BFD": self = .bfd
        case "SCP": self = .scp
        case "DNF": self = .dnf
        case "RAF": self = .raf
        case "DSQ": self = .dsq
        case "DNE": self = .dne
        case "DGM": self = .dgm
        case "RDG": self = .rdg
        case "ZFP": self = .zfp
        default:
            if let position = Int(value) {
                self = .finished(position: position)
            }
            else {
                return nil
            }
        }
    }
    
    public static let allSpecial: [RaceResult] = [
        .dnc, .dnf, .dns,
        .ocs, .bfd, .scp,
        .raf, .dsq, .dne,
        .rdg, .zfp
    ]
    
    /// Is the score excludable in a series that allows throw-outs?
    ///
    /// **90.3 (b)** When a scoring system provides for excluding one or more race scores from a boat’s series score, the score for disqualification under rule 2; rule 30.3’s last sentence; rule 42 if rule P2.2 or P2.3 applies; or rule 69.2(c)(2) shall not be excluded. The next-worse score shall be excluded instead.
    var isExcludable: Bool {
        switch self {
        case .dne, .bfd, .dgm:
            return false
        default:
            return true
        }
    }
}

extension RaceResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .racing:
            return ""
        case .finished(let position):
            return position.description
        case .dnc:
            return "DNC"
        case .dns:
            return "DNS"
        case .ocs:
            return "OCS"
        case .bfd:
            return "BFD"
        case .scp:
            return "SCP"
        case .dnf:
            return "DNF"
        case .raf:
            return "RAF"
        case .dsq:
            return "DSQ"
        case .dne:
            return "DNE"
        case .dgm:
            return "DGM"
        case .rdg:
            return "RDG"
        case .zfp:
            return "ZFP"
        }
    }
}

extension RaceResult: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = RaceResult(value) ?? .racing
    }
}

extension RaceResult: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .finished(position: value)
    }
}
