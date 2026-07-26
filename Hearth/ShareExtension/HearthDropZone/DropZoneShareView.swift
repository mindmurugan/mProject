import SwiftUI

/// Minimal confirmation screen shown in the share sheet itself. Deliberately
/// tiny -- the whole point of the Drop Zone is that you don't have to open
/// the app or make decisions in the moment; categorization happens later
/// from the Inbox tab.
struct DropZoneShareView: View {
    let onSave: () -> Void
    let onCancel: () -> Void
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("Add to Hearth")
                .font(.title3.weight(.semibold))

            Text("This will land in your shared Inbox for both of you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                isSaving = true
                onSave()
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Save to Hearth").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)

            Button("Cancel", role: .cancel, action: onCancel)
                .disabled(isSaving)
        }
        .padding(24)
        .background(.ultraThinMaterial)
    }
}
