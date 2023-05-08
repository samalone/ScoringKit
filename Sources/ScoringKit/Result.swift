import Foundation

public enum Result: Equatable {
    case racing         // Still racing
    case finished(Int)  // Completed the race normally
    
    case dnc    // Did not start; did not come to the starting area
    case dns    // Did not start (other than DNC and OCS)
    case ocs    // Did not start; on the course side of the starting line and broke rule 29.1 or 30.1
    case bfd    // Disqualification under rule 30.3 (Blank Flag Disqualification)
    case scp    // Took a scoring penalty under rule 44.3
    case dnf    // Did not finish
    case raf    // Retired after finishing
    case dsq    // Disqualification
    case dne    // Disqualification not excludable under rule 88.3(b)
    case rdg    // Redress given
    case zfp    // 20% penalty under rule 30.2
    
    public static let allSpecial: [Result] = [
        .dnc, .dnf, .dns,
        .ocs, .bfd, .scp,
        .raf, .dsq, .dne,
        .rdg, .zfp
    ]
    
    /// Is the score excludable in a series that allows throw-outs?
    ///
    /// **90.3 (b)** When a scoring system provides for excluding one or more race scores from a boat’s series score, the score for disqualification under rule 2; rule 30.3’s last sentence; rule 42 if rule P2.2 or P2.3 applies; or rule 69.2(c)(2) shall not be excluded. The next-worse score shall be excluded instead.
    var isExcludable: Bool {
        return self != .dne
    }
}
