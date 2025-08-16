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
        // Build frequency counts of provided levels per key
        var counts: [Key: [Int: Int]] = [:]  // Key -> (level -> freq)
        for a in accounts {
            let s = a.code.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty, s.allSatisfy(\.isNumber) else { continue }
            let tz = s.reversed().prefix(while: { $0 == "0" }).count
            let len = s.count
            guard len == 4 || len == 5 else { continue }
            let lastTwo = s.suffix(2)
            let idxHundreds = s.index(s.endIndex, offsetBy: -3)
            let hundredsIsZero = s[idxHundreds] == "0"

            let k = Key(len: len,
                        tz: tz,
                        hundredsIsZero: hundredsIsZero,
                        lastTwo: String(lastTwo))
            var bucket = counts[k] ?? [:]
            bucket[a.level, default: 0] += 1
            counts[k] = bucket
        }

        // Majority vote → canonical level
        var t: [Key: Int] = [:]
        for (k, freq) in counts {
            if let (lvl, _) = freq.max(by: { $0.value < $1.value }) {
                t[k] = lvl
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
        if let lvl = table[k] { return lvl }
        // Try a looser key (ignore lastTwo) if exact not found
        let loose = Key(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: "__")
        if let lvl = table[loose] { return lvl }

        return try fallbackLevel(for: s)
    }
}
