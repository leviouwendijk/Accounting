import Foundation

extension TaxonomyShared {
    public static func trim(
        _ string: String
    ) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func localName(
        _ qualifiedName: String
    ) -> String {
        guard let colon = qualifiedName.lastIndex(of: ":") else {
            return qualifiedName
        }

        return String(qualifiedName[qualifiedName.index(after: colon)...])
    }

    public static func attributeValue(
        _ element: XMLElement,
        _ name: String
    ) -> String? {
        if let value = element.attribute(forName: name)?.stringValue {
            return value
        }

        let wantedLocalName = localName(name)

        for attribute in element.attributes ?? [] {
            guard let attributeName = attribute.name else {
                continue
            }

            if attributeName == name || localName(attributeName) == wantedLocalName {
                return attribute.stringValue
            }
        }

        return nil
    }

    public static func conceptNameExtraction(
        from raw: String
    ) -> TaxonomyConceptNameExtraction {
        let trimmed = trim(raw)

        let concept: String
        if trimmed.isEmpty {
            concept = ""
        } else if let url = URL(string: trimmed),
                  let fragment = url.fragment,
                  !fragment.isEmpty {
            concept = fragment
        } else if let hashIndex = trimmed.lastIndex(of: "#") {
            let next = trimmed.index(after: hashIndex)
            let fragment = String(trimmed[next...])
            concept = fragment.isEmpty ? trimmed : fragment
        } else {
            concept = localName(trimmed)
        }

        return TaxonomyConceptNameExtraction(
            localName: concept,
            normalizedName: normalizedTaxonomyConceptKey(concept)
        )
    }

    public static func conceptName(
        from raw: String
    ) -> String {
        conceptNameExtraction(from: raw).localName
    }

    public static func normalizedTaxonomyConceptKey(
        _ string: String
    ) -> String {
        let folded = string.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )

        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            } else {
                return "_"
            }
        }

        let collapsed = String(scalars)
            .replacingOccurrences(
                of: "_+",
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return collapsed.lowercased()
    }
}
