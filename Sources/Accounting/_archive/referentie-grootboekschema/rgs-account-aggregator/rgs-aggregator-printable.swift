import Foundation

extension RGSAccountAggregator {
    public func printableTree(maxLines: Int = 12) -> String {
        var output = ""
        for fam in sortedFamilies() {
            if let t = fam.title {
                output.append("# Family \(fam.key) — \(t)")
                output.append("\n")
            } else {
                output.append("# Family \(fam.key)")
                output.append("\n")
            }

            if !fam.headersL2.isEmpty {
                for a in fam.headersL2.prefix(maxLines) {
                    output.append("  L2  \(a.code)  \(a.label)")
                    output.append("\n")
                }
                if fam.headersL2.count > maxLines {
                    output.append("  … +\(fam.headersL2.count - maxLines) more L2")
                    output.append("\n")
                }
            }

            let subclasses = fam.subclasses.values.sorted { $0.key.value < $1.key.value }
            for sub in subclasses {
                if let t = sub.title {
                    output.append("  ## Subclass \(sub.key) — \(t)")
                    output.append("\n")
                } else {
                    output.append("  ## Subclass \(sub.key)")
                    output.append("\n")
                }

                // group L4 under their L3 parent
                let grouped = groupL4ByParent(in: sub)

                // output.append each L3 with its L4 children
                for (parent, kids) in grouped.pairs {
                    output.append("    L3  \(parent.code)  \(parent.label)")
                    output.append("\n")
                    for a in kids.prefix(maxLines) {
                        output.append("      L4  \(a.code)  \(a.label)")
                        output.append("\n")
                    }
                    if kids.count > maxLines {
                        output.append("      … +\(kids.count - maxLines) more L4")
                        output.append("\n")
                    }
                }

                // any L3 that had no kids still appears above (with zero children)
                // now output.append orphan L4s (no matching L3 header present)
                if !grouped.orphans.isEmpty {
                    output.append("    -- Orphan L4 (no L3 header) --")
                    for a in grouped.orphans.prefix(maxLines) {
                        output.append("      L4  \(a.code)  \(a.label)")
                        output.append("\n")
                    }
                    if grouped.orphans.count > maxLines {
                        output.append("      … +\(grouped.orphans.count - maxLines) more L4")
                        output.append("\n")
                    }
                }
            }
        }
        return output
    }
    
    public func printableFamiliesOnly(maxLines: Int = 12) throws -> String {
        var output = ""

        let grouped = try familiesGroupedByRoot()

        for root in RootNodeClass.allCases {
            guard let fams = grouped[root], !fams.isEmpty else { continue }
            output.append("## \(root)")
            output.append("\n")

            for fam in fams {
                if let t = fam.title {
                    output.append("# Family \(fam.key) — \(t)")
                    output.append("\n")
                } else {
                    output.append("# Family \(fam.key)")
                    output.append("\n")
                }

                if maxLines > 0 && !fam.headersL2.isEmpty {
                    for a in fam.headersL2.prefix(maxLines) {
                        output.append("  L2  \(a.code)  \(a.label)")
                        output.append("\n")
                    }
                    if fam.headersL2.count > maxLines {
                        output.append("  … +\(fam.headersL2.count - maxLines) more L2")
                        output.append("\n")
                    }
                }
            }
            output.append("\n")
        }
        return output
    }

    public func printableFullTree() throws -> String {
        func indent(_ level: Int) -> String { String(repeating: " ", count: level * 4) }

        var output = ""
        let grouped = try familiesGroupedByRoot()

        for root in RootNodeClass.allCases {
            guard let fams = grouped[root], !fams.isEmpty else { continue }

            // Root (no tree marker, level 0)
            output.append("root \(root)\n")

            // Families (level 1)
            for fam in fams {
                if let t = fam.title {
                    output.append("\(indent(1))└── family \(fam.key) — \(t)\n")
                } else {
                    output.append("\(indent(1))└── family \(fam.key)\n")
                }

                // All L2 headers (level 2)
                if !fam.headersL2.isEmpty {
                    for a in fam.headersL2 {
                        output.append("\(indent(2))└── L2  \(a.code)  \(a.label)\n")
                    }
                }

                // Subclasses (level 2), then L3 (level 3), then L4 (level 4)
                let subclasses = fam.subclasses.values.sorted { $0.key.value < $1.key.value }
                for sub in subclasses {
                    if let t = sub.title {
                        output.append("\(indent(2))└── subclass \(sub.key) — \(t)\n")
                    } else {
                        output.append("\(indent(2))└── subclass \(sub.key)\n")
                    }

                    let grouped = groupL4ByParent(in: sub)

                    // L3 parents and their L4 children
                    for (parent, kids) in grouped.pairs {
                        output.append("\(indent(3))└── L3  \(parent.code)  \(parent.label)\n")
                        for a in kids {
                            output.append("\(indent(4))└── L4  \(a.code)  \(a.label)\n")
                        }
                    }

                    // Orphan L4s (no L3 header present)
                    if !grouped.orphans.isEmpty {
                        output.append("\(indent(3))└── -- Orphan L4 (no L3 header) --\n")
                        for a in grouped.orphans {
                            output.append("\(indent(4))└── L4  \(a.code)  \(a.label)\n")
                        }
                    }
                }
            }

            output.append("\n")
        }

        return output
    }
}
