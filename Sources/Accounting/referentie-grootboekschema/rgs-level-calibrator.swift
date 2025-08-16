import Foundation

public struct RGSLevelCalibrator: Sendable {
    public struct Key: Hashable, Sendable {
        public let len: Int          // 4 or 5
        public let tz: Int           // trailing zeros
        public let hundredsIsZero: Bool
        public let lastTwo: String   // e.g. "10","50","00","01"
    }

    public private(set) var table: [Key: Int] = [:]

    public init(accounts: [RGSAccount]) {
        var counts: [Key: [Int: Int]] = [:]
        for a in accounts {
            let s = a.code.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty, s.allSatisfy(\.isNumber) else { continue }
            let len = s.count
            guard len == 4 || len == 5 else { continue }

            let tz = s.reversed().prefix(while: { $0 == "0" }).count
            let lastTwo = String(s.suffix(2))
            let idxHundreds = s.index(s.endIndex, offsetBy: -3)
            let hundredsIsZero = s[idxHundreds] == "0"

            let k = Key(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: lastTwo)
            var bucket = counts[k] ?? [:]
            bucket[a.level, default: 0] += 1
            counts[k] = bucket
        }

        var t: [Key: Int] = [:]
        for (k, freq) in counts {
            if let (lvl, _) = freq.max(by: { $0.value < $1.value }) {
                t[k] = min(4, max(2, lvl)) // clamp while recording
            }
        }
        self.table = t
    }

    /// Static fallback (your current best rule).
    @inline(__always)
    private func fallbackLevel(for code: String) throws -> Int {
        let s = code
        let tz = s.reversed().prefix(while: { $0 == "0" }).count
        switch s.count {
        case 5:
            let base = 5 - tz
            let L = (tz <= 1) ? (base - 1) : base
            return max(2, L)
        case 4:
            let base = 4 - tz
            return base + 1
        default:
            throw RGSParsingError.invalidCodeStringLength(code)
        }
    }

    @inline(__always)
    private func pairedFallback(_ s: String) throws -> Int {
        let tz = s.reversed().prefix(while: { $0 == "0" }).count
        switch s.count {
        case 5:
            // Pair last two digits:
            // tz:4→2, tz:3→3, tz:2→3, tz:1→4, tz:0→4
            let map = [4: 2, 3: 3, 2: 3, 1: 4, 0: 4]
            return map[tz].map { min(4, max(2, $0)) } ?? 4
        case 4:
            // Classic:
            // tz:3→2, tz:2→3, tz:1→4, tz:0→4
            let map = [3: 2, 2: 3, 1: 4, 0: 4]
            return map[tz].map { min(4, max(2, $0)) } ?? 4
        default:
            throw RGSParsingError.invalidCodeStringLength(s)
        }
    }

    public func inferLevel(from code: String) throws -> Int {
        let s = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, s.allSatisfy(\.isNumber) else {
            throw RGSParsingError.cannotConvertCodeToInteger(code)
        }
        let len = s.count
        guard len == 4 || len == 5 else {
            throw RGSParsingError.invalidCodeStringLength(code)
        }

        let tz = s.reversed().prefix(while: { $0 == "0" }).count
        let lastTwo = String(s.suffix(2))
        let idxHundreds = s.index(s.endIndex, offsetBy: -3)
        let hundredsIsZero = s[idxHundreds] == "0"
        let k = Key(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: lastTwo)

        // Progressive relaxation: exact → ignore lastTwo
        let keys = [
            k,
            Key(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: "__"),
        ]

        // Start from the *correct* paired fallback
        var result = try pairedFallback(s)

        // If we have calibration, apply it (can raise or lower), then clamp.
        for kk in keys {
            if let v = table[kk] {
                result = v
                break
            }
        }
        return min(4, max(2, result))
    }
}
