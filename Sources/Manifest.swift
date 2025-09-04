import Foundation
import SandboxSDK

// Build and apply demo features + policies on app startup using typed APIs.
@discardableResult
func registerDemoFeatures() -> Bool {
    let features: [Feature] = [
        Feature(
            name: "open_payment_page",
            category: .Native,
            path: "/payment",
            requiredCapabilities: [.UIAccess],
            primitives: [.MobileUI(page: "/payment", component: nil)]
        ),
        Feature(
            name: "play_sound",
            category: .Native,
            path: "media://tone",
            requiredCapabilities: [.AudioOutput],
            primitives: [.PlayAudio(source: "media://tone", volume: 80)]
        ),
        Feature(
            name: "scan_ble",
            category: .Native,
            path: "bluetooth",
            requiredCapabilities: [.Bluetooth],
            primitives: [.BluetoothScan]
        ),
        Feature(
            name: "read_nfc",
            category: .Native,
            path: "nfc",
            requiredCapabilities: [.NFC],
            primitives: [.NfcReadTag]
        ),
        Feature(
            name: "exportPortfolioCSV",
            category: .Native,
            path: "/export",
            requiredCapabilities: [.Network],
            primitives: [.NetworkOp(url: "https://api.example.com/export", method: "GET")]
        ),
        Feature(
            name: "limitedFeature",
            category: .Native,
            path: "/limited",
            requiredCapabilities: [.UIAccess],
            primitives: [.ShowDialog(title: "Hello", message: "Rate-limited action")]
        ),
        Feature(
            name: "turn_on_light",
            category: .Native,
            path: "/iot/lights/on",
            requiredCapabilities: [.DeviceControl],
            primitives: [.ShowDialog(title: "Lights", message: "Turning on living room light…")]
        ),
        Feature(
            name: "perform_payment",
            category: .Native,
            path: "/payment/confirm",
            requiredCapabilities: [.UIAccess, .Network],
            primitives: [
                .ShowDialog(title: "Confirm", message: "Proceed with payment?"),
                .NetworkOp(url: "https://api.example.com/pay", method: "POST")
            ]
        ),
        Feature(
            name: "navigateTo",
            category: .Native,
            path: "/navigate",
            requiredCapabilities: [.UIAccess],
            primitives: [.MobileUI(page: "/navigate", component: nil)]
        )
    ]

    let policies: [String: Policy] = [
        "exportPortfolioCSV": Policy(
            requiresUserPresent: true,
            requiresExplicitConsent: true,
            sensitivity: .high,
            rateLimit: nil
        ),
        "turn_on_light": Policy(
            requiresUserPresent: false,
            requiresExplicitConsent: false,
            sensitivity: .low,
            rateLimit: SandboxSDK.RateLimit(unit: SandboxSDK.RateUnit.day, max: 3)
        ),
        "limitedFeature": Policy(
            requiresUserPresent: false,
            requiresExplicitConsent: false,
            sensitivity: .low,
            rateLimit: SandboxSDK.RateLimit(unit: SandboxSDK.RateUnit.minute, max: 2)
        ),
        "navigateTo": Policy(
            requiresUserPresent: true,
            requiresExplicitConsent: false,
            sensitivity: .low,
            rateLimit: SandboxSDK.RateLimit(unit: SandboxSDK.RateUnit.minute, max: 10)
        )
    ]

    return applyManifest(features: features, policies: policies)
}
