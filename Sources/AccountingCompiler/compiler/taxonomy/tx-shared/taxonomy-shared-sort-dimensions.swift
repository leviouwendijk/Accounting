import Accounting
import Foundation

extension TaxonomyShared {
    public static func sortDimensions(
        _ dimensions: [TaxonomyDimensionBinding]
    ) -> [TaxonomyDimensionBinding] {
        dimensions.sorted {
            if $0.axis == $1.axis {
                return $0.member < $1.member
            }

            return $0.axis < $1.axis
        }
    }
}
