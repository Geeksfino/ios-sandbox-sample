# SandboxSDK for iOS

A comprehensive Swift wrapper for the universal sandbox Rust SDK, providing secure execution framework for iOS applications with fine-grained capability control.

## Features

- **Policy Decision Pattern (PDP)**: Evaluate features without execution, letting your app control when to act
- **Fine-grained Security**: Feature → Capability → Primitive hierarchy with context-aware policies
- **Performance Monitoring**: Real-time metrics, execution history, and proactive alerts
- **Resource Management**: Configurable limits for memory, CPU, network, and execution time
- **Comprehensive Audit**: Complete audit trail for security and compliance
- **Dynamic Capability Management**: Runtime capability revocation and scope modification

## Quick Start

### Installation

Add to your Xcode project:

- File > Add Packages... > Add Local... and select `sandbox/ios/SandboxSDK`

Or in `Package.swift`:

```swift
.package(path: "../sandbox/ios/SandboxSDK")
```

### Basic Usage

```swift
import SandboxSDK

// 1. Initialize
SandboxSDK.initialize()

// 2. Register features and policies (typed APIs)
let feature = Feature(
    name: "open_payment_page",
    category: .Native,
    path: "/payment",
    requiredCapabilities: [.UIAccess],
    primitives: [.MobileUI(page: "/payment", component: nil)]
)

let policy = Policy(
    requiresUserPresent: true,
    requiresExplicitConsent: false,
    sensitivity: .low,
    // RateUnit supported: .minute, .day
    rateLimit: SandboxSDK.RateLimit(unit: .minute, max: 5)
)

applyManifest(features: [feature], policies: [
    "open_payment_page": policy
])

// 3. Evaluate and execute
let decision = try SandboxSDK.evaluateFeature(
    "open_payment_page",
    args: ["amount": 100.0],
    context: ["user_present": true]
)

switch decision.status {
case .allowed:
    // Your app executes the feature
    openPaymentPage()
    // Record successful usage
    try SandboxSDK.recordUsage("open_payment_page")
case .denied:
    showError("Access denied: \(decision.reason ?? "")")
case .rateLimited:
    showError("Rate limited. Try again later.")
case .ask:
    requestUserConsent { /* re-evaluate if granted */ }
}
```

## Core APIs

### Feature Evaluation & Management

- `evaluateFeature(_:args:context:)` - Evaluate feature access
- `recordUsage(_:)` - Record successful execution
- `registerFeature(_:)` - Register individual features
- `applyManifest(_:)` - Apply complete feature/policy manifest

### Performance & Monitoring

- `getPerformanceSummary()` - Performance metrics and alerts
- `getPerformanceHistory()` - Detailed execution history
- `getResourceUsage()` - Current resource consumption
- `updateResourceLimits(_:)` - Configure resource limits

### Audit & Security

- `getAuditLog()` - Complete audit trail
- `revokeCapability(_:)` - Revoke system capabilities
- `updateCapability(_:scope:)` - Modify capability scope

## Advanced Features

### Performance Monitoring

```swift
let summary = try SandboxSDK.getPerformanceSummary()
print("Success rate: \(summary.successRate)")

// Check for alerts
for alert in summary.recentAlerts {
    print("Alert: \(alert.message)")
}
```

### Resource Management

```swift
// Monitor usage
let usage = try SandboxSDK.getResourceUsage()
if usage.memoryUsedMb > 100 {
    print("High memory usage detected")
}

// Update limits
try SandboxSDK.updateResourceLimits([
    "max_memory_mb": 128,
    "max_cpu_percent": 70
])
```

### Dynamic Capability Control

```swift
// Temporarily restrict capabilities
try SandboxSDK.updateCapability("Network", scope: .restricted)

// Revoke entirely
try SandboxSDK.revokeCapability("Camera")
```

## Documentation

📖 **[Complete Developer Guide](Documentation.md)** - Comprehensive documentation with:

- Detailed API reference
- Advanced usage patterns  
- Error handling strategies
- Performance optimization
- Best practices
- Troubleshooting guide

## Sample App

Explore the full-featured sample app in `../../ios-sandbox-sample/` demonstrating:

- Feature registration and evaluation
- Policy configuration
- Performance monitoring
- Resource management
- Error handling patterns

## Build Requirements

### For Development

- iOS 13.0+
- Xcode 14.0+
- Swift 5.7+

### Building XCFramework

```bash
# From repo root - builds Rust static libraries and packages as XCFramework
./sandbox/ios/scripts/build.sh --release
```

**Artifacts:**

- `sandbox/ios/output/libsandbox_sdk.xcframework`
- Staged copy in `Binary/libsandbox_sdk.xcframework`

## Architecture

The iOS SDK wraps the universal Rust core via C FFI:

- **Swift Layer**: Developer-friendly APIs and type safety
- **C FFI Layer**: Bridge to Rust core (`SandboxSDKFFI`)
- **Rust Core**: Policy engine, security, and monitoring

**Key FFI Functions:**

- `sandbox_evaluate_feature` - Policy evaluation
- `sandbox_record_usage` - Usage tracking
- `sandbox_apply_manifest` - Feature/policy registration
- `sandbox_get_performance_summary` - Performance metrics
- `sandbox_update_resource_limits` - Resource management

## Support

- 📖 [Documentation](Documentation.md)
- 🔍 [Sample App](../../ios-sandbox-sample/)
- 🐛 [Issue Tracker](../../issues)
- 💬 [Discussions](../../discussions)
