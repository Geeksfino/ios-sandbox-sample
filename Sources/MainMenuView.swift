import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Audio Demo", destination: AudioDemoView())
                NavigationLink("Bluetooth Demo", destination: BluetoothDemoView())
                NavigationLink("NFC Demo", destination: NFCDemoView())
                NavigationLink("Network Export Demo", destination: NetworkDemoView())
                NavigationLink("Rate Limits & Resource Limits", destination: RateLimitDemoView())
                NavigationLink("Grants (Lights) Scenario", destination: GrantsDemoView())
                NavigationLink("Payment Demo", destination: PaymentDemoView())
            }
            .navigationTitle("Sandbox SDK Demos")
        }
    }
}

#Preview {
    MainMenuView()
}
