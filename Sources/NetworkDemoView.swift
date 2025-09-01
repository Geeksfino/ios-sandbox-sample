import SwiftUI
import SandboxSDK

struct NetworkDemoView: View {
    @State private var output: [String] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(output, id: \.self) { Text($0).font(.system(.footnote, design: .monospaced)) }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Network Export Demo")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Export CSV") { exportCSV() }
            }
        }
        .onAppear { output.removeAll() }
    }

    private func append(_ s: String) { output.append(s) }

    private func exportCSV() {
        Task {
            do {
                append("exportPortfolioCSV…")
                let decision = try SandboxSDK.evaluateFeature("exportPortfolioCSV", args: [:], context: nil)
                append("decision=\(decision.status.rawValue) reason=\(decision.reason ?? "<nil>")")
                if decision.status == .allowed {
                    append("[host] exporting CSV… done")
                    _ = try SandboxSDK.recordUsage("exportPortfolioCSV")
                }
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview { NetworkDemoView() }
