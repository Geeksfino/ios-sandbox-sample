import SwiftUI
import SandboxSDK

struct GrantsDemoView: View {
    @EnvironmentObject var store: PolicyStore
    private let engine = PolicyEngine()
    @State private var userId: String = "alice"
    @State private var weekday: String = "Mon"
    @State private var hour: String = "19"
    @State private var location: String = "home"
    @State private var network: String = "WiFi"
    @State private var output: [String] = []
    @State private var showConfirm = false

    var body: some View {
        let policy = store.policies["turn_on_light"] ?? PolicyConfig(featureId: "turn_on_light")
        let context = DemoContext(userId: userId, location: location, date: Date(), amount: nil)
        let status = engine.evaluate(policy: policy, context: context)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                PolicyStatusCard(status: status)

                Text("Inputs").font(.caption).foregroundColor(.secondary)
                Group {
                    TextField("user_id", text: $userId)
                    TextField("weekday (Mon..Sun)", text: $weekday)
                    TextField("hour (0-23)", text: $hour)
                    TextField("location", text: $location)
                    TextField("network (WiFi/Cell)", text: $network)
                }
                .textFieldStyle(.roundedBorder)

                Button("Turn On Light (grants)") {
                    switch status {
                    case .denied, .rateLimited:
                        break
                    case .needsConfirmation:
                        showConfirm = true
                    case .allowed:
                        simulate()
                    }
                }
                .disabled({
                    if case .denied = status { return true }
                    if case .rateLimited = status { return true }
                    return false
                }())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                Text("Output").font(.caption).foregroundColor(.secondary)
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
                        Color.clear.frame(height: 1).id("BOTTOM")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .onChange(of: output.count) { _ in
                withAnimation { proxy.scrollTo("BOTTOM", anchor: .bottom) }
            }
        }
        .navigationTitle("Grants (Lights)")
        .alert(isPresented: $showConfirm) {
            Alert(
                title: Text("Confirm action"),
                message: Text("Requires user confirmation per policy"),
                primaryButton: .default(Text("Proceed"), action: { simulate() }),
                secondaryButton: .cancel()
            )
        }
    }

    private func append(_ s: String) { output.append(s) }

    private func simulate() {
        Task {
            do {
                let ctx: [String: Any] = [
                    "user_id": userId,
                    "user_state": [
                        "weekday": weekday,
                        "hour": Int(hour) ?? 0,
                        "location": location,
                        "network": network
                    ]
                ]
                append("turn_on_light… (context prepared)")
                let decision = try SandboxSDK.evaluateFeature(
                    "turn_on_light",
                    args: [:],
                    context: ctx
                )
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    append("[host] turning on light… done")
                    _ = try SandboxSDK.recordUsage("turn_on_light")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { GrantsDemoView() }
