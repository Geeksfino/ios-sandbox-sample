# SandboxSDK for iOS - Complete Developer Guide

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Core Concepts](#core-concepts)
4. [API Reference](#api-reference)
5. [Advanced Usage](#advanced-usage)
6. [Error Handling](#error-handling)
7. [Performance Monitoring](#performance-monitoring)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../sandbox/ios/SandboxSDK")
]
```

Or in Xcode: File > Add Packages... > Add Local... and select `sandbox/ios/SandboxSDK`

### Requirements

- iOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## Quick Start

```swift
import SandboxSDK

// 1. Initialize the sandbox
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

let success = applyManifest(features: [feature], policies: [
    "open_payment_page": policy
])

// 3. Evaluate and execute features
do {
    let decision = try SandboxSDK.evaluateFeature(
        "open_payment_page",
        args: ["amount": 100.0],
        context: ["user_present": true]
    )
    
    switch decision.status {
    case .allowed:
        // Execute your feature logic here
        openPaymentPage()
        // Record successful usage
        try SandboxSDK.recordUsage("open_payment_page")
        
    case .denied:
        showError("Access denied: \(decision.reason ?? "")")
        
    case .ask:
        // Request user consent
        requestUserConsent { granted in
            if granted {
                // Re-evaluate with consent
            }
        }
        
    case .rateLimited:
        showError("Rate limited. Try again later.")
    }
} catch {
    handleError(error)
}
```

## Core Concepts

### Policy Decision Pattern (PDP)

The sandbox uses a Policy Decision Point pattern where:

- **Sandbox** evaluates policies and returns decisions
- **Your app** acts as Policy Enforcement Point (PEP) and executes actions
- **Usage recording** happens after successful execution

### Feature → Capability → Primitive Hierarchy

- **Features**: High-level app capabilities ("open_payment_page")
- **Capabilities**: System permissions ("UIAccess", "Network")
- **Primitives**: Low-level operations ("MobileUI", "NetworkOp")

## API Reference

### Core APIs

#### Initialization

```swift
func initialize() -> Bool
```

Initialize the sandbox. Call once at app startup.

#### Feature Evaluation

```swift
func evaluateFeature(
    _ name: String,
    args: [String: Any] = [:],
    context: [String: Any]? = nil
) throws -> PolicyDecision
```

**Parameters:**

- `name`: Feature name to evaluate
- `args`: Feature-specific arguments
- `context`: Execution context (location, user state, etc.)

**Returns:** `PolicyDecision` with status and optional reason

#### Usage Recording

```swift
func recordUsage(_ name: String) throws -> OkResponse
```

Record successful feature usage for rate limiting and audit.

#### Feature Management

```swift
// Preferred typed APIs
func registerFeature(_ feature: Feature) -> Bool
func applyManifest(features: [Feature], policies: [String: Policy]) -> Bool
func setPolicies(_ policies: [String: Policy]) -> Bool

// Legacy dictionary-based APIs (still available)
func registerFeature(_ feature: [String: Any]) -> Bool
func applyManifest(_ manifest: [String: Any]) -> Bool
func setPolicies(_ policies: [String: Any]) -> Bool
```

#### Audit & Observability

```swift
func getAuditLog() throws -> [[String: Any]]
func clearAuditLog()
func updateResourceLimits(_ limits: [String: Any]) throws -> OkResponse
```

#### Performance Monitoring

```swift
func getPerformanceSummary() throws -> PerformanceSummary
func getPerformanceHistory() throws -> [ExecutionRecord]
func getResourceUsage() throws -> ResourceUsage
func getResourceLimits() throws -> ResourceLimits
```

#### Capability Management

```swift
func revokeCapability(_ capabilityId: String) throws -> OkResponse
func updateCapability(_ capabilityId: String, scope: CapabilityScope) throws -> OkResponse
```

### Data Types

#### PolicyDecision

```swift
struct PolicyDecision {
    let status: DecisionStatus  // .allowed, .denied, .ask, .rateLimited
    let reason: String?
    let reset_at: Int64?
}
```

#### PerformanceSummary

```swift
struct PerformanceSummary {
    let totalExecutions: UInt64
    let averageDuration: TimeInterval
    let successRate: Double
    let errorCount: UInt64
    let mostUsedPrimitives: [PrimitiveUsage]
    let recentAlerts: [PerformanceAlert]
}
```

#### PrimitiveUsage

```swift
struct PrimitiveUsage {
    let name: String
    let count: UInt64
}
```

## Advanced Usage

### Complex Feature Registration

```swift
let complexFeature: [String: Any] = [
    "name": "secure_payment_flow",
    "category": "Native",
    "path": "/payment/secure",
    "required_capabilities": ["UIAccess", "Network", "Camera"],
    "primitives": [
        [
            "type": "MobileUI",
            "page": "/payment/confirm"
        ],
        [
            "type": "CapturePhoto",
            "params": ["quality": "high", "facing": "front"]
        ],
        [
            "type": "NetworkOp",
            "url": "https://api.example.com/payment",
            "method": "POST",
            "headers": ["Content-Type": "application/json"]
        ]
    ]
]

SandboxSDK.registerFeature(complexFeature)
```

### Advanced Policy Configuration

```swift
let advancedPolicies: [String: Any] = [
    "secure_payment_flow": [
        "requires_user_present": true,
        "requires_explicit_consent": true,
        "sensitivity": "high",
        "rate_limit": [
            "unit": "day",
            "max": 10
        ]
    ]
]

SandboxSDK.setPolicies(advancedPolicies)
```

### Context-Aware Evaluation

```swift
let context: [String: Any] = [
    "location": "home",
    "user_state": [
        "user_present": true,
        "authenticated": true,
        "consent_given": true
    ],
    "device_status": [
        "battery_level": 80,
        "network_type": "wifi"
    ]
]

let decision = try SandboxSDK.evaluateFeature(
    "secure_payment_flow",
    args: ["amount": 500.0, "currency": "USD"],
    context: context
)
```

### Performance Monitoring Examples

```swift
// Get performance overview
let summary = try SandboxSDK.getPerformanceSummary()
print("Success rate: \(summary.successRate)")
print("Average duration: \(summary.averageDuration)s")

// Check for performance alerts
for alert in summary.recentAlerts {
    switch alert.alertType {
    case .highLatency:
        print("Warning: High latency detected")
    case .highMemoryUsage:
        print("Warning: Memory usage at \(alert.actualValue)MB")
    default:
        print("Alert: \(alert.message)")
    }
}

// Get detailed execution history
let history = try SandboxSDK.getPerformanceHistory()
for record in history.prefix(5) {
    print("\(record.featureName): \(record.duration)s, success: \(record.success)")
}
```

### Resource Management

```swift
// Check current resource usage
let usage = try SandboxSDK.getResourceUsage()
if usage.memoryUsedMb > 100 {
    print("High memory usage: \(usage.memoryUsedMb)MB")
}

// Update resource limits
try SandboxSDK.updateResourceLimits([
    "max_memory_mb": 128,
    "max_cpu_percent": 70,
    "max_network_calls": 100,
    "max_execution_time_secs": 30
])
```

### Dynamic Capability Management

```swift
// Temporarily restrict a capability
try SandboxSDK.updateCapability("Network", scope: .restricted)

// Revoke capability entirely
try SandboxSDK.revokeCapability("Camera")
```

## Error Handling

### Error Types

```swift
enum SandboxError: Error {
    case runtime(String)
}
```

### Best Practices

```swift
func executeFeatureSafely(_ featureName: String) {
    do {
        let decision = try SandboxSDK.evaluateFeature(featureName)
        
        switch decision.status {
        case .allowed:
            // Execute feature
            try SandboxSDK.recordUsage(featureName)
            
        case .denied:
            handleDeniedAccess(reason: decision.reason)
            
        case .rateLimited:
            handleRateLimit(resetAt: decision.reset_at)
            
        case .ask:
            requestUserConsent(message: decision.reason) { granted in
                if granted {
                    executeFeatureSafely(featureName)
                }
            }
        }
    } catch let error as SandboxError {
        switch error {
        case .runtime(let message):
            logError("Sandbox runtime error: \(message)")
            showUserFriendlyError()
        }
    } catch {
        logError("Unexpected error: \(error)")
        showUserFriendlyError()
    }
}
```

## Best Practices & Guidelines

### 1. Feature Design

- Use descriptive feature names
- Group related primitives in single features
- Define minimal required capabilities

### 2. Policy Configuration

- Start with restrictive policies and relax as needed
- Use rate limiting for sensitive operations
- Require user presence for critical actions

### 3. Performance Optimization

- Monitor performance metrics regularly
- Set appropriate resource limits
- Handle rate limiting gracefully

### 4. Security

- Always record usage after successful execution
- Use context-aware policies
- Regularly audit capability usage

### 5. Error Handling

- Provide user-friendly error messages
- Implement retry logic for transient failures
- Log errors for debugging

## Troubleshooting

### Common Issues

#### "Feature not found" Error

```swift
// Ensure feature is registered before evaluation
SandboxSDK.registerFeature(myFeature)
let decision = try SandboxSDK.evaluateFeature("my_feature")
```

#### Rate Limiting Issues

```swift
// Check rate limit configuration
let policies = ["my_feature": ["rate_limit": ["unit": "minute", "max": 5]]]
SandboxSDK.setPolicies(policies)
```

#### Permission Denied

```swift
// Verify required capabilities are available
// Check if capabilities were revoked
let decision = try SandboxSDK.evaluateFeature("my_feature")
if case .denied(let reason) = decision.status {
    print("Denied: \(reason)")
}
```

### Debug Mode

Enable detailed logging by setting environment variable:

```bash
SANDBOX_DEBUG=1
```

### Performance Issues

```swift
// Monitor performance regularly
let summary = try SandboxSDK.getPerformanceSummary()
if summary.averageDuration > 1.0 {
    print("Performance issue detected")
}
```

## Migration Guide

### From Previous Versions

When updating the SandboxSDK:

1. **Check API changes** in the changelog
2. **Update feature manifests** if schema changed
3. **Test policy configurations** with new version
4. **Update error handling** for new error types

### Breaking Changes

- v2.0: Removed direct execution APIs, now PDP-only
- v2.1: Added performance monitoring APIs
- v2.2: Enhanced capability management

## Support

For issues and questions:

- Check this documentation first
- Review sample app code in `ios-sandbox-sample/`
- File issues in the project repository
- Contact the development team
