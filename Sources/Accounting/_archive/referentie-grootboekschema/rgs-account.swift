import Foundation

public enum RGSParsingError: Error, CustomStringConvertible {
    case invalidLevel(String)
    case invalidDirection(String)
    case cannotConvertCodeToInteger(String)
    case invalidCodeStringLength(String)

    public var description: String {
        switch self {
        case .invalidLevel(let str):
            return "Couldn’t parse level from ‘\(str)’"
        case .invalidDirection(let dc):
            return "Couldn’t parse direction from ‘\(dc)’"
        case .cannotConvertCodeToInteger(let code):
            return "Cannot convert the code string to an integer ‘\(code)’"
        case .invalidCodeStringLength(let code):
            return "Cannot convert this code into an account range ‘\(code)’, with length: \(code.count)"
        }
    }
}

public enum RGSAccountRange: Codable, Sendable {
    case thousands
    case tenThousands
}

public struct RGSAccount: Codable, Sendable {
    public let code: String
    public let label: String
    public let level: Int
    public let direction: Direction
    public let identifiers: RGSIdentifiers
    public let applicability: Applicability

    public init(
        code: String,
        label: String,
        level: Int,
        direction: Direction,
        identifiers: RGSIdentifiers,
        applicability: Applicability
    ) {
        self.code = code
        self.label = label
        self.level = level
        self.direction = direction
        self.identifiers = identifiers
        self.applicability = applicability
    }

    public var parentCode: String? {
        let trimmed = code.reversed().drop(while: { $0 == "0" })
        guard trimmed.count > 2 else { return nil }
        let nonZeroPart = String(trimmed).reversed()
        let prefixLen = nonZeroPart.count - 1
        let prefix = nonZeroPart.prefix(prefixLen)
        let zeros = String(repeating: "0", count: code.count - prefixLen)
        return String(prefix) + zeros
    }

    public init(raw: RGSRawPDFTableObject) throws {
        self.code = raw.RekNr
        self.label = raw.Omschrijving

        guard let lvl = Int(raw.Nivo) else {
            throw RGSParsingError.invalidLevel(raw.Nivo)
        }
        self.level = lvl

        self.direction = try Direction(raw: raw.DC)

        let oms = raw.Omslag.isEmpty ? nil : raw.Omslag
        self.identifiers = RGSIdentifiers(rgs: raw.RGSCode, omslag: oms)

        self.applicability = Applicability(
            zzp:     raw.ZZP,
            ez:      raw.EZ,
            bv:      raw.BV,
            svc:     raw.SVC,
            branche: raw.Bra
        )
    }

    public func writeAsEC() -> String {
        let identifiersBlock: String
        if let omslag = identifiers.omslag {
            identifiersBlock = """
            identifiers {
                rgs = \(identifiers.rgs)
                omslag = \(omslag)
            }
            """

        } else {
            identifiersBlock = """
            identifiers {
                rgs = \(identifiers.rgs)
            }
            """
        }

        return """
        account {
            use code \(code)

            label {
                \(label)
            }

            direction = \(direction)

            level = \(level)

            applicability {
                branche = \(applicability.branche)
                bv = \(applicability.bv)
                ez = \(applicability.ez)
                svc = \(applicability.svc)
                zzp = \(applicability.zzp)
            }

        \(identifiersBlock.indent())
        }
            
        """
    }

    public func codeInteger() throws -> Int {
        guard let integer = Int(code) else {
            throw RGSParsingError.cannotConvertCodeToInteger(code)
        }

        return integer
    }
}

// extension Array: Sendable where Element == RGSAccount {} 
// deprecation in swift-tools 6.2?

extension Array where Element == RGSAccount {
    public func ec() -> String {
        var string = ""
        for i in self {
            string.append(i.writeAsEC())
        }
        return string
    }

    public func validateInferredLevels() {
        var matches: [(code: String, provided: Int, inferred: Int)] = []
        var mismatches: [(code: String, provided: Int, inferred: Int)] = []

        let calibrator = RGSLevelCalibrator(accounts: self)

        for a in self {
            do {
                // let inferred = try a.inferLevelFromCodeString()
                let inferred = try calibrator.inferLevel(from: a.code)
                if inferred != a.level {
                    mismatches.append((a.code, a.level, inferred))
                } else {
                    matches.append((a.code, a.level, inferred))
                }
            } catch {
                fputs("skip \(a.code): \(error)\n", stderr)
            }
        }

        if mismatches.isEmpty {
            print("OK: inferred levels match for \(self.count) accounts.")
        } else {
            print("MATCHES (\(matches.count)):".ansi(.green))

            for m in matches.sorted(by: { $0.code < $1.code }).prefix(100) {
                print("  \(m.code): provided=\(m.provided) inferred=\(m.inferred)")
            }
            if matches.count > 100 {
                print("  … +\(matches.count - 100) more")
            }

            print("MISMATCHES (\(mismatches.count)):".ansi(.red))
            for m in mismatches.sorted(by: { $0.code < $1.code }).prefix(100) {
                print("  \(m.code): provided=\(m.provided) inferred=\(m.inferred)")
            }
            if mismatches.count > 100 {
                print("  … +\(mismatches.count - 100) more")
            }
        }
    }
}

public struct RGSIdentifiers: Codable, Sendable {
    public let rgs: String           // the RGS-code column
    public let omslag: String?       // the Omslagcode column, to flip appearance account based on dr-cr balance

    public init(
        rgs: String,
        omslag: String?
    ) {
        self.rgs = rgs
        self.omslag = omslag
    }
}

public struct Applicability: Codable, Sendable {
    public let zzp: String
    public let ez: String
    public let bv: String
    public let svc: String
    public let branche: String

    public init(
        zzp: String,
        ez: String,
        bv: String,
        svc: String,
        branche: String
    ) {
        self.zzp = zzp
        self.ez = ez
        self.bv = bv
        self.svc = svc
        self.branche = branche
    }
}
