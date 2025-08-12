import Foundation
import SwiftUI

protocol ImageGenerator {
    func generateImage(prompt: String, size: CGSize) async throws -> URL  // returns a local file URL of the saved image
}

enum ImageGenError: Error { case badResponse, network, decoding, noURL }

final class FluxReplicateImageGenerator: ImageGenerator {
    // Configure your API key in app settings/secure storage and inject here.
    private let apiKeyProvider: () -> String?
    private let session: URLSession

    init(apiKeyProvider: @escaping () -> String?, session: URLSession = .shared) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    struct PredictionRequest: Encodable {
        let version: String?
        let input: Input
        struct Input: Encodable {
            let prompt: String
            let width: Int
            let height: Int
            // Optional knobs supported by many Replicate diffusion models
            let guidance: Double?
            let num_inference_steps: Int?
            let negative_prompt: String?
        }
    }

    struct PredictionResponse: Decodable {
        let id: String
        let status: String
        let output: [String]?
        let error: String?
    }

    func generateImage(prompt: String, size: CGSize) async throws -> URL {
        guard let key = apiKeyProvider() else { throw ImageGenError.network }
        let model = "black-forest-labs/flux-schnell"  // Replicate model slug
        let createURL = URL(string: "https://api.replicate.com/v1/models/\(model)/predictions")!
        let negative = "text, letters, watermark, logo, caption, diagram, UI, interface, typography, words, text overlay"
        let body = PredictionRequest(
            version: nil, // using the models endpoint; omit explicit version
            input: .init(
                prompt: prompt,
                width: Int(size.width),
                height: Int(size.height),
                guidance: 3.5,
                num_inference_steps: 4,
                negative_prompt: negative
            )
        )
        var req = URLRequest(url: createURL)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Token \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 300 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[Replicate] Create failed HTTP \(http.statusCode). Body=\n\(bodyText)")
            throw ImageGenError.badResponse
        }
        var pred = try JSONDecoder().decode(PredictionResponse.self, from: data)

        // Poll until completed
        while pred.status == "starting" || pred.status == "processing" || pred.status == "queued" {
            try await Task.sleep(nanoseconds: 700_000_000)
            let getURL = URL(string: "https://api.replicate.com/v1/predictions/\(pred.id)")!
            var getReq = URLRequest(url: getURL)
            getReq.addValue("Token \(key)", forHTTPHeaderField: "Authorization")
            let (gdata, gresp) = try await session.data(for: getReq)
            if let http = gresp as? HTTPURLResponse, http.statusCode >= 300 {
                let bodyText = String(data: gdata, encoding: .utf8) ?? "<non-utf8 body>"
                print("[Replicate] Poll failed HTTP \(http.statusCode). Body=\n\(bodyText)")
                throw ImageGenError.badResponse
            }
            pred = try JSONDecoder().decode(PredictionResponse.self, from: gdata)
        }
        guard pred.status == "succeeded", let urlStr = pred.output?.first,
            let remoteURL = URL(string: urlStr)
        else { throw ImageGenError.noURL }

        // Download image data and persist locally
        let (imgData, dresp) = try await session.data(from: remoteURL)
        guard (dresp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
            throw ImageGenError.badResponse
        }
        return try saveImageData(imgData)
    }

    private func saveImageData(_ data: Data) throws -> URL {
        let fm = FileManager.default
        let dir = try fm.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appendingPathComponent("Images", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let url = dir.appendingPathComponent(UUID().uuidString + ".png")
        try data.write(to: url)
        return url
    }
}
