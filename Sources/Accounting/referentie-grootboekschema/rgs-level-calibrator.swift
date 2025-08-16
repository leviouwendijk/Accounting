import Foundation

public struct RGSLevelCalibrator: Sendable {
    public struct Key: Hashable, Sendable {
        public let len: Int              // 4 or 5
        public let tz: Int               // trailing zeros
        public let hundredsIsZero: Bool
        public let lastTwo: String       // "00","10","50","70","01",…
        public let prefix2: Int          // first two digits as Int, e.g. 13, 70, 82
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

            let p2 = Int(s.prefix(2)) ?? -1

            let k = Key(len: len,
                        tz: tz,
                        hundredsIsZero: hundredsIsZero,
                        lastTwo: lastTwo,
                        prefix2: p2)

            var bucket = counts[k] ?? [:]
            bucket[a.level, default: 0] += 1
            counts[k] = bucket
        }

        var t: [Key: Int] = [:]
        for (k, freq) in counts {
            if let (lvl, _) = freq.max(by: { $0.value < $1.value }) {
                t[k] = lvl
            }
        }
        self.table = t
    }

    @inline(__always)
    private func staticFallback(_ s: String) throws -> Int {
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
        let p2 = Int(s.prefix(2)) ?? -1

        // Lookup with progressive relaxation
        let keys: [Key] = [
            .init(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: lastTwo, prefix2: p2),
            .init(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: lastTwo, prefix2: -1),
            .init(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: "__",   prefix2: p2),
            .init(len: len, tz: tz, hundredsIsZero: hundredsIsZero, lastTwo: "__",   prefix2: -1),
        ]

        var calibrated: Int? = nil
        for k in keys {
            if let v = table[k] { calibrated = v; break }
        }

        let fallback = try staticFallback(s)

        // Bias: never downgrade below fallback (fixes 14000-type cases).
        if let cal = calibrated {
            return max(fallback, cal)
        } else {
            return fallback
        }
    }
}
