import SwiftUI
import SandboxSDK

struct NFCDemoView: View {
    @EnvironmentObject var store: PolicyStore
    private let engine = PolicyEngine()
    @State private var output: [String] = []
    @State private var showConfirm = false

    var body: some View {
        let policy = store.policies["read_nfc"] ?? PolicyConfig(featureId: "read_nfc")
        let context = DemoContext(userId: nil, location: nil, date: Date(), amount: nil)
        let status: PermissionStatus = engine.evaluate(policy: policy, context: context)

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                PolicyStatusCard(status: status)
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("NFC Demo")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Read Tag") {
                    switch status {
                    case .denied, .rateLimited: break
                    case .needsConfirmation: showConfirm = true
                    case .allowed: read()
                    }
                }
                .disabled({
                    if case .denied = status { return true }
                    if case .rateLimited = status { return true }
                    return false
                }())
            }
        }
        .onAppear { output.removeAll() }
        .alert(isPresented: $showConfirm) {
            Alert(
                title: Text("Confirm NFC read"),
                message: Text("Requires user confirmation per policy"),
                primaryButton: .default(Text("Proceed"), action: { read() }),
                secondaryButton: .cancel()
            )
        }
    }

    private func append(_ s: String) { output.append(s) }

    private func read() {
        Task {
            do {
                append("read_nfc…")
                let decision = try SandboxSDK.evaluateFeature("read_nfc", args: [:], context: nil)
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    append("[host] reading NFC… done")
                    _ = try SandboxSDK.recordUsage("read_nfc")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { NFCDemoView() }
