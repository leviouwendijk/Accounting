// import Arguments
// import Foundation

// enum EntryCompilerCommandSpec {
//     static func make() throws -> CommandSpec {
//         try cmd("ec") {
//             defaultChild("compile")

//             try compileSpec()
//             try cmd("depreciation") {}
//             try cmd("id") {}
//             try cmd("rgs-hierarchy") {}
//             try equitySpec()
//             try periodSpec()
//             try vatSpec()
//             try cmd("taxonomy-probe") {}
//             try cmd("kia") {}
//             try cmd("document") {}
//             try assetsSpec()
//             try sourceSpec()
//             try metaSpec()
//             try cmd("cost") {}
//         }
//     }

//     private static func compileSpec() throws -> CommandSpec {
//         try cmd("compile") {
//             try periodSpec()
//             try equitySpec()

//             try projectOptions()

//             opt(
//                 "snapshots-dir",
//                 as: String.self,
//                 default: "_snapshots"
//             )

//             flag(
//                 "verbose",
//                 short: "v"
//             )

//             flag("trace")

//             opt(
//                 "caption",
//                 as: String.self,
//                 default: "label"
//             )

//             opt(
//                 "detail",
//                 as: String.self,
//                 default: "standard"
//             )

//             try projectionOptions(
//                 includeDiagAlias: true
//             )
//         }
//     }

//     private static func equitySpec() throws -> CommandSpec {
//         try cmd("equity") {
//             try periodWindowOptions(
//                 defaultPeriod: "month",
//                 includeCustomRange: false,
//                 includeQuarter: false
//             )

//             flag("history")
//             flag("compare")
//             flag("by-entity")
//             flag("pdf")
//             flag("trace")
//             flag("async")
//         }
//     }

//     private static func periodSpec() throws -> CommandSpec {
//         try cmd("period") {
//             try periodWindowOptions(
//                 defaultPeriod: "month",
//                 includeCustomRange: false,
//                 includeQuarter: false
//             )

//             flag("compare")
//             flag("by-entity")

//             opt(
//                 "margins",
//                 as: Double.self,
//                 default: 40.0
//             )

//             flag("pdf")
//             flag("trace")

//             opt(
//                 "caption",
//                 as: String.self,
//                 default: "label"
//             )

//             opt(
//                 "detail",
//                 as: String.self,
//                 default: "standard"
//             )

//             try projectionOptions(
//                 includeDiagAlias: false
//             )

//             flag(
//                 "analytics-diagnostics",
//                 alias: "diag"
//             )

//             flag("hierarchy-diagnostics")
//         }
//     }

//     private static func vatSpec() throws -> CommandSpec {
//         try cmd("vat") {
//             defaultChild("overview")

//             try cmd("overview") {
//                 try vatPeriodOptions(
//                     defaultPeriod: "quarter"
//                 )

//                 opt(
//                     "margins",
//                     as: Double.self,
//                     default: 40.0
//                 )

//                 flag("pdf")
//                 flag("trace")
//                 flag("include-corrections")
//             }

//             try cmd("audit") {
//                 try vatPeriodOptions(
//                     defaultPeriod: "quarter"
//                 )

//                 opt(
//                     "tolerance",
//                     as: Decimal.self,
//                     default: Decimal(string: "0.01")!
//                 )

//                 flag("only-flagged")
//                 flag("hide-entries")
//                 flag("trace")
//             }

//             try cmd("status") {
//                 try params(
//                     VATStatusOptions.self
//                 )
//             }
//         }
//     }

//     private static func assetsSpec() throws -> CommandSpec {
//         try cmd(
//             AssetsCommand.self
//         )
//     }

//     private static func sourceSpec() throws -> CommandSpec {
//         try cmd("source") {
//             try cmd("render") {
//                 try projectOptions()

//                 opt(
//                     "group",
//                     as: String.self
//                 )

//                 opt(
//                     "entry",
//                     as: String.self
//                 )

//                 opt(
//                     "margins",
//                     as: Double.self,
//                     default: 40.0
//                 )

//                 flag("pdf")
//                 flag("trace")
//             }
//         }
//     }

//     private static func metaSpec() throws -> CommandSpec {
//         try cmd("meta") {
//             try cmd("audit") {
//                 try periodWindowOptions(
//                     defaultPeriod: "year",
//                     includeCustomRange: true,
//                     includeQuarter: false
//                 )

//                 opt(
//                     "add-group",
//                     as: String.self,
//                     take: .many
//                 )

//                 opt(
//                     "margins",
//                     as: Double.self,
//                     default: 40.0
//                 )

//                 flag("pdf")
//                 flag("trace")
//             }
//         }
//     }

//     private static func projectOptions() throws -> DynamicParam {
//         try group("project-options") {
//             opt(
//                 "project",
//                 short: "p",
//                 as: String.self
//             )
//         }
//     }

//     private static func periodWindowOptions(
//         defaultPeriod: String,
//         includeCustomRange: Bool,
//         includeQuarter: Bool
//     ) throws -> DynamicParam {
//         try group("period-window-options") {
//             try projectOptions()

//             arg(
//                 "period",
//                 as: String.self,
//                 default: defaultPeriod
//             )

//             flag("to-date")

//             opt(
//                 "anchor",
//                 as: String.self
//             )

//             if includeCustomRange {
//                 opt(
//                     "from",
//                     as: String.self
//                 )

//                 opt(
//                     "to",
//                     as: String.self
//                 )
//             }

//             if includeQuarter {
//                 opt(
//                     "quarter",
//                     as: String.self
//                 )
//             }
//         }
//     }

//     private static func vatPeriodOptions(
//         defaultPeriod: String
//     ) throws -> DynamicParam {
//         try periodWindowOptions(
//             defaultPeriod: defaultPeriod,
//             includeCustomRange: true,
//             includeQuarter: true
//         )
//     }

//     private static func projectionOptions(
//         includeDiagAlias: Bool
//     ) throws -> DynamicParam {
//         try group("projection-options") {
//             opt(
//                 "taxonomy",
//                 as: String.self
//             )

//             opt(
//                 "presentation",
//                 as: String.self,
//                 take: .many
//             )

//             if includeDiagAlias {
//                 flag(
//                     "projection-diagnostics",
//                     alias: "diag"
//                 )
//             } else {
//                 flag("projection-diagnostics")
//             }
//         }
//     }
// }
