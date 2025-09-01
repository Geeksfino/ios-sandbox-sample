import SwiftUI

struct PolicyStatusCard: View {
    let status: PermissionStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).bold().foregroundColor(color)
                if let reason = reason { Text(reason).font(.caption).foregroundColor(.secondary) }
            }
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    private var title: String {
        switch status {
        case .allowed: return "Allowed"
        case .needsConfirmation: return "Needs Confirmation"
        case .rateLimited: return "Rate Limited"
        case .denied: return "Denied"
        }
    }

    private var reason: String? {
        switch status {
        case .needsConfirmation(let msg): return msg
        case .rateLimited:
            return "Rate limit active"
        case .denied(let why): return why
        case .allowed: return nil
        }
    }

    private var color: Color {
        switch status {
        case .allowed: return .green
        case .needsConfirmation: return .orange
        case .rateLimited: return .blue
        case .denied: return .red
        }
    }
}
