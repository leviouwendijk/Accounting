import Foundation

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
    public init(entity: EntityPath, account: AccountPath, direction: Direction, amount: Decimal) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
    }
}

public struct Entry: Hashable, Codable, Sendable {
    public var date: Date
    public var lines: [Line]
    public var details: String? = nil
    public init(date: Date = Date(), lines: [Line] = [], details: String? = nil) {
        self.date = date
        self.lines = lines
        self.details = details
    }

    public var viewableString: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        var out = ["Entry on \(fmt.string(from: date)):"]
        for line in lines {
            let ent = "\(line.entity.domain).\(line.entity.alias)"
            let acc = line.account.segments.joined(separator: ".")
            let dir = line.direction == .debit ? "DR" : "CR"
            out.append("  - [\(dir)] \(ent) → \(acc): \(line.amount)")
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
