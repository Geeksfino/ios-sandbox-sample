# SandboxSDK for iOS - 完整开发者指南（中文）

## 目录

1. 安装与要求
2. 快速开始
3. 核心概念
4. API 参考
5. 进阶用法
6. 错误处理
7. 性能监控
8. 最佳实践
9. 故障排查
10. 迁移指南与支持

---

## 1. 安装与要求

### 使用 Swift Package Manager

在 `Package.swift` 中添加本地包：

```swift
dependencies: [
    .package(path: "../sandbox/ios/SandboxSDK")
]
```

或在 Xcode 中：File > Add Packages... > Add Local... 选择 `sandbox/ios/SandboxSDK`

### 运行要求

- iOS 13.0+
- Xcode 14.0+
- Swift 5.7+

---

## 2. 快速开始

```swift
import SandboxSDK

// 1) 初始化
SandboxSDK.initialize()

// 2) 使用强类型 API 注册特性与策略（推荐）
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
    // RateUnit 与 Rust 对齐：仅支持 .minute 与 .day
    rateLimit: SandboxSDK.RateLimit(unit: .minute, max: 5)
)

let success = applyManifest(features: [feature], policies: [
    "open_payment_page": policy
])

// 3) 评估并执行业务特性
 do {
    let decision = try SandboxSDK.evaluateFeature(
        "open_payment_page",
        args: ["amount": 100.0],
        context: ["user_present": true]
    )

    switch decision.status {
    case .allowed:
        // 执行业务
        openPaymentPage()
        // 成功后记录使用
        try SandboxSDK.recordUsage("open_payment_page")

    case .denied:
        showError("访问被拒绝: \(decision.reason ?? "")")

    case .ask:
        // 请求用户同意
        requestUserConsent { granted in
            if granted {
                // 重新评估
            }
        }

    case .rateLimited:
        showError("触发频控，请稍后重试")
    }
 } catch {
    handleError(error)
 }
```

---

## 3. 核心概念

### PDP（策略决策点）模式

- Sandbox 负责评估策略并返回决策（PolicyDecision）
- 你的 App 充当 PEP（策略执行点），根据决策执行或拒绝
- 成功执行之后再调用记录接口进行审计与限流统计

### Feature → Capability → Primitive 分层

- Feature（特性）：高层业务能力（如 `open_payment_page`）
- Capability（能力）：系统许可/权限（如 `UIAccess`, `Network`）
- Primitive（原语）：底层操作（如 `MobileUI`, `NetworkOp`）

---

## 4. API 参考

### 初始化

```swift
func initialize() -> Bool
```

### 特性评估

```swift
func evaluateFeature(
    _ name: String,
    args: [String: Any] = [:],
    context: [String: Any]? = nil
) throws -> PolicyDecision
```

- `name`: 特性名称
- `args`: 业务参数
- `context`: 上下文（如位置、用户状态）

返回 `PolicyDecision`：包含 `status` 与可选 `reason`

### 记录使用

```swift
func recordUsage(_ name: String) throws -> OkResponse
```

### 特性与策略管理

```swift
// 推荐的强类型 API
func registerFeature(_ feature: Feature) -> Bool
func applyManifest(features: [Feature], policies: [String: Policy]) -> Bool
func setPolicies(_ policies: [String: Policy]) -> Bool

// 兼容的字典 API（仍可用，但非首选）
func registerFeature(_ feature: [String: Any]) -> Bool
func applyManifest(_ manifest: [String: Any]) -> Bool
func setPolicies(_ policies: [String: Any]) -> Bool
```

### 审计与资源

```swift
func getAuditLog() throws -> [[String: Any]]
func clearAuditLog()
func updateResourceLimits(_ limits: [String: Any]) throws -> OkResponse
```

### 性能与资源监控

```swift
func getPerformanceSummary() throws -> PerformanceSummary
func getPerformanceHistory() throws -> [ExecutionRecord]
func getResourceUsage() throws -> ResourceUsage
func getResourceLimits() throws -> ResourceLimits
```

### 能力管理

```swift
func revokeCapability(_ capabilityId: String) throws -> OkResponse
func updateCapability(_ capabilityId: String, scope: CapabilityScope) throws -> OkResponse
```

### 数据类型（节选）

```swift
struct PolicyDecision {
    let status: DecisionStatus  // .allowed, .denied, .ask, .rateLimited
    let reason: String?
    let reset_at: Int64?
}

struct PerformanceSummary {
    let totalExecutions: UInt64
    let averageDuration: TimeInterval
    let successRate: Double
    let errorCount: UInt64
    let mostUsedPrimitives: [PrimitiveUsage]
    let recentAlerts: [PerformanceAlert]
}

struct PrimitiveUsage {
    let name: String
    let count: UInt64
}

// 强类型策略模型（新增）
struct Policy {
    let requiresUserPresent: Bool
    let requiresExplicitConsent: Bool
    let sensitivity: Sensitivity   // .low, .medium, .high
    let rateLimit: RateLimit?
}

enum Sensitivity: String { case low, medium, high }

struct RateLimit { let unit: RateUnit; let max: Int }

// 与 Rust 核心一致，仅支持以下单位：
enum RateUnit: String { case minute, day }
```

---

## 5. 进阶用法

- 复杂特性注册（多原语组合）
- 高级策略（敏感度、频控、用户在场/同意）
- 上下文感知评估（位置、网络、电量等）
- 性能历史与告警查看
- 资源使用与配额调整
- 动态能力调整/撤销

示例参考英文文档中的对应代码片段，API 一致。

---

## 6. 错误处理

```swift
enum SandboxError: Error {
    case runtime(String)
}
```

- 用用户可理解的信息提示
- 对临时错误做重试策略
- 记录日志方便排查

---

## 7. 性能监控

- 使用 `getPerformanceSummary()` 获取总体成功率、平均时延、错误数、常用原语、告警
- 使用 `getPerformanceHistory()` 获取执行明细（可抽样/分页展示）
- 使用 `getResourceUsage()`/`getResourceLimits()` 观察与配置资源

---

## 8. 最佳实践

- 采用最小权限原则配置能力
- 对敏感操作启用频控与用户在场/同意
- 每次成功执行后调用 `recordUsage`
- 定期查看性能与资源使用，及时调整策略

---

## 9. 故障排查

- “Feature not found”：确保先注册特性再评估
- 频控：检查策略中的 rate_limit 配置
- 权限拒绝：检查所需能力是否被限制/撤销
- 调试日志：设置环境变量 `SANDBOX_DEBUG=1`

---

## 10. 迁移与支持

- 升级前查看变更日志与破坏性变更
- 如有特性清单（manifest）变更，请同步更新
- 升级后回归策略评估与错误处理

支持：

- 优先阅读本文档与示例 `ios-sandbox-sample/`
- 在仓库提交 Issue 或联系开发团队
