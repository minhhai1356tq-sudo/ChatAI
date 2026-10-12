import Foundation

struct GeminiConfig {
    static let defaultBaseURL = "https://generativelanguage.googleapis.com/v1beta"
    static let defaultModel = "gemini-2.5-flash"

    var baseURL: String
    var model: String
    var apiKey: String
}

enum GeminiError: LocalizedError {
    case invalidURL
    case badStatus(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL API không hợp lệ."
        case .badStatus(let code, let body):
            return "Lỗi \(code): \(body)"
        case .emptyResponse:
            return "API không trả về nội dung."
        }
    }
}

// Request/response theo format của Gemini generateContent.
// Endpoint khác không cùng format (ví dụ OpenAI) sẽ không chạy được nếu chỉ đổi URL.
private struct GenerateRequest: Encodable {
    struct Content: Codable {
        let role: String
        let parts: [Part]
    }
    struct Part: Codable {
        let text: String
    }
    let contents: [Content]
}

private struct GenerateResponse: Decodable {
    struct Candidate: Decodable {
        let content: GenerateRequest.Content?
    }
    let candidates: [Candidate]?
}

struct GeminiClient {
    let config: GeminiConfig

    func send(history: [ChatMessage]) async throws -> String {
        let base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/models/\(config.model):generateContent") else {
            throw GeminiError.invalidURL
        }

        let body = GenerateRequest(contents: history.map { message in
            GenerateRequest.Content(
                role: message.role == .user ? "user" : "model",
                parts: [GenerateRequest.Part(text: message.text)]
            )
        })

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw GeminiError.badStatus(http.statusCode, String(decoding: data, as: UTF8.self))
        }

        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        let text = decoded.candidates?.first?.content?.parts.first?.text ?? ""
        guard !text.isEmpty else { throw GeminiError.emptyResponse }
        return text
    }
}