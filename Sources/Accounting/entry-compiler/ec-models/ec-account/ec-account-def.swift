import Foundation

public struct AccountDef: Codable, Sendable {
    public let code: String
    public var label: String?
    public var direction: Direction?
    public var level: Int?
    public var identifiers: RGSIdentifiers?
    public var applicability: Applicability?

    public init(
        code: String,
        label: String? = nil,
        direction: Direction? = nil,
        level: Int? = nil,
        identifiers: RGSIdentifiers? = nil,
        applicability: Applicability? = nil
    ) {
        self.code = code
        self.label = label
        self.direction = direction
        self.level = level
        self.identifiers = identifiers
        self.applicability = applicability
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
