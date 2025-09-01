import SwiftUI
import SandboxSDK

struct BluetoothDemoView: View {
    @EnvironmentObject var store: PolicyStore
    private let engine = PolicyEngine()
    @State private var output: [String] = []
    @State private var showConfirm = false

    var body: some View {
        let policy = store.policies["scan_ble"] ?? PolicyConfig(featureId: "scan_ble")
        let status = engine.evaluate(policy: policy, context: DemoContext(userId: nil, location: nil, date: Date(), amount: nil))

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                PolicyStatusCard(status: status)
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Bluetooth Demo")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Scan") {
                    switch status {
                    case .denied, .rateLimited: break
                    case .needsConfirmation: showConfirm = true
                    case .allowed: scan()
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
                title: Text("Confirm scan"),
                message: Text("Requires user confirmation per policy"),
                primaryButton: .default(Text("Proceed"), action: { scan() }),
                secondaryButton: .cancel()
            )
        }
    }

    private func append(_ s: String) { output.append(s) }

    private func scan() {
        Task {
            do {
                append("scan_ble…")
                let decision = try SandboxSDK.evaluateFeature("scan_ble", args: [:], context: nil)
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    append("[host] scanning BLE… done")
                    _ = try SandboxSDK.recordUsage("scan_ble")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { BluetoothDemoView() }
