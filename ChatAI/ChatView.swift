import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, model }
    let id = UUID()
    let role: Role
    let text: String
}

struct ChatView: View {
    @AppStorage("baseURL") private var baseURL = GeminiConfig.defaultBaseURL
    @AppStorage("model") private var model = GeminiConfig.defaultModel

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isSending = false
    @State private var errorText: String?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isSending {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                if let errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                inputBar
            }
            .navigationTitle("ChatAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Nhập tin nhắn", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding()
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let apiKey = KeychainStore.load(account: "apiKey")
        guard !apiKey.isEmpty else {
            errorText = "Chưa có API key. Vào Cài đặt (biểu tượng bánh răng) để nhập."
            return
        }

        messages.append(ChatMessage(role: .user, text: text))
        input = ""
        errorText = nil
        isSending = true

        let client = GeminiClient(config: GeminiConfig(baseURL: baseURL, model: model, apiKey: apiKey))

        Task {
            do {
                let reply = try await client.send(history: messages)
                messages.append(ChatMessage(role: .model, text: reply))
            } catch {
                errorText = error.localizedDescription
            }
            isSending = false
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.text)
                .textSelection(.enabled)
                .padding(12)
                .background(
                    message.role == .user ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16)
                )

            if message.role == .model { Spacer(minLength: 40) }
        }
    }
}