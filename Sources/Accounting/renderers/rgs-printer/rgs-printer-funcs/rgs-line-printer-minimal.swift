import Foundation

public func printRGSLines(
    _ title: String,
    _ lines: [StatementLine]
) {
    print("\n\(title)")
    print(String(repeating: "—", count: title.count))
    var lastLevel = 0
    for r in lines {
        if r.level != lastLevel { lastLevel = r.level }
        let indent = String(repeating: "  ", count: max(0, r.level-1))
        print("\(indent)• \(r.label)  \(r.amount)")
    }
}
