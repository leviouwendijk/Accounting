// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Accounting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Accounting",
            targets: ["Accounting"]
        ),
        .library(
            name: "AccountingLegacy",
            targets: ["AccountingLegacy"]
        ),
        .executable(
            name: "ec",
            targets: ["ec"]
        ),
        .executable(
            name: "eclsp",
            targets: ["eclsp"]
        ),
        .executable(
            name: "ecvparity",
            targets: ["ecvparity"]
        ),
        .executable(
            name: "acctest",
            targets: ["AccountingTestFlows"]
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
        .package(url: "https://github.com/leviouwendijk/Interfaces.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Arguments.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Difference.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
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
                .product(name: "Arguments", package: "Arguments"),
            ],
        ),
        .target(
            name: "AccountingParsers",
            dependencies: [
                "Accounting",
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
                .product(name: "Arguments", package: "Arguments"),
            ],
        ),
        .target(
            name: "AccountingCompiler",
            dependencies: [
                "Accounting",
                "AccountingParsers",
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
                .product(name: "Arguments", package: "Arguments"),
            ],
        ),
        .target(
            name: "AccountingLegacy",
            dependencies: [
                "Accounting",
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
            ],
        ),
        .executableTarget(
            name: "ec",
            dependencies: [
                "Accounting",
                "AccountingParsers",
                "AccountingCompiler",
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "Arguments", package: "Arguments"),
            ],
            path: "Sources/EntryCompilerCLI"
        ),
        .executableTarget(
            name: "eclsp",
            dependencies: [
                "Accounting",
                "AccountingCompiler",
                "AccountingParsers",
            ],
            path: "Sources/EntryCompilerLSP"
        ),
        .executableTarget(
            name: "ecvparity",
            dependencies: [
                "Accounting",
                .product(name: "Difference", package: "Difference"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "Arguments", package: "Arguments"),
                .product(name: "Terminal", package: "Terminal"),
            ],
            path: "Sources/EntryCompilerParity"
        ),

        .executableTarget(
            name: "AccountingTestFlows",
            dependencies: [
                "Accounting",
                "AccountingParsers",
                "AccountingCompiler",
                .product(name: "plate", package: "plate"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Methods", package: "Methods"),
                .product(name: "HTML", package: "HTML"),
                .product(name: "CSS", package: "CSS"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Terminal", package: "Terminal"),
                .product(name: "Arguments", package: "Arguments"),
                .product(name: "TestFlows", package: "TestFlows"),
            ],
        ),
    ]
)
