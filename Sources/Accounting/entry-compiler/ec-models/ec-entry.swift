import Foundation

public struct Entry: Hashable, Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var lines: [Line]
    public var details: String? = nil
    public var timezone: String? = nil
    public var transactionReferences: [EntryCompilerTransactionID]

    public init(
        id: Int? = nil,
        date: DateSpecification = .absolute(Date()),
        lines: [Line] = [],
        details: String? = nil,
        timezone: String? = nil,
        transactionReferences: [EntryCompilerTransactionID] = []
    ) {
        self.id = id
        self.date = date
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.transactionReferences = transactionReferences
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
            let acc = line.account.segments.joined(separator: ".")
            let dir = line.direction == .debit ? "DR" : "CR"
            var lineStr = "  - [\(dir)] \(ent) → \(acc): \(line.amount)"
            if let adj = line.adjustment {
                let tag = (adj.mutation == .addition || adj.mutation == .add) ? "ADD" : "REM"
                lineStr += "  (\(tag) \(adj.count))"
            }
            // transactionRefs somewhere here
            out.append(lineStr)
        }
        if let d = details {
            out.append("Details: \(d)")
        }
        return out.joined(separator: "\n")
    }
}

