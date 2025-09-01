import SwiftUI
import SandboxSDK

struct ContentView: View {
    @State private var output: [String] = []

    var body: some View {
        NavigationView {
            List(output, id: \.self) { line in
                Text(line).font(.system(.footnote, design: .monospaced))
            }
            .navigationTitle("Sandbox SDK Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run") { runAll() }
                }
            }
        }
        .onAppear { runInit() }
    }

    private func append(_ line: String) { output.append(line) }

    private func runInit() {
        append("Initializing sandbox…")
        _ = SandboxSDK.initialize()
        append("Initialized.")
    }

    private func runAll() {
        Task {
            do {
                append("\n1) evaluateFeature navigateTo")
                let dec1 = try SandboxSDK.evaluateFeature(
                    "navigateTo",
                    args: [:],
                    context: ["location": "sampleapp"]
                )
                append("decision=\(dec1.status.rawValue) reason=\(dec1.reason ?? "<nil>")")
                if dec1.status == .allowed {
                    append("[host] navigating to page… done")
                    _ = try SandboxSDK.recordUsage("navigateTo")
                }

                append("\n2) evaluateFeature exportPortfolioCSV")
                let dec2 = try SandboxSDK.evaluateFeature(
                    "exportPortfolioCSV",
                    args: [:],
                    context: nil
                )
                append("decision=\(dec2.status.rawValue) reason=\(dec2.reason ?? "<nil>")")
                if dec2.status == .allowed {
                    append("[host] exporting CSV… done")
                    _ = try SandboxSDK.recordUsage("exportPortfolioCSV")
                }

                append("\n3) getAuditLog")
                let audit = try SandboxSDK.getAuditLog()
                append("audit entries=\(audit.count)")

                append("\n4) clearAuditLog")
                SandboxSDK.clearAuditLog()
                append("audit cleared")

                append("\n5) updateResourceLimits")
                let res3 = try SandboxSDK.updateResourceLimits([
                    "max_memory_mb": 128,
                    "max_cpu_percent": 50
                ])
                append("ok=\(res3.ok)")
            } catch {
                append("Exception: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
