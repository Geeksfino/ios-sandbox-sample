import Foundation
import SandboxSDK

final class PolicyEngine {
    private let rateLimiter: RateLimiter

    init(rateLimiter: RateLimiter = .shared) {
        self.rateLimiter = rateLimiter
    }

    func evaluate(policy: PolicyConfig, context: DemoContext, at date: Date = Date()) -> PermissionStatus {
        // Short-circuit: hard deny baseline
        if policy.baseline == .deny { return .denied(reason: "Policy baseline denies") }

        // Optional local checks that don't exist in SDK policy schema
        if !policy.allowedUsers.isEmpty {
            let ok = context.userId.map { policy.allowedUsers.contains($0) } ?? false
            if !ok { return .denied(reason: "User not allowed") }
        }
        if !policy.allowedLocations.isEmpty {
            let ok = context.location.map { policy.allowedLocations.contains($0) } ?? false
            if !ok { return .denied(reason: "Location not allowed") }
        }
        if let tw = policy.timeWindow {
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: date)
            if !tw.daysOfWeek.isEmpty && !tw.daysOfWeek.contains(weekday) { return .denied(reason: "Outside allowed days") }
            let hour = cal.component(.hour, from: date)
            if hour < tw.startHour || hour > tw.endHour { return .denied(reason: "Outside allowed hours") }
        }
        if policy.featureId == "perform_payment", let maxAmount = policy.constraints.payment?.maxAmount {
            if let amt = context.amount, amt > maxAmount { return .denied(reason: "Amount exceeds max \(Int(maxAmount))") }
        }

        // Build SDK args/context from DemoContext
        var args: [String: Any] = [:]
        if policy.featureId == "perform_payment", let amt = context.amount { args["amount"] = amt }
        var sdkContext: [String: Any]? = nil
        if context.userId != nil || context.location != nil {
            var userState: [String: Any] = [:]
            if let loc = context.location { userState["location"] = loc }
            var ctx: [String: Any] = [:]
            if let uid = context.userId { ctx["user_id"] = uid }
            if !userState.isEmpty { ctx["user_state"] = userState }
            if !ctx.isEmpty { sdkContext = ctx }
        }

        do {
            let decision = try SandboxSDK.evaluateFeature(policy.featureId, args: args, context: sdkContext)
            return mapDecision(decision.status, reason: decision.reason)
        } catch {
            return .denied(reason: "SDK error: \(error)")
        }
    }

    private func mapDecision(_ status: Any, reason: String?) -> PermissionStatus {
        let raw = String(describing: status).lowercased()
        if raw.contains("allow") { return .allowed }
        if raw.contains("confirm") || raw.contains("ask") { return .needsConfirmation(message: reason ?? "Requires user confirmation") }
        if raw.contains("rate") { return .rateLimited(resetAt: nil) }
        return .denied(reason: reason ?? "Denied")
    }
}

// Helper for RateLimiter result
extension RateLimiter {
    enum CheckResult {
        case ok
        case exceeded(resetAt: Date?)
    }
}
