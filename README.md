# iOS Sandbox Sample App + Prebuilt SDK

[English](README.md) | [中文](README.zh-CN.md)

This repository contains:

- Sandbox sample app source (`Sources/`)
- Prebuilt SDK binary (`Vendor/SandboxSDK.xcframework`) exposed via Swift Package Manager

Documentation:

- See `Vendor/SandboxSDK-Documentation.md` for the complete Swift API guide (staged with the XCFramework).

Developers can build the sample app out-of-the-box and/or consume the SDK as an SPM dependency without checking out the sandbox source.

## Requirements

- Xcode 15+
- iOS 14.0+ (deployment target)
- Git LFS (required to fetch `xcframework` binaries)

## Architecture Overview

```text
+-----------------------------------------------------------+
|                  App using Sandbox Model                   |
+-----------------------------------------------------------+
|  Remote Agent / LLM                                        |
|          |                                                 |
|          v                                                 |
|      [ Host App ]                                          |
|          |                                                 |
|          v                                                 |
|      [ Sandbox SDK ]                                       |
|          |                                                 |
|   Checks Feature → Capabilities → Policy                   |
|          |                                                 |
|          v                                                 |
|    [ Policy Engine ]                                       |
|    - Context check (time, location, consent)               |
|    - User confirmation if required                         |
|          |                                                 |
|          v                                                 |
|   Decision: Allow / Deny / Needs Confirmation              |
|          |                                                 |
|          v                                                 |
|    [ Adapter / Primitive ]                                 |
|          |                                                 |
|          v                                                 |
|    [ OS API: Camera / File / Network ]                     |
+-----------------------------------------------------------+
```

## Consume the SDK via SPM

Add the package to your project (replace version as needed):

```swift
// Package.swift
.dependencies: [
    .package(url: "https://github.com/Geeksfino/ios-sandbox-sample.git", from: "1.0.0")
]
// target dependencies
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SandboxSDK", package: "ios-sandbox-sample")
    ]
)
```

Then import and use:

```swift
import SandboxSDK

@main
struct MyApp: App {
    init() {
        _ = SandboxSDK.initialize()
    }
    // ...
}

// Evaluate and record usage
let decision = try SandboxSDK.evaluateFeature("perform_payment", args: ["amount": 100], context: nil)
if decision.status == .allowed {
    // Perform host action, then:
    _ = try SandboxSDK.recordUsage("perform_payment")
}
```

Available module-level APIs (see `sandbox/ios/SandboxSDK/Sources/SandboxSDK/Sandbox.swift` for details):

- `initialize() -> Bool`
- `evaluateFeature(_:args:context:) throws -> PolicyDecision`
- `recordUsage(_:) throws -> OkResponse`
- `getAuditLog() throws -> [[String: Any]]`
- `clearAuditLog()`
- `updateResourceLimits(_:) throws -> OkResponse`
- `applyManifest(_:) -> Bool`
- `registerFeature(_:) -> Bool`
- `setPolicies(_:) -> Bool`

## Build the Sample App

This repo includes an XcodeGen project spec (`project.yml`). Generate and build via Xcode:

1. `brew install xcodegen` (if needed)
2. `xcodegen generate`
3. Open the generated `.xcodeproj` and build the `SandboxSampleApp` scheme

## Create Your Own iOS App (independent of this repo)

The Sandbox SDK can be consumed via SPM to build your own iOS app in a separate project. Below is a minimal path that works end‑to‑end.

1. Prerequisites

- Xcode 15+
- iOS 15.0+ deployment target (required if you use modern SwiftUI APIs like `confirmationDialog` and `.borderedProminent`)
- XcodeGen (to generate an iOS app target)

1. Create a new folder structure

- Create a new directory (e.g., `sandbox-test/`) with:
  - `Package.swift` (Swift Package to declare the dependency on this SDK)
  - `Sources/sandbox-test/` with your SwiftUI app sources
  - `project.yml` (XcodeGen spec to produce an iOS app target)

1. Package.swift

Declare a dependency on this repo and link the `SandboxSDK` product:

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "sandbox-test",
    platforms: [ .iOS(.v14) ],
    products: [ .executable(name: "sandbox-test", targets: ["sandbox-test"]) ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/ios-sandbox-sample.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "sandbox-test",
            dependencies: [ .product(name: "SandboxSDK", package: "ios-sandbox-sample") ],
            path: "Sources/sandbox-test",
            swiftSettings: [ .unsafeFlags(["-parse-as-library"]) ]
        )
    ]
)
```

Note: A SwiftPM executable alone targets macOS by default. To run on iOS, generate an iOS app target with XcodeGen.

1. XcodeGen project.yml

```yaml
name: sandbox-test
options:
  minimumXcodeGenVersion: 2.38.0
settings:
  base:
    IPHONEOS_DEPLOYMENT_TARGET: "15.0"
    SWIFT_VERSION: "5.0"
    CODE_SIGN_STYLE: Automatic
packages:
  ios-sandbox-sample:
    url: https://github.com/Geeksfino/ios-sandbox-sample.git
    from: 1.0.0
targets:
  sandbox-test:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources:
      - path: Sources/sandbox-test
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.sandbox.test
        GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - package: ios-sandbox-sample
        product: SandboxSDK
```

1. Minimal SwiftUI integration

- On app launch: `SandboxSDK.initialize()` then `SandboxSDK.applyManifest(...)`.
- When a feature is requested: `evaluateFeature(name)` and branch on the returned `DecisionStatus`.
- After you actually perform the action: `recordUsage(name)`.
- Swift 6 tip: add `@unknown default:` to your `switch` over `DecisionStatus`.

Example features/policies:

- `navigateToB` → requires user consent (`requires_user_present`, `requires_explicit_consent`).
- `navigateToC` → denied (e.g., require an unmet capability to enforce deny).

1. Generate & run

- Install XcodeGen: `brew install xcodegen`
- From your project folder: `xcodegen generate`
- Open the generated `.xcodeproj`, pick an iOS 15+ simulator, and run the scheme.

Troubleshooting:

- If you see “While building for macOS, no library for this platform was found”, you opened a SwiftPM executable without an iOS app target. Use the XcodeGen project and run the iOS scheme.
- API availability errors for `alert(...actions:message:)` / `confirmationDialog(...)` mean your deployment target is below iOS 15. Bump it to iOS 15 in `project.yml`.

## SDK Build Information
- **Version**: e5de24f
- **Built from**: [e5de24f95a0a3091cef915f724bd85c3ed24ba83](https://github.com/Geeksfino/finclip-sandbox/commit/e5de24f95a0a3091cef915f724bd85c3ed24ba83)
- **Build date**: Mon Sep 15 07:44:23 UTC 2025

