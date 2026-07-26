import SwiftUI
import HearthKit

/// Small colored avatar chip used anywhere a `HouseholdMember` needs to be
/// shown compactly: task rows, board captions, itinerary segments.
struct MemberBadge: View {
    let member: HouseholdMember?
    let isUnassignedStyle: Bool

    init(member: HouseholdMember?) {
        self.member = member
        self.isUnassignedStyle = member == nil
    }

    var body: some View {
        Group {
            if let member {
                Image(systemName: member.systemIconName)
                    .foregroundStyle(Color(hex: member.colorHex))
                    .imageScale(.small)
            } else {
                Image(systemName: "person.crop.circle.dashed")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
            }
        }
        .frame(width: 22, height: 22)
        .background(.thinMaterial, in: Circle())
    }
}

extension Color {
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if hexValue.isEmpty { hexValue = "8E8E93" }
        var rgb: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
