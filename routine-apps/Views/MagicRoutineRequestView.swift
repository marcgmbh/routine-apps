import SwiftUI

struct MagicRoutineRequestView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String = ""
    @State private var isBusy: Bool = false
    @State private var errorText: String?

    @State private var draft: RoutineDraft?
    @State private var navigate: Bool = false

    private let generator: RoutineGenerator

    init(generator: RoutineGenerator = OpenRouterRoutineGenerator(apiKeyProvider: {
        // Priority: Env vars (Xcode-launched only) -> Info.plist -> UserDefaults
        let env = ProcessInfo.processInfo.environment
        if let v = env["openrouter_api_key"] ?? env["openrouter_api"] ?? env["OPENROUTER_API_KEY"], !v.isEmpty {
            return v
        }
        if let plist = Bundle.main.infoDictionary {
            if let v = (plist["OPENROUTER_API_KEY"] as? String) ?? (plist["openrouter_api_key"] as? String), !v.isEmpty {
                return v
            }
        }
        if let v = UserDefaults.standard.string(forKey: "openrouter_api_key") ?? UserDefaults.standard.string(forKey: "OPENROUTER_API_KEY"), !v.isEmpty {
            return v
        }
        return nil
    })) {
        self.generator = generator
    }

    var body: some View {
        Form {
            Section("Describe your routine") {
                TextField("e.g. create 5 minute running stretches routine", text: $prompt)
                    .submitLabel(.go)
                    .onSubmit { Task { await run() } }
            }
            if let errorText { Text(errorText).foregroundStyle(.red) }
            Button {
                Task { await run() }
            } label: {
                if isBusy { ProgressView() } else { Text("Generate") }
            }
            .disabled(isBusy || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Magic Routine")
        .onChange(of: prompt) { _, _ in errorText = nil }
        .background(
            NavigationLink(isActive: $navigate) {
                AddRoutineView(draft: draft)
            } label: { EmptyView() }
            .hidden()
        )
    }

    private func run() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await generator.generate(prompt: prompt)
            await MainActor.run {
                self.draft = result
                self.navigate = true
            }
        } catch {
            await MainActor.run { self.errorText = error.localizedDescription }
        }
    }
}

#Preview { NavigationStack { MagicRoutineRequestView() } }
