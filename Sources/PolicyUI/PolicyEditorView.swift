import SwiftUI

struct PolicyEditorView: View {
    @EnvironmentObject var store: PolicyStore

    let featureId: String
    @State var cfg: PolicyConfig

    init(featureId: String, initialConfig: PolicyConfig) {
        self.featureId = featureId
        self._cfg = State(initialValue: initialConfig)
    }

    var body: some View {
        Form {
            Section(header: Text("Baseline")) {
                Picker("Decision", selection: $cfg.baseline) {
                    ForEach(BaselineMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Toggle("Require Confirmation", isOn: $cfg.requireConfirmation)
            }

            Section(header: Text("Rate Limit")) {
                Toggle("Enable", isOn: Binding(
                    get: { cfg.rateLimit != nil },
                    set: { on in cfg.rateLimit = on ? RateLimit(unit: .day, max: 1) : nil }
                ))
                if let _ = cfg.rateLimit {
                    Picker("Unit", selection: Binding(
                        get: { cfg.rateLimit?.unit ?? .day },
                        set: { unit in cfg.rateLimit?.unit = unit }
                    )) {
                        ForEach(RateUnit.allCases) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                    Stepper(value: Binding(
                        get: { cfg.rateLimit?.max ?? 1 },
                        set: { val in cfg.rateLimit?.max = max(1, val) }
                    ), in: 1...100) {
                        Text("Max per window: \(cfg.rateLimit?.max ?? 1)")
                    }
                }
            }

            Section(header: Text("Time Window")) {
                Stepper(value: Binding(get: { cfg.timeWindow?.startHour ?? 0 }, set: { v in
                    if cfg.timeWindow == nil { cfg.timeWindow = TimeWindow() }
                    cfg.timeWindow?.startHour = max(0, min(23, v))
                }), in: 0...23) { Text("Start Hour: \(cfg.timeWindow?.startHour ?? 0)") }

                Stepper(value: Binding(get: { cfg.timeWindow?.endHour ?? 23 }, set: { v in
                    if cfg.timeWindow == nil { cfg.timeWindow = TimeWindow() }
                    cfg.timeWindow?.endHour = max(0, min(23, v))
                }), in: 0...23) { Text("End Hour: \(cfg.timeWindow?.endHour ?? 23)") }

                Button(cfg.timeWindow == nil ? "Enable" : "Disable") {
                    cfg.timeWindow = (cfg.timeWindow == nil) ? TimeWindow() : nil
                }
            }

            Section(header: Text("Audience")) {
                TextField("Allowed Users (comma separated)", text: Binding(
                    get: { cfg.allowedUsers.joined(separator: ", ") },
                    set: { text in cfg.allowedUsers = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
                TextField("Allowed Locations (comma separated)", text: Binding(
                    get: { cfg.allowedLocations.joined(separator: ", ") },
                    set: { text in cfg.allowedLocations = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }

            if featureId == "perform_payment" {
                Section(header: Text("Payment")) {
                    TextField("Max Amount", text: Binding(
                        get: {
                            if let v = cfg.constraints.payment?.maxAmount {
                                return String(v)
                            } else { return "" }
                        },
                        set: { txt in
                            if cfg.constraints.payment == nil { cfg.constraints.payment = PaymentConstraints() }
                            cfg.constraints.payment?.maxAmount = Double(txt.replacingOccurrences(of: ",", with: "."))
                        }
                    ))
                    .keyboardType(.decimalPad)
                }
            }

            Section {
                Button("Save") { save() }
            }
        }
        .navigationTitle(featureId)
        .onDisappear { save() }
    }

    private func save() {
        var dict = store.policies
        dict[featureId] = cfg
        store.policies = dict
        store.save()
    }
}
