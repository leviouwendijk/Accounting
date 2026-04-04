public enum ECDocumentRenderer {
    public static func renderHTML(
        _ document: ECDocument
    ) throws -> String {
        switch document.kind {
        case .declaration_of_truthfulness:
            return try renderTruthfulness(document)

        case .discrepancy_statement:
            return try renderDiscrepancyStatement(document)

        case .generic:
            return try renderGenericDocument(document)
        }
    }
}
