import Foundation
import plate

// Handy mapping for "legacyAssetId -> preferred entity alias/unit + expense account"
public struct LegacyAssetMapping: Sendable, Codable {
    public let alias: String
    public let entity: String
    public let unit: String
    public let account: String?

    public init(alias: String, of entity: String, unit: String, account: String? = nil) {
        self.alias = alias
        self.entity = entity
        self.unit = unit
        self.account = account
    }

    public var entrySyntaxForEntity: String {
        return "\(alias)#\(entity)(\(unit))"
    }
}

public enum LegacyAssetMappings {
    public static let rgs_3_8: [Int: LegacyAssetMapping] = [
        1: .init(
            alias: "macbook",
            of: "levi",
            unit: "air_m2",
            account: "WAfsAmvBei"
        ), // // Monthly depreciation ~22.03 (cost 1,652.07, RV 20%, 5y) → MacBook Air M2. 

        2: .init(
            alias: "macbook",
            of: "shusha",
            unit: "air_m2",
            account: "WAfsAmvBei"
        ),

        3: .init(
            alias: "iphone",
            of: "casper",
            unit: "15_pro_max",
            account: "WAfsAmvBei"
        ),

        4: .init(
            alias: "airpods",
            of: "shusha",
            unit: "shusha(max)",
            account: "WAfsAmvBei"
        ),

        5: .init(
            alias: "camera_equipment",
            of: "casper",
            unit: "peak_design_travel_tripod",
            account: "WAfsAmvBei"
        ),

        6: .init(
            alias: "monitor",
            of: "casper",
            unit: "lg_nano_ips_4k",
            account: "WAfsAmvBei"
        ),
    ]
}

// syntax modification?
// entity(macbook#levi(air_m2))
// for (macbook#levi(air_m2))
// for macbook#levi(air_m2)
// for macbook#levi#air_m2
