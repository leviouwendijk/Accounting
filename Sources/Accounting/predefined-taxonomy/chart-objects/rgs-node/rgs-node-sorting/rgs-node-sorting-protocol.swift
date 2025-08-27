import Foundation

// any type that can provide Sorting segments can opt in and gain sorting for free.
public protocol SortingKeyProviding {
    var sorteringSegments: [String] { get }
}
