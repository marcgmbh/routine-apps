import SwiftUI
import SwiftData

struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var summary = ""
    @State private var steps: [RoutineStep] = []

    private let imageGenerator = FluxReplicateImageGenerator(apiKeyProvider: { ProcessInfo.processInfo.environment["REPLICATE_API_KEY"] })
    
    init(draft: RoutineDraft? = nil) {
        if let d = draft {
            _title = State(initialValue: d.title)
            _summary = State(initialValue: d.summary)
            _steps = State(initialValue: d.steps.enumerated().map { idx, s in
                RoutineStep(title: s.title, orderIndex: idx, durationSeconds: s.durationSeconds, instructionsMarkdown: s.instructionsMarkdown)
            })
        }
    }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Summary", text: $summary)
            }
            Section("Steps") {
                List {
                    ForEach(steps.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    TextField("Step title", text: Binding(
                                        get: { steps[i].title }, set: { steps[i].title = $0 }
                                    ))
                                    Stepper("Duration: \(steps[i].durationSeconds)s", value: Binding(
                                        get: { steps[i].durationSeconds }, set: { steps[i].durationSeconds = $0 }
                                    ), in: 5...3600, step: 5)
                                }
                                Spacer()
                                if let url = steps[i].imageURL, let img = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: img).resizable().scaledToFill().frame(width: 64, height: 64).clipped().cornerRadius(8)
                                }
                            }
                            TextField("Instructions (Markdown)", text: Binding(
                                get: { steps[i].instructionsMarkdown }, set: { steps[i].instructionsMarkdown = $0 }
                            ), axis: .vertical)
                            HStack {
                                Button("Generate Image with Flux") { Task { await generateImageForStep(i) } }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .onMove { from, to in steps.move(fromOffsets: from, toOffset: to); reindex() }
                    .onDelete { idx in steps.remove(atOffsets: idx); reindex() }
                    Button("Add Step") { steps.append(RoutineStep(title: "", orderIndex: steps.count, durationSeconds: 60, instructionsMarkdown: "")) }
                }
            }
            Button("Save") { save() }.disabled(title.isEmpty || steps.isEmpty)
        }
        .navigationTitle("New Routine")
        .toolbar { EditButton() }
    }

    private func reindex() { for (i, s) in steps.enumerated() { s.orderIndex = i } }

    private func save() {
        let routine = Routine(title: title, summary: summary, steps: steps)
        context.insert(routine)
        try? context.save()
        dismiss()
    }

    private func generateImageForStep(_ i: Int) async {
        let base = steps[i].instructionsMarkdown.isEmpty ? steps[i].title : steps[i].instructionsMarkdown
        let prompt = buildVisualPrompt(from: base)
        do {
            let url = try await imageGenerator.generateImage(prompt: prompt, size: CGSize(width: 768, height: 768))
            steps[i].imageURL = url
        } catch {
            print("Image generation failed: \(error)")
        }
    }

    private func buildVisualPrompt(from instruction: String) -> String {
        // Creative, non-literal, no text; photographic look with shallow focus
        let core = instruction
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let style = [
            "cinematic photograph",
            "documentary style, candid moment",
            "soft natural light, golden hour or overcast",
            "shallow depth of field, subject slightly out of focus",
            "subtle motion blur, sense of movement",
            "professional color grading, film grain",
            "off-center composition, leading lines, negative space",
            "no text, no letters, no typography, no logos"
        ].joined(separator: ", ")
        return "\(style). subject: \(core)."
    }
}

#Preview { AddRoutineView() }
