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
        let local = localName(raw)
        let normalized = normalizedTaxonomyConceptKey(local)

        return TaxonomyConceptNameExtraction(
            localName: local,
            normalizedName: normalized
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

public func trim(
    _ string: String
) -> String {
    TaxonomyShared.trim(string)
}

public func localName(
    _ qualifiedName: String
) -> String {
    TaxonomyShared.localName(qualifiedName)
}

public func attributeValue(
    _ element: XMLElement,
    _ name: String
) -> String? {
    TaxonomyShared.attributeValue(element, name)
}

public func conceptNameExtraction(
    from raw: String
) -> TaxonomyConceptNameExtraction {
    TaxonomyShared.conceptNameExtraction(from: raw)
}

public func conceptName(
    from raw: String
) -> String {
    TaxonomyShared.conceptName(from: raw)
}

public func normalizedTaxonomyConceptKey(
    _ string: String
) -> String {
    TaxonomyShared.normalizedTaxonomyConceptKey(string)
}
