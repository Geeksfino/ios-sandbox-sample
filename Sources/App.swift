import SwiftUI
import SandboxSDK

@main
struct SandboxSampleApp: App {
    init() {
        _ = SandboxSDK.initialize()
        _ = registerDemoFeatures()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(PolicyStore())
        }
    }
}
