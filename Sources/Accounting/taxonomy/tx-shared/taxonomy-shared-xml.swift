import Foundation

extension TaxonomyShared {
    public static func descendantElements(
        of root: XMLElement
    ) -> [XMLElement] {
        var out: [XMLElement] = []

        func visit(_ element: XMLElement) {
            out.append(element)

            for child in element.children ?? [] {
                guard let childElement = child as? XMLElement else {
                    continue
                }

                visit(childElement)
            }
        }

        visit(root)
        return out
    }
}
