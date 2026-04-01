// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Accounting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Accounting",
            targets: ["Accounting"]
        ),
        .library(
            name: "AccountingLegacy",
            targets: ["AccountingLegacy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/plate.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Methods.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/HTML.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/CSS.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Writers.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Terminal.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Accounting",
            dependencies: [
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
            ],
        ),

        .target(
            name: "AccountingLegacy",
            dependencies: [
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
            ],
        ),

        .testTarget(
            name: "AccountingTests",
            dependencies: [
                "Accounting",
                .product(name: "plate", package: "plate"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
            ]
        ),
    ]
)


