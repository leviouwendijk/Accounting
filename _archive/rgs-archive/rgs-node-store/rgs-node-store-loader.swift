// import Foundation

// public enum RGSNodeStoreLoader {
//     public static func load(from project: EntryCompilerProject) throws -> RGSNodeStore? {
//         let url = project.url(.config).appendingPathComponent("rgs.compiled.json")
//         guard FileManager.default.fileExists(atPath: url.path) else { return nil }
//         let data = try Data(contentsOf: url)
//         let chart = try JSONDecoder().decode(CompiledChart.self, from: data)
//         return RGSNodeStore(chart: chart)
//     }
// }
