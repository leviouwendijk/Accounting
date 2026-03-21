import Foundation

public enum TaxonomyCSVParser {
    public static func splitSemicolonLine(
        _ line: String
    ) -> [String] {
        var cells: [String] = []
        var current = ""
        var isInsideQuotes = false

        for character in line {
            if character == "\"" {
                isInsideQuotes.toggle()
                continue
            }

            if character == ";" && !isInsideQuotes {
                cells.append(trim(current))
                current = ""
                continue
            }

            current.append(character)
        }

        cells.append(trim(current))
        return cells
    }

    public static func parseMappingSource(
        _ raw: String
    ) -> TaxonomyCSVMappingSource {
        let value = trim(raw)

        if value.contains("+") || value.contains("-") {
            let terms = parseGroupTerms(value)
            if !terms.isEmpty {
                return .group(terms)
            }
        }

        if value.contains("*") || value.contains("?") {
            return .glob(value)
        }

        if value.hasSuffix("%") {
            return .prefix(String(value.dropLast()))
        }

        return .exact(value)
    }

    public static func parseMappingCSV(
        _ csv: String
    ) throws -> TaxonomyCSVMappingFile {
        let lines = csv
            .components(separatedBy: .newlines)
            .map(trim)
            .filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            throw TaxonomyProbeError.missingMappingHeader
        }

        let header = splitSemicolonLine(headerLine)
        let lowercasedHeader = header.map { $0.lowercased() }

        guard let sourceIndex = lowercasedHeader.firstIndex(where: {
            $0.contains("bron") || $0.contains("source")
        }) else {
            throw TaxonomyProbeError.missingColumn("source")
        }

        guard let conceptIndex = lowercasedHeader.firstIndex(where: {
            $0.contains("concept")
                || $0.contains("doel")
                || $0.contains("target")
        }) else {
            throw TaxonomyProbeError.missingColumn("targetConcept")
        }

        let dimensionIndexes = lowercasedHeader.enumerated().compactMap { index, name in
            if name.contains("dimensie") || name.contains("dimension") {
                return index
            }

            return nil
        }

        var rows: [TaxonomyCSVMappingRow] = []

        for line in lines.dropFirst() {
            let cells = splitSemicolonLine(line)

            guard sourceIndex < cells.count, conceptIndex < cells.count else {
                continue
            }

            let rawSource = cells[sourceIndex]
            let rawConcept = cells[conceptIndex]

            guard !rawSource.isEmpty, !rawConcept.isEmpty else {
                continue
            }

            var dimensions: [TaxonomyExplicitDimension] = []

            for index in dimensionIndexes where index < cells.count {
                let rawDimension = cells[index]
                guard !rawDimension.isEmpty else {
                    continue
                }

                if let dimension = csvAxisQName(from: rawDimension) {
                    dimensions.append(dimension)
                }
            }

            var rawByHeader: [String: String] = [:]
            for (index, name) in header.enumerated() where index < cells.count {
                rawByHeader[name] = cells[index]
            }

            rows.append(
                TaxonomyCSVMappingRow(
                    source: parseMappingSource(rawSource),
                    targetConcept: rawConcept,
                    dimensions: dimensions,
                    raw: rawByHeader
                )
            )
        }

        return TaxonomyCSVMappingFile(
            header: header,
            rows: rows
        )
    }

    public static func csvAxisQName(
        from raw: String
    ) -> TaxonomyExplicitDimension? {
        let value = trim(raw)
        guard !value.isEmpty else {
            return nil
        }

        let separators = ["=", ":"]
        for separator in separators {
            let parts = value.components(separatedBy: separator)
            if parts.count == 2 {
                let axis = trim(parts[0])
                let member = trim(parts[1])

                guard !axis.isEmpty, !member.isEmpty else {
                    continue
                }

                return TaxonomyExplicitDimension(
                    axis: axis,
                    member: member
                )
            }
        }

        return nil
    }
}

private extension TaxonomyCSVParser {
    static func parseGroupTerms(
        _ raw: String
    ) -> [TaxonomyCSVGroupTerm] {
        var terms: [TaxonomyCSVGroupTerm] = []
        var buffer = ""
        var sign: Decimal = 1

        func flushBuffer() {
            let pattern = trim(buffer)
            guard !pattern.isEmpty else {
                buffer = ""
                return
            }

            terms.append(
                TaxonomyCSVGroupTerm(
                    sign: sign,
                    pattern: pattern
                )
            )
            buffer = ""
        }

        for character in raw {
            if character == "+" {
                flushBuffer()
                sign = 1
                continue
            }

            if character == "-" {
                flushBuffer()
                sign = -1
                continue
            }

            buffer.append(character)
        }

        flushBuffer()
        return terms
    }
}
