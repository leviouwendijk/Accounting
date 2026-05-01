import Foundation
import Primitives

public enum EntrySort: String, RawRepresentable, Hashable, Codable, Sendable, StringParsableEnum {
    case regular
    case adjusting
}

public struct Entry: Hashable, Codable, Sendable {
    public var id: Int?
    public var date: DateSpecification
    public var history: EntryHistory?
    public var sort: EntrySort?
    public var lines: [Line]
    public var details: String? = nil
    public var timezone: String? = nil
    public var transactionReferences: [Int]
    public var vat: VATAnnotation? = nil
    public var metadata: [String: String] = [:]
    public var location: SourceLocation?
    public var mistake: Mistake? = nil
    public var select: EntrySelect? = nil
    public var verbose: Bool = false

    public init(
        id: Int? = nil,
        date: DateSpecification = .absolute(Date()),
        history: EntryHistory? = nil,
        sort: EntrySort? = nil,
        lines: [Line] = [],
        details: String? = nil,
        timezone: String? = nil,
        transactionReferences: [Int] = [],
        vat: VATAnnotation? = nil,
        metadata: [String: String] = [:],
        location: SourceLocation? = nil,
        mistake: Mistake? = nil,
        select: EntrySelect? = nil,
        verbose: Bool = false
    ) {
        self.id = id
        self.date = date
        self.history = history
        self.sort = sort
        self.lines = lines
        self.details = details
        self.timezone = timezone
        self.transactionReferences = transactionReferences
        self.vat = vat
        self.metadata = metadata
        self.location = location
        self.mistake = mistake
        self.select = select
        self.verbose = verbose

        // printPlaceholderWarning(verbose: verbose)
        // move this to ../ec-ext-entry.swift -> in parseEntry()
    }

    public func printPlaceholderWarning(verbose: Bool = false) {
        let (count, report) = entityPlaceholderWarning()

        if count == 0 {
            if verbose {
                print("0")
            }
            return
        }

        print(report)
        // print("\(count)".ansi(.red, .bold))
        print("placeholders in entry (id: \(self.id, default: "unknown")): \(count)".ansi(.red, .bold))
        print()
    }

    public func entityPlaceholderWarning() -> (Int, String) {
        var count = 0
        var matches: [String] = []

        func record(
            kind: String? = nil,
            value: String? = nil,
            loweredAlias: String? = nil,
            at location: SourceLocation? = nil
        ) {
            matches.append("! WARNING: Placeholder detected")
            if let kind {
                matches.append("    kind: \"\(kind)\"")
            }
            if let value {
                matches.append("    value: \"\(value)\"")
            }
            if let loweredAlias {
                matches.append("    lowered alias: \"\(loweredAlias)\"")
            }
            if let location {
                matches.append("    at: \(location.description)")
            }
        }

        for l in lines {
            if let placeholder = l.entity.placeholder {
                count += 1
                record(
                    kind: placeholder.kind.rawValue,
                    loweredAlias: placeholder.loweredAlias,
                    at: l.location
                )
                continue
            }

            let alias = l.entity.alias.name
            if alias.hasSuffix("_placeholder") {
                count += 1
                record(
                    value: alias,
                    at: l.location
                )
            }
        }

        return (count, matches.joined(separator: "\n"))
    }

    public var viewableString: String {
        // let fmt = DateFormatter()
        // fmt.dateStyle = .short
        // fmt.timeStyle = .none
        // let dateStr: String = {
        //     switch date {
        //     case .absolute(let d): return fmt.string(from: d)
        //     case .infer(let day):  return "inferred-day \(day)"
        //     }
        // }()
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none

        func fmtDateSpec(_ spec: DateSpecification) -> String {
            switch spec {
            case .absolute(let d):
                return fmt.string(from: d)
            case .infer(let day):
                return "inferred-day \(day)"
            }
        }

        let dateStr = fmtDateSpec(date)

        var out = ["Entry on \(dateStr):"]

        if let history, !history.events.isEmpty {
            out.append("History:")
            for event in history.events {
                out.append("  - \(event.kind.rawValue): \(fmtDateSpec(event.date))")
                if let details = event.details, !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    out.append("    \(details)")
                }
            }
        }
        
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
        if let v = vat { out.append("VAT Annotation: \(v)") }
        if let m = mistake { 
            out.append("[!] Mistake:".ansi(.yellow)) 
            out.append("\n")
            out.append(m.description)
        }
        if let s = select { out.append("Select: \(s)") }
        return out.joined(separator: "\n")
    }

    public func resolvedPostingDate(using settings: EntryCompilerSettings) -> Date? {
        guard case let .absolute(d) = (try? date.resolved(for: self, using: settings)) else {
            return nil
        }
        return d
    }
}
