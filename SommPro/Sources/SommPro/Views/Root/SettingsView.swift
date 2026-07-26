import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = GeminiAPIKeyStore.load() ?? ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Gemini API key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("SommPro uses your own Gemini key (paid tier) to identify wines and write educational background from public information. Get a key at aistudio.google.com. Stored only in this device's Keychain.")
                }

                Section {
                    Button("Save") {
                        GeminiAPIKeyStore.save(apiKey)
                        saved = true
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !apiKey.isEmpty {
                        Button("Remove key", role: .destructive) {
                            GeminiAPIKeyStore.clear()
                            apiKey = ""
                        }
                    }
                }

                Section("About the ratings shown") {
                    Text("Vivino, CellarTracker, and James Suckling don't offer a free public rating API. SommPro makes a best-effort attempt to read publicly visible ratings from their search pages, and always falls back to a direct link to their site when that isn't possible. Treat any score shown here as approximate.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Saved", isPresented: $saved) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}
