import Foundation

public enum RGSParsingError: Error, CustomStringConvertible {
    case invalidLevel(String)
    case invalidDirection(String)

    public var description: String {
        switch self {
        case .invalidLevel(let str):
            return "Couldn’t parse level from ‘\(str)’"
        case .invalidDirection(let dc):
            return "Couldn’t parse direction from ‘\(dc)’"
        }
    }
}

public struct RGSAccount: Codable {
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

    public var accountClass: AccountClass {
        // placeholder
        AccountClass.asset
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

        guard let dir = Direction(rawValue: raw.DC) else {
            throw RGSParsingError.invalidDirection(raw.DC)
        }
        self.direction = dir

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
}

public struct RGSIdentifiers: Codable {
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

public struct Applicability: Codable {
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
