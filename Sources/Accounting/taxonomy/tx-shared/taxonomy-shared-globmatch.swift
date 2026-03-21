import Foundation

extension TaxonomyShared {
    public static func globMatch(
        pattern: String,
        text: String
    ) -> Bool {
        let patternScalars = Array(pattern.unicodeScalars)
        let textScalars = Array(text.unicodeScalars)

        var patternIndex = 0
        var textIndex = 0
        var starIndex: Int?
        var matchIndex = 0

        while textIndex < textScalars.count {
            if patternIndex < patternScalars.count,
               (
                   patternScalars[patternIndex] == textScalars[textIndex]
                   || patternScalars[patternIndex] == "?"
               ) {
                patternIndex += 1
                textIndex += 1
                continue
            }

            if patternIndex < patternScalars.count,
               patternScalars[patternIndex] == "*" {
                starIndex = patternIndex
                matchIndex = textIndex
                patternIndex += 1
                continue
            }

            if let starIndex {
                patternIndex = starIndex + 1
                matchIndex += 1
                textIndex = matchIndex
                continue
            }

            return false
        }

        while patternIndex < patternScalars.count,
              patternScalars[patternIndex] == "*" {
            patternIndex += 1
        }

        return patternIndex == patternScalars.count
    }

    public static func csvDimensionBindings(
        from dimensions: [TaxonomyExplicitDimension]
    ) -> [TaxonomyDimensionBinding] {
        dimensions.map {
            TaxonomyDimensionBinding(
                axis: $0.axis,
                member: $0.member
            )
        }
    }
}
