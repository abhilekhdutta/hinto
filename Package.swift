// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hinto",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "HintoCore", targets: ["HintoCore"]),
    ],
    targets: [
        .target(
            name: "HintoCore",
            dependencies: [],
            path: "Core",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "HintoTests",
            dependencies: ["HintoCore"],
            path: "Tests"
        ),
    ]
)
