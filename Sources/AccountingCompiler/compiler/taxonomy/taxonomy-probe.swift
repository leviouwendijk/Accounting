import Accounting
import Foundation

extension TaxonomyProbe {
    public static func run(
        config: TaxonomyProbeConfig = .init()
    ) throws {
        let runner = TaxonomyProberRunner(
            config: config
        )

        try runner.run()
    }
}
