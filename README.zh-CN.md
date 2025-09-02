# iOS Sandbox 示例应用 + 预编译 SDK

[English](README.md) | [中文](README.zh-CN.md)

本仓库包含：

- 示例应用源码（`Sources/`）
- 通过 Swift Package Manager 暴露的预编译 SDK（二进制）`Vendor/SandboxSDK.xcframework`

开发者可以开箱即用地编译示例应用；也可以在项目中通过 SPM 直接依赖该 SDK，而无需检出 sandbox 源码。

## 环境要求

- Xcode 15+
- iOS 14.0+（最低部署版本）
- Git LFS（用于获取 `xcframework` 二进制切片）

## 架构概览

```text
+-----------------------------------------------------------+
|                      App 如何采用Sandbox                    |
+-----------------------------------------------------------+
|  远程 Agent / LLM                                         |
|          |                                                 |
|          v                                                 |
|      [ 宿主应用 Host App ]                                 |
|          |                                                 |
|          v                                                 |
|      [ 沙箱 SDK Sandbox SDK ]                              |
|          |                                                 |
|   检查：功能 → 能力 → 策略                                 |
|          |                                                 |
|          v                                                 |
|    [ 策略引擎 Policy Engine ]                              |
|    - 上下文检查（时间、位置、同意）                        |
|    - 必要时用户确认                                        |
|          |                                                 |
|          v                                                 |
|   决策：允许 / 拒绝 / 需确认                               |
|          |                                                 |
|          v                                                 |
|    [ 适配器 / 原语 Adapter / Primitive ]                   |
|          |                                                 |
|          v                                                 |
|    [ 系统 API：相机 / 文件 / 网络 ]                        |
+-----------------------------------------------------------+
```

## 通过 SPM 引入 SDK

在你的项目中添加依赖（版本号按需替换）：

```swift
// Package.swift
.dependencies: [
    .package(url: "https://github.com/Geeksfino/ios-sandbox-sample.git", from: "1.0.0")
]
// 目标依赖
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SandboxSDK", package: "ios-sandbox-sample")
    ]
)
```

然后在代码中导入与使用：

```swift
import SandboxSDK

@main
struct MyApp: App {
    init() {
        _ = SandboxSDK.initialize()
    }
    // ... 其他代码
}

// 评估与记录使用
let decision = try SandboxSDK.evaluateFeature("perform_payment", args: ["amount": 100], context: nil)
if decision.status == .allowed {
    // 先执行宿主动作，然后记录使用（用于限流/审计）
    _ = try SandboxSDK.recordUsage("perform_payment")
}
```

可用的模块级 API（详见 `sandbox/ios/SandboxSDK/Sources/SandboxSDK/Sandbox.swift`）：

- `initialize() -> Bool`
- `evaluateFeature(_:args:context:) throws -> PolicyDecision`
- `recordUsage(_:) throws -> OkResponse`
- `getAuditLog() throws -> [[String: Any]]`
- `clearAuditLog()`
- `updateResourceLimits(_:) throws -> OkResponse`
- `applyManifest(_:) -> Bool`
- `registerFeature(_:) -> Bool`
- `setPolicies(_:) -> Bool`

## 构建示例应用

本仓库提供了 XcodeGen 的工程描述文件（`project.yml`）。通过 Xcode 构建：

1. 安装 XcodeGen：`brew install xcodegen`
2. 生成工程：`xcodegen generate`
3. 打开生成的 `.xcodeproj`，编译 `SandboxSampleApp` scheme

## 在独立项目中创建你自己的 iOS 应用

你可以在独立项目中通过 SPM 引入本 SDK，并用 XcodeGen 生成一个 iOS 应用目标。下面给出从零到可运行的最小步骤。

1. 前置条件

- Xcode 15+
- iOS 15.0+ 部署目标（若要使用 `confirmationDialog`、`.borderedProminent` 等较新的 SwiftUI API）
- XcodeGen（用于生成 iOS App 目标）

1. 创建目录结构

- 新建目录（例如 `sandbox-test/`），包含：
  - `Package.swift`（声明依赖本仓库并产出可执行目标）
  - `Sources/sandbox-test/`（SwiftUI 源码）
  - `project.yml`（XcodeGen 工程描述文件）

1. Package.swift 示例

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

说明：仅通过 SwiftPM 打开“可执行目标”默认会跑在 macOS 上，而 `SandboxSDK.xcframework` 仅包含 iOS 切片。因此需要使用 XcodeGen 生成 iOS App 目标后在 iOS 模拟器/设备上运行。

1. XcodeGen project.yml 示例

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

1. 最小 SwiftUI 集成

- App 启动时：调用 `SandboxSDK.initialize()`，随后 `SandboxSDK.applyManifest(...)`。
- 触发功能前：调用 `evaluateFeature(name)` 并根据返回的 `DecisionStatus` 分支处理。
- 完成实际动作后：调用 `recordUsage(name)`（用于限流与审计）。
- Swift 6 提示：对库枚举做 `switch` 时增加 `@unknown default:` 分支以保持前向兼容。

示例策略：

- `navigateToB` → 需要用户在场与显式同意（`requires_user_present`、`requires_explicit_consent`），进入 Ask 流程。
- `navigateToC` → 通过要求一个不存在/未满足的能力来实现拒绝（Denied）。

1. 生成与运行

- 安装 XcodeGen：`brew install xcodegen`
- 在你的项目目录执行：`xcodegen generate`
- 打开生成的 `.xcodeproj`，选择 iOS 15+ 模拟器，运行对应 scheme。

排错指南：

- 若出现 “While building for macOS, no library for this platform was found”，说明你使用了 SwiftPM 可执行目标直接在 macOS 上构建。请使用 XcodeGen 生成的 iOS App 目标并在 iOS 上运行。
- 若出现 `alert(...actions:message:)` / `confirmationDialog(...)` 的可用性报错，请将 iOS 部署版本提升到 15.0（见 `project.yml`）。
