import Foundation
import Combine

final class PolicyStore: ObservableObject {
    @Published var policies: [String: PolicyConfig] = [:]
    @Published var activePresetId: String? = nil

    private let persistenceURL: URL

    init() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        self.persistenceURL = docs.appendingPathComponent("policies.json")
        load()
        if policies.isEmpty {
            seedDefaults()
            save()
        }
    }

    // MARK: - Persistence
    func load() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoded = try JSONDecoder().decode([String: PolicyConfig].self, from: data)
            self.policies = decoded
        } catch {
            // ignore if not found
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(policies)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("PolicyStore save error: \(error)")
        }
    }

    // MARK: - Defaults / Presets
    var featureIds: [String] {
        // Keep in sync with Manifest.swift features for the demo
        [
            "open_payment_page",
            "play_sound",
            "scan_ble",
            "read_nfc",
            "exportPortfolioCSV",
            "limitedFeature",
            "turn_on_light",
            "perform_payment",
            "navigateTo"
        ]
    }

    func seedDefaults() {
        var dict: [String: PolicyConfig] = [:]
        for fid in featureIds {
            var cfg = PolicyConfig(featureId: fid)
            switch fid {
            case "perform_payment":
                cfg.baseline = .ask
                cfg.requireConfirmation = true
                cfg.constraints.payment = .init(maxAmount: 100)
            case "exportPortfolioCSV":
                cfg.baseline = .ask
                cfg.requireConfirmation = true
            default:
                cfg.baseline = .allow
            }
            dict[fid] = cfg
        }
        self.policies = dict
    }

    var presets: [PolicyPreset] {
        [
            .openPreset(featureIds: featureIds),
            .balancedPreset(featureIds: featureIds),
            .lockedDownPreset(featureIds: featureIds)
        ]
    }

    func apply(preset: PolicyPreset) {
        var dict = policies
        preset.apply(&dict)
        self.policies = dict
        self.activePresetId = preset.id
        save()
    }
}
