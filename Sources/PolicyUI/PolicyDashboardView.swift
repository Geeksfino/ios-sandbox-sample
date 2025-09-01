import SwiftUI

struct PolicyDashboardView: View {
    @EnvironmentObject var store: PolicyStore
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Presets")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.presets, id: \._id) { preset in
                                Button(action: { store.apply(preset: preset) }) {
                                    Text(preset.name)
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(store.activePresetId == preset.id ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                }

                Section(header: Text("Features")) {
                    ForEach(store.featureIds, id: \.self) { fid in
                        if let cfg = store.policies[fid] {
                            NavigationLink(destination: PolicyEditorView(featureId: fid, initialConfig: cfg)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(fid).font(.subheadline)
                                        Text(summary(cfg: cfg)).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    statusPill(for: cfg)
                                }
                            }
                        } else {
                            NavigationLink(destination: PolicyEditorView(featureId: fid, initialConfig: PolicyConfig(featureId: fid))) {
                                Text(fid)
                            }
                        }
                    }
                }

                Section {
                    Button(action: { showingResetAlert = true }) {
                        Text("Reset Usage (Rate Limits)").foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Policies")
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset Counters"),
                    message: Text("Reset all rate limit counters?"),
                    primaryButton: .destructive(Text("Reset"), action: { RateLimiter.shared.resetAll() }),
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func summary(cfg: PolicyConfig) -> String {
        var parts: [String] = ["baseline=\(cfg.baseline.rawValue)"]
        if cfg.requireConfirmation { parts.append("confirm") }
        if let rl = cfg.rateLimit { parts.append("rl=\(rl.max)/\(rl.unit.rawValue)") }
        if let tw = cfg.timeWindow { parts.append("time=\(tw.startHour)-\(tw.endHour)") }
        return parts.joined(separator: " · ")
    }

    private func statusPill(for cfg: PolicyConfig) -> some View {
        let color: Color
        switch cfg.baseline {
        case .allow: color = .green
        case .ask: color = .orange
        case .deny: color = .red
        }
        return Text(cfg.baseline.title)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

private extension PolicyPreset { var _id: String { id } }
