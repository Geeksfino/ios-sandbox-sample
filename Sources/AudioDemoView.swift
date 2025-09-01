import SwiftUI
import SandboxSDK

struct AudioDemoView: View {
    @EnvironmentObject var store: PolicyStore
    private let engine = PolicyEngine()
    @State private var output: [String] = []
    @State private var showConfirm = false

    var body: some View {
        let policy = store.policies["play_sound"] ?? PolicyConfig(featureId: "play_sound")
        let context = DemoContext(userId: nil, location: nil, date: Date(), amount: nil)
        let status: PermissionStatus = engine.evaluate(policy: policy, context: context)

        SwiftUI.ScrollView(.vertical, showsIndicators: true) {
            SwiftUI.VStack(alignment: .leading, spacing: CGFloat(10)) {
                PolicyStatusCard(status: status)
                SwiftUI.VStack(alignment: .leading, spacing: CGFloat(6)) {
                    ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Audio Demo")
        .navigationBarItems(trailing:
            Button("Play") {
                switch status {
                case .denied, .rateLimited: break
                case .needsConfirmation: showConfirm = true
                case .allowed: play()
                }
            }
            .disabled({
                if case .denied = status { return true }
                if case .rateLimited = status { return true }
                return false
            }())
        )
        .onAppear {
            output.removeAll()
            // Dynamically register feature and policies for this demo
            let okF = SandboxSDK.registerFeature([
                "name": "play_sound",
                "category": "Native",
                "path": "/audio/play",
                "required_capabilities": ["AudioOutput"],
                "primitives": [
                    ["type": "PlayAudio", "source": "ding", "volume": 100]
                ]
            ])
            let okP = SandboxSDK.setPolicies([
                "play_sound": [
                    "requires_user_present": false,
                    "requires_explicit_consent": false,
                    "rate_limit": ["unit": "minute", "max": 20],
                    "sensitivity": "low"
                ]
            ])
            if !okF || !okP { output.append("Failed to register feature/policies") }
        }
        .alert(isPresented: $showConfirm) {
            Alert(
                title: Text("Confirm playback"),
                message: Text("Requires user confirmation per policy"),
                primaryButton: .default(Text("Proceed"), action: { play() }),
                secondaryButton: .cancel()
            )
        }
    }

    private func append(_ s: String) { output.append(s) }

    private func play() {
        Task {
            do {
                append("play_sound…")
                let decision = try SandboxSDK.evaluateFeature("play_sound", args: [:], context: nil)
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    // Simulate host-side action, then record usage for rate limiting/audit
                    append("[host] playing sound… done")
                    _ = try SandboxSDK.recordUsage("play_sound")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { AudioDemoView() }
