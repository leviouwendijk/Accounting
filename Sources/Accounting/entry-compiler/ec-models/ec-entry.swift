import Foundation
import Extensions

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
    public let location: SourceLocation?

    public init(
        id: Int? = nil,
        date: DateSpecification = .absolute(Date()),
        sort: EntrySort? = nil,
        lines: [Line] = [],
        details: String? = nil,
        timezone: String? = nil,
        transactionReferences: [Int] = [],
        location: SourceLocation? = nil
    ) {
        self.id = id
        self.date = date
        self.sort = sort
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.transactionReferences = transactionReferences
        self.location = location
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
        return out.joined(separator: "\n")
    }
}
