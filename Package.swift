// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SandboxSampleApp",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Library product exposing the prebuilt SandboxSDK for consumers
        .library(name: "SandboxSDK", targets: ["SandboxSDK"]),
        // Sample app executable (optional for this package)
        .executable(name: "SandboxSampleApp", targets: ["SandboxSampleApp"])
    ],
    dependencies: [],
    targets: [
        // Consume prebuilt SandboxSDK framework directly
        .binaryTarget(
            name: "SandboxSDK",
            path: "Vendor/SandboxSDK.xcframework"
        ),
        .executableTarget(
            name: "SandboxSampleApp",
            dependencies: ["SandboxSDK"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
