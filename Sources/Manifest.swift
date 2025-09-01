import Foundation
import SandboxSDK

// Build and apply demo features + policies on app startup.
@discardableResult
func registerDemoFeatures() -> Bool {
    let features: [[String: Any]] = [
        [
            "name": "open_payment_page",
            "category": "Native",
            "path": "/payment",
            "required_capabilities": ["UIAccess"],
            "primitives": [
                ["type": "MobileUI", "page": "/payment"]
            ]
        ],
        [
            "name": "play_sound",
            "category": "Native",
            "path": "media://tone",
            "required_capabilities": ["AudioOutput"],
            "primitives": [
                ["type": "PlayAudio", "source": "media://tone", "volume": 80]
            ]
        ],
        [
            "name": "scan_ble",
            "category": "Native",
            "path": "bluetooth",
            "required_capabilities": ["Bluetooth"],
            "primitives": [
                ["type": "BluetoothScan"]
            ]
        ],
        [
            "name": "read_nfc",
            "category": "Native",
            "path": "nfc",
            "required_capabilities": ["NFC"],
            "primitives": [
                ["type": "NfcReadTag"]
            ]
        ],
        [
            "name": "exportPortfolioCSV",
            "category": "Native",
            "path": "/export",
            "required_capabilities": ["Network"],
            "primitives": [
                ["type": "NetworkOp", "url": "https://api.example.com/export", "method": "GET"]
            ]
        ],
        [
            "name": "limitedFeature",
            "category": "Native",
            "path": "/limited",
            "required_capabilities": ["UIAccess"],
            "primitives": [
                ["type": "ShowDialog", "title": "Hello", "message": "Rate-limited action"]
            ]
        ],
        [
            "name": "turn_on_light",
            "category": "Native",
            "path": "/iot/lights/on",
            "required_capabilities": ["DeviceControl"],
            "primitives": [
                ["type": "ShowDialog", "title": "Lights", "message": "Turning on living room light…"]
            ]
        ],
        [
            "name": "perform_payment",
            "category": "Native",
            "path": "/payment/confirm",
            "required_capabilities": ["UIAccess", "Network"],
            "primitives": [
                ["type": "ShowDialog", "title": "Confirm", "message": "Proceed with payment?"],
                ["type": "NetworkOp", "url": "https://api.example.com/pay", "method": "POST"]
            ]
        ],
        [
            "name": "navigateTo",
            "category": "Native",
            "path": "/navigate",
            "required_capabilities": ["UIAccess"],
            "primitives": [
                ["type": "MobileUI", "page": "/navigate"]
            ]
        ]
    ]

    let policies: [String: Any] = [
        "exportPortfolioCSV": [
            "requires_user_present": true,
            "requires_explicit_consent": true,
            "sensitivity": "high"
        ],
        "turn_on_light": [
            "rate_limit": ["unit": "day", "max": 3],
            "sensitivity": "low"
        ],
        "limitedFeature": [
            "rate_limit": ["unit": "minute", "max": 2],
            "sensitivity": "low"
        ],
        "navigateTo": [
            "requires_user_present": true,
            "rate_limit": ["unit": "minute", "max": 10],
            "sensitivity": "low"
        ]
    ]

    let manifest: [String: Any] = [
        "features": features,
        "policies": policies
    ]

    return SandboxSDK.applyManifest(manifest)
}
