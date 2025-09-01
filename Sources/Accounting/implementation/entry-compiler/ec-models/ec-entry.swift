import Foundation
import Extensions
import plate

public enum EntrySort: String, RawRepresentable, Hashable, Codable, Sendable, StringParsableEnum {
    case regular
    case adjusting
}

public struct Entry: Hashable, Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var sort: EntrySort?
    public var lines: [Line]
    public var details: String? = nil
    public var timezone: String? = nil
    public var transactionReferences: [Int]
    public var metadata: [String: String] = [:]
    public var location: SourceLocation?
    public var mistake: Mistake? = nil
    public var verbose: Bool = false

    public init(
        id: Int? = nil,
        date: DateSpecification = .absolute(Date()),
        sort: EntrySort? = nil,
        lines: [Line] = [],
        details: String? = nil,
        timezone: String? = nil,
        transactionReferences: [Int] = [],
        metadata: [String: String] = [:],
        location: SourceLocation? = nil,
        mistake: Mistake? = nil,
        verbose: Bool = false
    ) {
        self.id = id
        self.date = date
        self.sort = sort
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.transactionReferences = transactionReferences
        self.metadata = metadata
        self.location = location
        self.mistake = mistake
        self.verbose = verbose

        printPlaceholderWarning(verbose: verbose)
    }

    public func printPlaceholderWarning(verbose: Bool = false) {
        let (placeholders, report) = entityPlaceholderWarning()
        if placeholders == 0, !verbose { 
            return 
        }
        print(report)
        print()
        let str = (placeholders > 0) ? "\(placeholders)".ansi(.red, .bold) : "\(placeholders)".ansi(.green)
        print(str)
    }

    public func entityPlaceholderWarning(
        for values: [String] = ["asset_placeholder"]
    ) -> (Int, String) {
        var count = 0
        var matches: [String] = []

        func match(_ match: String, at location: SourceLocation? = nil) {
            matches.append("! WARNING: Placeholder detected\n")
            matches.append("    value: \"match\"\n")
            if let l = location {
                matches.append("    at: \(l.description)\n")
            }
        }

        for l in lines {
            for v in values {
                if l.entity.alias.name.contains(v) {
                    count += 1
                    match(v, at: l.location)
                }
            }
            
        }
        let result = matches.joined(separator: "\n")
        return (count, result)
    }

    public var viewableString: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        let dateStr: String = {
            switch date {
            case .absolute(let d): return fmt.string(from: d)
            case .infer(let day):  return "inferred-day \(day)"
            }
        }()
        var out = ["Entry on \(dateStr):"]
        for line in lines {
            let ent = line.entity.printable
            let acc: String = {
                switch line.account {
                case .code(let s): return s
                case .identifier(let s): return s
                case .path(let segs): return segs.joined(separator: ".")
                }
            }()
            let dir = line.direction == .debit ? "DR" : "CR"
            var lineStr = "  - [\(dir)] \(ent) → \(acc): \(line.amount)"
            if let adj = line.adjustment {
                let tag = (adj.mutation == .addition || adj.mutation == .add) ? "ADD" : "REM"
                lineStr += "  (\(tag) \(adj.count))"
            }
            out.append(lineStr)
        }
        if let d = details { out.append("Details: \(d)") }
        if let m = mistake { 
            out.append("[!] Mistake:".ansi(.yellow)) 
            out.append("\n")
            out.append(m.description)
        }
        return out.joined(separator: "\n")
    }
}
