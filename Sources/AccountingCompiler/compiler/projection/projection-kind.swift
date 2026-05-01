import Accounting
import Foundation

public enum ProjectionKind: Sendable, Equatable {
    case native
    case taxonomy(profile: String, presentation: [String] = [])
}
