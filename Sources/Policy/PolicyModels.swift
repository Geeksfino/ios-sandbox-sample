import Foundation
import SwiftUI

// MARK: - Core Models

enum BaselineMode: String, Codable, CaseIterable, Identifiable {
    case allow
    case ask
    case deny
    var id: String { rawValue }

    var title: String {
        switch self { case .allow: return "Allow"; case .ask: return "Ask"; case .deny: return "Deny" }
    }
}

enum RateUnit: String, Codable, CaseIterable, Identifiable {
    case minute
    case hour
    case day
    var id: String { rawValue }
}

struct RateLimit: Codable, Equatable {
    var unit: RateUnit
    var max: Int
}

struct TimeWindow: Codable, Equatable {
    // 1 = Sunday ... 7 = Saturday (aligns with Calendar.component(.weekday))
    var daysOfWeek: Set<Int> = []
    var startHour: Int = 0   // 0-23
    var endHour: Int = 23    // 0-23
}

struct PaymentConstraints: Codable, Equatable {
    var maxAmount: Double?
}

struct FeatureConstraints: Codable, Equatable {
    // Extend as needed per feature
    var payment: PaymentConstraints? = nil
}

struct PolicyConfig: Codable, Equatable, Identifiable {
    var id: String { featureId }
    let featureId: String

    // Baseline
    var baseline: BaselineMode = .allow
    var requireConfirmation: Bool = false

    // Constraints
    var rateLimit: RateLimit? = nil
    var timeWindow: TimeWindow? = nil
    var allowedUsers: [String] = [] // empty means no restriction
    var allowedLocations: [String] = [] // empty means no restriction

    // Feature-specific
    var constraints: FeatureConstraints = FeatureConstraints()
}

// MARK: - Status & Context

enum PermissionStatus: Equatable {
    case allowed
    case needsConfirmation(message: String)
    case rateLimited(resetAt: Date?)
    case denied(reason: String)
}

struct DemoContext: Equatable {
    var userId: String?
    var location: String?
    var date: Date = Date()

    // Optional feature-specific inputs
    var amount: Double? // for perform_payment
}

// MARK: - Presets

struct PolicyPreset: Identifiable {
    let id: String
    let name: String
    let apply: (inout [String: PolicyConfig]) -> Void
}

extension PolicyPreset {
    static func openPreset(featureIds: [String]) -> PolicyPreset {
        PolicyPreset(id: "open", name: "Open") { dict in
            for fid in featureIds {
                var cfg = dict[fid] ?? PolicyConfig(featureId: fid)
                cfg.baseline = .allow
                cfg.requireConfirmation = false
                cfg.rateLimit = nil
                dict[fid] = cfg
            }
        }
    }

    static func balancedPreset(featureIds: [String]) -> PolicyPreset {
        PolicyPreset(id: "balanced", name: "Balanced") { dict in
            for fid in featureIds {
                var cfg = dict[fid] ?? PolicyConfig(featureId: fid)
                if fid == "perform_payment" {
                    cfg.baseline = .ask
                    cfg.requireConfirmation = true
                    cfg.constraints.payment = .init(maxAmount: 100.0)
                } else {
                    cfg.baseline = .allow
                    cfg.requireConfirmation = false
                }
                cfg.rateLimit = RateLimit(unit: .minute, max: 10)
                dict[fid] = cfg
            }
        }
    }

    static func lockedDownPreset(featureIds: [String]) -> PolicyPreset {
        PolicyPreset(id: "locked", name: "Locked Down") { dict in
            for fid in featureIds {
                var cfg = dict[fid] ?? PolicyConfig(featureId: fid)
                cfg.baseline = .deny
                cfg.requireConfirmation = false
                cfg.rateLimit = nil
                dict[fid] = cfg
            }
        }
    }
}
