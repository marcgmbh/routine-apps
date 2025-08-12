import Foundation

// MARK: - Public Protocols & Models

protocol RoutineGenerator {
    func generate(prompt: String) async throws -> RoutineDraft
}

struct RoutineDraft: Decodable, Equatable {
    var title: String
    var summary: String
    var steps: [Step]

    struct Step: Decodable, Equatable {
        var title: String
        var durationSeconds: Int
        var instructionsMarkdown: String
    }
}

enum RoutineGenError: Error, LocalizedError {
    case noApiKey
    case badResponse
    case noContent
    case invalidJSON
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "OpenRouter API key missing. Set `openrouter_api_key` (or `openrouter_api` / `OPENROUTER_API_KEY`)."
        case .badResponse: return "The AI service returned an error. Please try again."
        case .noContent: return "No content returned. Please try again."
        case .invalidJSON: return "Could not parse AI response."
        case .validationFailed(let msg): return msg
        }
    }
}

extension RoutineDraft {
    func validated() throws -> Self {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RoutineGenError.validationFailed("Title is empty")
        }
        guard !steps.isEmpty else {
            throw RoutineGenError.validationFailed("No steps were generated")
        }
        guard steps.count <= 30 else {
            throw RoutineGenError.validationFailed("Too many steps (max 30)")
        }
        let okDurations = steps.allSatisfy { (5...3600).contains($0.durationSeconds) && $0.durationSeconds % 5 == 0 }
        guard okDurations else {
            throw RoutineGenError.validationFailed("Durations must be 5–3600 and multiples of 5")
        }
        return self
    }
}

// Optional convenience mapping into existing models
extension Routine {
    convenience init?(draft: RoutineDraft) {
        guard let v = try? draft.validated() else { return nil }
        let steps = v.steps.enumerated().map { i, s in
            RoutineStep(
                title: s.title,
                orderIndex: i,
                durationSeconds: s.durationSeconds,
                instructionsMarkdown: s.instructionsMarkdown,
                isRemote: true
            )
        }
        self.init(title: v.title, summary: v.summary, steps: steps)
    }
}

// MARK: - OpenRouter implementation

final class OpenRouterRoutineGenerator: RoutineGenerator {
    private let apiKeyProvider: () -> String?
    private let session: URLSession
    private let referer: String
    private let titleHeader: String

    init(apiKeyProvider: @escaping () -> String?,
         session: URLSession = .shared,
         referer: String = Bundle.main.bundleIdentifier ?? "dev.routines",
         titleHeader: String = "RoutineGen v1") {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
        self.referer = referer
        self.titleHeader = titleHeader
    }

    func generate(prompt: String) async throws -> RoutineDraft {
        guard let key = apiKeyProvider(), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("[OpenRouter] Missing API key. Set `openrouter_api_key`, `openrouter_api`, or `OPENROUTER_API_KEY` in the environment.")
            throw RoutineGenError.noApiKey
        }

        // Define strict instructions and schema to reduce decoding failures
        let schemaGuide = """
        Return ONLY a JSON object matching this schema:
        {
          "title": string,              // non-empty
          "summary": string,            // short description
          "steps": [
            {
              "title": string,          // non-empty
              "durationSeconds": number,// integer, multiples of 5, 5..3600
              "instructionsMarkdown": string
            }
          ]
        }
        No extra keys. No prose. No code fences.
        """

        let body: [String: Any] = [
            // Use a valid OpenRouter model ID (no "-json" suffix)
            "model": "openai/gpt-4o-mini",
            // Ask for a JSON object response
            "response_format": ["type": "json_object"],
            "stream": false,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": "You are a coach. \n\(schemaGuide)"],
                ["role": "user",   "content": prompt]
            ]
        ]

        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.addValue(referer, forHTTPHeaderField: "HTTP-Referer")
        req.addValue(titleHeader, forHTTPHeaderField: "X-Title")

        do {
            let (data, resp) = try await dataWithRetry(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
                let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                print("[OpenRouter] HTTP \(http.statusCode). Headers=\(http.allHeaderFields). Body=\n\(bodyText)")
                throw RoutineGenError.badResponse
            }

            struct Envelope: Decodable {
                struct Choice: Decodable {
                    struct Msg: Decodable { let content: String }
                    let message: Msg
                }
                let choices: [Choice]
            }
            let env = try JSONDecoder().decode(Envelope.self, from: data)
            guard let raw = env.choices.first?.message.content, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("[OpenRouter] No content in assistant message. Full response=\n\(String(data: data, encoding: .utf8) ?? "<non-utf8>")")
                throw RoutineGenError.noContent
            }

            let clean = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
            guard let jsonData = clean.data(using: .utf8) else { throw RoutineGenError.invalidJSON }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let draft = try decoder.decode(RoutineDraft.self, from: jsonData)
                return try draft.validated()
            } catch {
                print("[OpenRouter] JSON decode failed. Raw content=\n\(clean)\nError=\(error)")
                throw error
            }
        } catch {
            // Log networking / decoding errors for diagnostics
            print("[OpenRouter] Request failed: \(error)")
            throw error
        }
    }

    // Simple retry with exponential backoff + jitter
    private func dataWithRetry(for req: URLRequest, retries: Int = 3) async throws -> (Data, URLResponse) {
        var attempt = 0
        var lastError: Error?
        while attempt <= retries {
            do { return try await session.data(for: req) }
            catch {
                lastError = error
                let delay = pow(2.0, Double(attempt)) * 0.75 + Double.random(in: 0...0.25)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            }
        }
        throw lastError ?? URLError(.unknown)
    }
}
