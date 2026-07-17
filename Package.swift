// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClassicLaunchpad",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ClassicLaunchpad", targets: ["ClassicLaunchpad"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Kyome22/OpenMultitouchSupport.git",
            exact: "4.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "ClassicLaunchpad",
            dependencies: [
                .product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")
            ],
            path: "Sources/ClassicLaunchpad"
        ),
        .testTarget(
            name: "ClassicLaunchpadTests",
            dependencies: ["ClassicLaunchpad"],
            path: "Tests/ClassicLaunchpadTests"
        )
    ]
)
