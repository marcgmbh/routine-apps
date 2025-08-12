import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var vm = HomeViewModel()
    @State private var showingAdd = false
    @State private var showModePicker = false
    private enum AddMode: Identifiable { case custom, magic; var id: Int { self == .custom ? 0 : 1 } }
    @State private var addMode: AddMode? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.routines, id: \.id) { routine in
                    NavigationLink(destination: playerView(for: routine)) {
                        VStack(alignment: .leading) {
                            Text(routine.title).font(.headline)
                            Text(routine.summary).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(routine.totalDurationSeconds) sec • \(routine.steps.count) steps").font(.caption)
                        }
                    }
                }
                .onDelete { offsets in vm.delete(at: offsets, context: context) }
            }
            .navigationTitle("Routine")
            .onAppear { vm.load(context: context) }
            .overlay(alignment: .bottom) {
                Button(action: { showModePicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .accessibilityLabel("Add routine")
                }
                .padding(.bottom, 24)
            }
            .confirmationDialog("Add Routine", isPresented: $showModePicker) {
                Button("Custom") { addMode = .custom; showingAdd = true }
                Button("Magic ✨") { addMode = .magic;  showingAdd = true }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    switch addMode {
                    case .custom: AddRoutineView()
                    case .magic:  MagicRoutineRequestView()
                    case .none:   EmptyView()
                    }
                }
            }
            .onChange(of: showingAdd) { _, isPresented in
                if isPresented == false {
                    vm.load(context: context)
                }
            }
        }
    }

    private func playerView(for routine: Routine) -> some View {
        let vm = RoutinePlayerViewModel(
            routine: routine,
            timeProvider: SystemTimeProvider(),
            notifications: LocalNotificationScheduler(),
            media: DefaultMediaLoader(),
            haptics: NoopHaptics()
        )
        return RoutinePlayerView(vm: vm)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Routine.self, RoutineStep.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let r = Routine(title: "Demo", summary: "Sample", steps: [
            RoutineStep(title: "Warmup", orderIndex: 0, durationSeconds: 30, instructionsMarkdown: "Breathe"),
            RoutineStep(title: "Stretch", orderIndex: 1, durationSeconds: 45, instructionsMarkdown: "Arms up")
        ])
        context.insert(r)
        return HomeView().modelContainer(container)
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
