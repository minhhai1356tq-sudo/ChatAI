import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("baseURL") private var baseURL = GeminiConfig.defaultBaseURL
    @AppStorage("model") private var model = GeminiConfig.defaultModel
    @State private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("API key") {
                    SecureField("Dán API key vào đây", text: $apiKey)
                }

                Section {
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Endpoint")
                } footer: {
                    Text("Chỉ đổi khi cần. Mặc định là Gemini API.")
                }

                Section {
                    Button("Khôi phục mặc định", role: .destructive) {
                        baseURL = GeminiConfig.defaultBaseURL
                        model = GeminiConfig.defaultModel
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        KeychainStore.save(
                            apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                            account: "apiKey"
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKey = KeychainStore.load(account: "apiKey")
            }
        }
    }
}