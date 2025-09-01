import Foundation

final class PolicyEngine {
    private let rateLimiter: RateLimiter

    init(rateLimiter: RateLimiter = .shared) {
        self.rateLimiter = rateLimiter
    }

    func evaluate(policy: PolicyConfig, context: DemoContext, at date: Date = Date()) -> PermissionStatus {
        // Audience checks
        if !policy.allowedUsers.isEmpty {
            let ok = context.userId.map { policy.allowedUsers.contains($0) } ?? false
            if !ok { return .denied(reason: "User not allowed") }
        }
        if !policy.allowedLocations.isEmpty {
            let ok = context.location.map { policy.allowedLocations.contains($0) } ?? false
            if !ok { return .denied(reason: "Location not allowed") }
        }

        // Time window (optional)
        if let tw = policy.timeWindow {
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: date)
            if !tw.daysOfWeek.isEmpty && !tw.daysOfWeek.contains(weekday) {
                return .denied(reason: "Outside allowed days")
            }
            let hour = cal.component(.hour, from: date)
            if hour < tw.startHour || hour > tw.endHour {
                return .denied(reason: "Outside allowed hours")
            }
        }

        // Feature-specific constraints (example: payment max amount)
        if policy.featureId == "perform_payment", let maxAmount = policy.constraints.payment?.maxAmount {
            if let amt = context.amount, amt > maxAmount {
                return .denied(reason: "Amount exceeds max \(Int(maxAmount))")
            }
        }

        // Baseline
        switch policy.baseline {
        case .deny:
            return .denied(reason: "Policy baseline denies")
        case .ask:
            // continue to rate-limit then ask
            break
        case .allow:
            break
        }

        // Rate limit
        if let rl = policy.rateLimit {
            let status = rateLimiter.status(featureId: policy.featureId, unit: rl.unit, max: rl.max, at: date)
            switch status {
            case .ok:
                break
            case .exceeded(let reset):
                return .rateLimited(resetAt: reset)
            }
        }

        // Ask confirmation if required
        if policy.baseline == .ask || policy.requireConfirmation {
            return .needsConfirmation(message: "Requires user confirmation")
        }

        return .allowed
    }
}

// Helper for RateLimiter result
extension RateLimiter {
    enum CheckResult {
        case ok
        case exceeded(resetAt: Date?)
    }
}
