// swift-tools-version:6.0

import PackageDescription

let wasiLibcCSettings: [CSetting] = [
    .define("_WASI_EMULATED_SIGNAL", .when(platforms: [.wasi])),
    .define("_WASI_EMULATED_MMAN", .when(platforms: [.wasi])),
]

let package = Package(
    name: "swift-feeds",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "Feeds",
            targets: ["Feeds"]
        ),
    ],
    targets: [
        .target(
            name: "Feeds",
            dependencies: [
                "_FoundationCShims",
                "_FoundationEssentials"
            ]
        ),
        // _FoundationCShims (Internal)
        .target(
            name: "_FoundationCShims",
            cSettings: [
                .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows]))
            ] + wasiLibcCSettings
        ),
        // _FoundationEssentials
        .target(
            name: "_FoundationEssentials",
            dependencies: [
            "_FoundationCShims"
            ]
          ),
        .testTarget(
            name: "FeedsTests",
            dependencies: ["Feeds"],
            resources: [.process("json"), .process("xml")]
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
