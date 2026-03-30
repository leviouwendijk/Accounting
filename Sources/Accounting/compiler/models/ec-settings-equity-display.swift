import Foundation

public enum StatementEquitySettingsError: LocalizedError, Sendable {
    case unknownPreset(String)
    case invalidEntityPath([String])

    public var errorDescription: String? {
        switch self {
        case .unknownPreset(let preset):
            return "Unknown statement_data.equity preset '\(preset)'."

        case .invalidEntityPath(let segments):
            return "Invalid entity path in statement equity settings: \(segments.joined(separator: "."))"
        }
    }
}

public extension StatementEntityPath {
    init(
        ref: EntityRef
    ) {
        var out: [String] = []

        if let c = ref.class {
            out.append(c)
        }

        if let f = ref.family {
            out.append(f)
        }

        out.append(ref.alias.string)

        self.init(segments: out)
    }

    func makeEntityRef() throws -> EntityRef {
        switch segments.count {
        case 1:
            return EntityRef(
                class: nil,
                family: nil,
                alias: EntityAlias.parse(segments[0])
            )

        case 2:
            return EntityRef(
                class: segments[0],
                family: nil,
                alias: EntityAlias.parse(segments[1])
            )

        case 3:
            return EntityRef(
                class: segments[0],
                family: segments[1],
                alias: EntityAlias.parse(segments[2])
            )

        default:
            throw StatementEquitySettingsError.invalidEntityPath(segments)
        }
    }
}

public extension StatementEquityViewSettings {
    func makeDisplayPlan() throws -> EquityOwnerDisplayPlan {
        let resolvedSections = try sections.map { section in
            switch section.kind {
            case .standard:
                return EquityOwnerDisplaySection(
                    kind: .standard,
                    rows: []
                )

            case .rows:
                return try EquityOwnerDisplaySection(
                    kind: .manual,
                    rows: section.rows.map { row in
                        switch row.kind {
                        case .owner:
                            guard let owner = row.owner else {
                                throw StatementEquitySettingsError.invalidEntityPath([])
                            }

                            return .owner(
                                try owner.makeEntityRef()
                            )

                        case .split:
                            guard let owner = row.owner, let percent = row.percent else {
                                throw StatementEquitySettingsError.invalidEntityPath([])
                            }

                            return .split(
                                .init(
                                    owner: try owner.makeEntityRef(),
                                    portion: percent / 100,
                                    label: row.label,
                                    includeInSum: row.includeInSum ?? true
                                )
                            )

                        case .subtotal:
                            guard let label = row.label else {
                                throw StatementEquitySettingsError.invalidEntityPath([])
                            }

                            return .subtotal(
                                .init(
                                    label: label,
                                    members: try row.members.map {
                                        EquityOwnerPortion(
                                            owner: try $0.owner.makeEntityRef(),
                                            portion: $0.percent / 100
                                        )
                                    },
                                    includeInSum: row.includeInSum ?? true
                                )
                            )
                        }
                    }
                )
            }
        }

        return EquityOwnerDisplayPlan(
            sections: resolvedSections
        )
    }
}

public extension StatementEquitySettings {
    func selectedDisplayPlan() throws -> EquityOwnerDisplayPlan? {
        guard let preset else {
            return nil
        }

        guard let view = views.first(where: { $0.alias == preset }) else {
            throw StatementEquitySettingsError.unknownPreset(preset)
        }

        return try view.makeDisplayPlan()
    }
}
