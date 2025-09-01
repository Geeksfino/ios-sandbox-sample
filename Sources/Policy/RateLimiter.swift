import Foundation

final class RateLimiter {
    static let shared = RateLimiter()

    private struct Key: Hashable { let featureId: String; let unit: RateUnit }
    private var counters: [Key: (windowStart: Date, count: Int)] = [:]
    private let queue = DispatchQueue(label: "RateLimiter.queue")

    func status(featureId: String, unit: RateUnit, max: Int, at date: Date) -> CheckResult {
        queue.sync {
            let key = Key(featureId: featureId, unit: unit)
            let start = windowStart(for: unit, at: date)
            if var entry = counters[key] {
                if !isSameWindow(unit: unit, lhs: entry.windowStart, rhs: start) {
                    entry = (windowStart: start, count: 0)
                }
                if entry.count >= max {
                    return .exceeded(resetAt: windowResetTime(for: unit, start: entry.windowStart))
                } else {
                    return .ok
                }
            } else {
                counters[key] = (windowStart: start, count: 0)
                return .ok
            }
        }
    }

    func recordUse(featureId: String, unit: RateUnit, at date: Date) {
        queue.sync {
            let key = Key(featureId: featureId, unit: unit)
            let start = windowStart(for: unit, at: date)
            if var entry = counters[key] {
                if !isSameWindow(unit: unit, lhs: entry.windowStart, rhs: start) {
                    entry = (windowStart: start, count: 0)
                }
                entry.count += 1
                counters[key] = entry
            } else {
                counters[key] = (windowStart: start, count: 1)
            }
        }
    }

    func resetAll() {
        queue.sync { counters.removeAll() }
    }

    // MARK: - Window helpers
    private func windowStart(for unit: RateUnit, at date: Date) -> Date {
        let cal = Calendar.current
        switch unit {
        case .minute:
            return cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)) ?? date
        case .hour:
            return cal.date(from: cal.dateComponents([.year, .month, .day, .hour], from: date)) ?? date
        case .day:
            return cal.startOfDay(for: date)
        }
    }

    private func windowResetTime(for unit: RateUnit, start: Date) -> Date {
        let cal = Calendar.current
        switch unit {
        case .minute: return cal.date(byAdding: .minute, value: 1, to: start) ?? start
        case .hour: return cal.date(byAdding: .hour, value: 1, to: start) ?? start
        case .day: return cal.date(byAdding: .day, value: 1, to: start) ?? start
        }
    }

    private func isSameWindow(unit: RateUnit, lhs: Date, rhs: Date) -> Bool {
        lhs == rhs
    }
}
