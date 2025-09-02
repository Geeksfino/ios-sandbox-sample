# iOS Sandbox Sample App + Prebuilt SDK

[English](README.md) | [中文](README.zh-CN.md)

This repository contains:

- Sandbox sample app source (`Sources/`)
- Prebuilt SDK binary (`Vendor/SandboxSDK.xcframework`) exposed via Swift Package Manager

Developers can build the sample app out-of-the-box and/or consume the SDK as an SPM dependency without checking out the sandbox source.

## Requirements

- Xcode 15+
- iOS 14.0+ (deployment target)
- Git LFS (required to fetch `xcframework` binaries)

## Architecture Overview

```text
+-----------------------------------------------------------+
|                          Sandbox Model                     |
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

Alternatively, use SwiftPM directly in Xcode by opening the package.

## Versioning & Releases

- Tags (e.g., `1.0.0`) are used for SPM version resolution.
- After updating the SDK or APIs, bump the version tag and push.

## License

TBD.
