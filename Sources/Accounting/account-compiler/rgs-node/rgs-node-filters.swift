import Foundation

public struct RGSNodeFilterIncludable: Sendable, Codable {
    public let basis: Int?
    public let uitgebreid: Int?
    public let ez_vof: Int?
    public let zzp: Int?
    public let inactief: Int?
    
    public init(
        basis: Int?,
        uitgebreid: Int?,
        ez_vof: Int?,
        zzp: Int?,
        inactief: Int?
    ) {
        self.basis = basis
        self.uitgebreid = uitgebreid
        self.ez_vof = ez_vof
        self.zzp = zzp
        self.inactief = inactief
    }
}

public struct RGSNodeFilterExcludable: Sendable, Codable {
    public let bb: Int?
    public let wkr: Int?
    public let ez_vof: Int?
    public let bv: Int?
    public let aftrek_syst: Int?
    public let nivo5: Int?
    public let uitbr5: Int?
    
    public init(
        bb: Int?,
        wkr: Int?,
        ez_vof: Int?,
        bv: Int?,
        aftrek_syst: Int?,
        nivo5: Int?,
        uitbr5: Int?
    ) {
        self.bb = bb
        self.wkr = wkr
        self.ez_vof = ez_vof
        self.bv = bv
        self.aftrek_syst = aftrek_syst
        self.nivo5 = nivo5
        self.uitbr5 = uitbr5
    }
}

public struct RGSNodeFilters: Sendable, Codable {
    public let inclusion: RGSNodeFilterIncludable?
    public let exclusion: RGSNodeFilterExcludable?
    
    public init(
        inclusion: RGSNodeFilterIncludable? = nil,
        exclusion: RGSNodeFilterExcludable? = nil
    ) {
        self.inclusion = inclusion
        self.exclusion = exclusion
    }
}
