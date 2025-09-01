import SwiftUI
import SandboxSDK

struct PaymentDemoView: View {
    @EnvironmentObject var store: PolicyStore
    private let engine = PolicyEngine()
    @State private var amount: String = "19.99"
    @State private var note: String = "Test payment"
    @State private var output: [String] = []
    @State private var showConfirm = false

    var body: some View {
        let policy = store.policies["perform_payment"] ?? PolicyConfig(featureId: "perform_payment")
        let amt = Double(amount.replacingOccurrences(of: ",", with: "."))
        let context = DemoContext(userId: nil, location: nil, date: Date(), amount: amt)
        let status = engine.evaluate(policy: policy, context: context)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                PolicyStatusCard(status: status)
                Text("Inputs").font(.caption).foregroundColor(.secondary)
                Group {
                    TextField("amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("note", text: $note)
                }
                .textFieldStyle(.roundedBorder)

                Button("Simulate Payment") {
                    switch status {
                    case .denied, .rateLimited:
                        break
                    case .needsConfirmation:
                        showConfirm = true
                    case .allowed:
                        simulatePayment()
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            }
            .onChange(of: output.count) { _ in
                withAnimation { proxy.scrollTo("BOTTOM", anchor: .bottom) }
            }
        }
        .navigationTitle("Payment Demo")
        .onAppear { output.removeAll() }
        .alert(isPresented: $showConfirm) {
            Alert(
                title: Text("Confirm payment"),
                message: Text("Requires user confirmation per policy"),
                primaryButton: .default(Text("Proceed"), action: { simulatePayment() }),
                secondaryButton: .cancel()
            )
        }
    }

    private func append(_ s: String) { output.append(s) }

    private func simulatePayment() {
        Task {
            do {
                append("perform_payment…")
                let decision = try SandboxSDK.evaluateFeature(
                    "perform_payment",
                    args: ["amount": amount, "note": note],
                    context: nil
                )
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    append("[host] processing payment… done")
                    _ = try SandboxSDK.recordUsage("perform_payment")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { PaymentDemoView() }
