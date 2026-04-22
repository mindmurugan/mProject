import SwiftUI

struct WarrantyStatusView: View {

    let warranty: WarrantyInfo

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(badgeColor)
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(badgeColor)
        }
    }

    private var statusIcon: String {
        switch warranty.expirationStatus {
        case .noWarranty: return "shield.slash"
        case .expired: return "shield.slash.fill"
        case .critical: return "shield.lefthalf.filled.badge.checkmark"
        case .warning: return "shield.righthalf.filled"
        case .valid: return "checkmark.shield.fill"
        }
    }

    private var badgeColor: Color {
        switch warranty.expirationStatus {
        case .noWarranty: return .gray
        case .expired: return .red
        case .critical: return .orange
        case .warning: return .yellow
        case .valid: return .green
        }
    }

    private var statusText: String {
        switch warranty.expirationStatus {
        case .noWarranty:
            return "No warranty recorded"
        case .expired:
            return "Warranty expired"
        case .critical:
            if let days = warranty.daysUntilExpiry {
                return "Expires in \(days) day\(days == 1 ? "" : "s")"
            }
            return "Expiring very soon"
        case .warning:
            if let days = warranty.daysUntilExpiry {
                return "Expires in \(days) days"
            }
            return "Expires soon"
        case .valid:
            if let days = warranty.daysUntilExpiry {
                return "\(days) days remaining"
            }
            return "Warranty active"
        }
    }
}
