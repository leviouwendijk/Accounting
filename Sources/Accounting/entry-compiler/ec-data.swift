import Foundation

public enum DateSpecification: Hashable, Codable, Sendable, Equatable {
    case absolute(Date)
    case infer(day: Int)
}

public struct EntityPath: Hashable, Codable, Sendable {
    public let domain: String            // "people"
    public let aliasSegments: [String]   // ["levi", "ouwendijk"]
    public init(domain: String, aliasSegments: [String]) {
        self.domain = domain
        self.aliasSegments = aliasSegments
    }

    public var alias: String { aliasSegments.joined(separator: "_") }
}

public struct AccountPath: Hashable, Codable, Sendable {
    public let segments: [String]
    public init(segments: [String]) { self.segments = segments }
}

public struct Line: Hashable, Codable, Sendable {
    public let entity: EntityPath
    public let account: AccountPath
    public let direction: Direction
    public let amount: Decimal
    public let adjustment: InventoryAdjustment?

    public init(
        entity: EntityPath,
        account: AccountPath,
        direction: Direction,
        amount: Decimal,
        adjustment: InventoryAdjustment? = nil
    ) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
        self.adjustment = adjustment
    }
}

public struct Entry: Hashable, Codable, Sendable {
    public var date: DateSpecification
    public var lines: [Line]
    public var details: String? = nil

    public init(
        date: DateSpecification = .absolute(Date()),
        lines: [Line] = [],
        details: String? = nil
    ) {
        self.date = date
        self.lines = lines
        self.details = details
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
            let ent = "\(line.entity.domain).\(line.entity.alias)"
            let acc = line.account.segments.joined(separator: ".")
            let dir = line.direction == .debit ? "DR" : "CR"
            var lineStr = "  - [\(dir)] \(ent) → \(acc): \(line.amount)"
            if let adj = line.adjustment {
                let tag = (adj.mutation == .addition || adj.mutation == .add) ? "ADD" : "REM"
                lineStr += "  (\(tag) \(adj.count))"
            }
            out.append(lineStr)
        }
        if let d = details {
            out.append("Details: \(d)")
        }
        return out.joined(separator: "\n")
    }
}

public struct SourceLocation: CustomStringConvertible, Sendable {
    public let line: Int
    public let column: Int
    public var description: String { "\(line):\(column)" }
}
