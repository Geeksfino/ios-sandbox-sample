import SwiftUI
import SandboxSDK

struct RateLimitDemoView: View {
    @State private var output: [String] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Rate Limits Demo")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Run x3") { runThrice() }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear Audit") { SandboxSDK.clearAuditLog(); output.removeAll() }
            }
        }
        .onAppear { output.removeAll() }
    }

    private func append(_ s: String) { output.append(s) }

    private func runOnce(_ i: Int) async {
        do {
            append("limitedFeature attempt #\(i)…")
            let decision = try SandboxSDK.evaluateFeature("limitedFeature", args: [:], context: nil)
            append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
            if decision.status == .allowed {
                append("[host] performing limited action… done")
                _ = try SandboxSDK.recordUsage("limitedFeature")
            }
        } catch {
            append("Exception: \(error)")
        }
    }

    private func runThrice() {
        Task {
            await runOnce(1)
            await runOnce(2)
            await runOnce(3)
        }
    }
}

#Preview { RateLimitDemoView() }
