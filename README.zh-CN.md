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

或直接用 Xcode 打开该 Swift 包并构建。

## 更新内置 SDK（可选）

如果你本地也有 sandbox 源码，并希望刷新内置二进制：

1. 在 `sandbox/` 目录执行：

   ```bash
   make ios-sdk-xcframework MODE=release
   ```

   该命令会重新生成 `ios-sandbox-sample/Vendor/SandboxSDK.xcframework`。
2. 提交变更（Git LFS 会自动处理大文件）。

## 版本与发布

- 使用 Git Tag（如 `1.0.0`）作为 SPM 的版本解析依据。
- 更新 SDK 或 API 后，记得提升版本并推送 Tag。

## 许可证

待定（TBD）。
