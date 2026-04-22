import SwiftUI

struct ExpirationBadgeView: View {

    let status: ExpirationStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .noWarranty: return .gray
        case .expired: return .red
        case .critical: return .orange
        case .warning: return .yellow
        case .valid: return .green
        }
    }
}
