import SwiftUI

struct AIExtractionProgressView: View {

    let stage: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 2) {
                Text("Processing Document")
                    .font(.headline)
                if !stage.isEmpty {
                    Text(stage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
