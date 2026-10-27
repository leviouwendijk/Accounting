import Accounting
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var accountingEntityIdentitiesFlow: TestFlow {
        TestFlow("accounting-entity-identities", tags: ["accounting", "invariance", "entities"]) {
            Step("entity alias preserves spelling and variant hierarchy") {
                let alias = try EntityAlias.parse("macbook#levi_air_m2#nl")
                try Expect.equal(alias.name, "macbook", "alias name")
                try Expect.equal(alias.variant, ["levi_air_m2", "nl"], "variants")
                try Expect.equal(alias.string, "macbook#levi_air_m2#nl", "lossless alias")
                let extended = try alias.appendingVariant("2026")
                try Expect.equal(extended.string, "macbook#levi_air_m2#nl#2026", "appended variant")
            }
            Step("entity alias rejects malformed components") {
                for input in ["", "#x", "x#", "x##y", "x.y", "x#y.z", "   "] {
                    try Expect.throwsError("invalid alias \(input)") {
                        _ = try EntityAlias.parse(input)
                    }
                }
                try Expect.throwsError("empty variant array") {
                    _ = try EntityAlias(name: "valid", variant: [])
                }
            }
            Step("entity key validates qualified identity without normalization") {
                let alias = try EntityAlias.parse("asset#serial_01")
                let key = try EntityKey(class: "objects", family: "usable", alias: alias)
                try Expect.equal(key.identifier(displaying: .root), "objects.usable.asset", "root identity")
                try Expect.equal(key.identifier(displaying: .fullchain), "objects.usable.asset#serial_01", "full identity")
                for component in ["", " ", "objects.other", "objects#other"] {
                    try Expect.throwsError("invalid class \(component)") {
                        _ = try EntityKey(class: component, family: "usable", alias: alias)
                    }
                    try Expect.throwsError("invalid family \(component)") {
                        _ = try EntityKey(class: "objects", family: component, alias: alias)
                    }
                }
            }
            Step("codable rejects invalid nested identities") {
                let decoder = JSONDecoder()
                let alias = try EntityAlias.parse("a#b")
                let key = try EntityKey(class: "objects", family: "usable", alias: alias)
                let restored = try decoder.decode(EntityKey.self, from: JSONEncoder().encode(key))
                try Expect.equal(restored, key, "keyed entity identity round-trip")
                try Expect.throwsError("invalid alias in JSON") {
                    _ = try decoder.decode(EntityAlias.self, from: Data(#"{"name":"a","variant":[""]}"#.utf8))
                }
                try Expect.throwsError("invalid class in JSON") {
                    _ = try decoder.decode(EntityKey.self, from: Data(#"{"class":"","family":"usable","alias":{"name":"a","variant":null}}"#.utf8))
                }
            }
        }
    }
}
