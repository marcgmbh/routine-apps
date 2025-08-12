import SwiftUI
import AVKit

struct RoutinePlayerView: View {
@StateObject var vm: RoutinePlayerViewModel
@Environment(\.scenePhase) private var scenePhase

var body: some View {
VStack(spacing: 16) {
header
media
instructions
controls
progressBar
}
.padding()
.onChange(of: scenePhase) { _, newPhase in
if newPhase == .active { vm.appBecameActive() }
}
.onDisappear { vm.stop() }
}

@ViewBuilder
private var media: some View {
if let player = vm.player {
        VideoPlayer(player: player)
                .frame(height: 220)
            .cornerRadius(12)
        .accessibilityLabel("Step video")
} else if let url = currentStep.imageURL, let img = UIImage(contentsOfFile: url.path) {
Image(uiImage: img)
    .resizable()
.scaledToFit()
        .frame(height: 220)
            .cornerRadius(12)
                .accessibilityLabel("Step image")
    }
}

private var header: some View {
VStack(alignment: .leading) {
        Text(vm.routine.title).font(.title2).bold()
            Text("Step \(vm.currentIndex + 1) of \(vm.routine.steps.count)")
        Text(timeString(vm.remainingInStep)).monospacedDigit().font(.system(size: 36, weight: .semibold))
        .accessibilityLabel("Remaining \(Int(vm.remainingInStep)) seconds")
}
}

private var instructions: some View {
ScrollView {
Text(.init(currentStep.instructionsMarkdown))
.frame(maxWidth: .infinity, alignment: .leading)
}
}

private var controls: some View {
    HStack(spacing: 16) {
            Button("Back") { /* TODO: previous step or -5s */ }.disabled(vm.currentIndex == 0)
        if vm.state == .playing {
        Button("Pause") { vm.pause() }
} else if vm.state == .paused || vm.state == .idle {
            Button("Start") { vm.start() }
            } else {
            Button("Restart") { vm.start() }
            }
        Button("Skip") { vm.advanceStep() }
}
.buttonStyle(.borderedProminent)
}

private var progressBar: some View {
    ProgressView(value: routineProgress)
            .accessibilityLabel("Routine progress")
}

private var currentStep: RoutineStep { vm.routine.steps[vm.currentIndex] }

    private var routineProgress: Double {
        let completedBefore = vm.routine.steps.prefix(vm.currentIndex).reduce(0) { $0 + $1.durationSeconds }
        let total = vm.routine.totalDurationSeconds
    guard total > 0 else { return 0 }
let currentElapsed = Int(TimeInterval(currentStep.durationSeconds) - vm.remainingInStep)
return Double(completedBefore + max(0, currentElapsed)) / Double(total)
}

private func timeString(_ t: TimeInterval) -> String {
let s = Int(t.rounded(.up))
return String(format: "%02d:%02d", s/60, s%60)
}
}

#Preview {
    let r = Routine(title: "Demo", summary: "Sample", steps: [
        RoutineStep(title: "Warmup", orderIndex: 0, durationSeconds: 10, instructionsMarkdown: "Breathe"),
        RoutineStep(title: "Stretch", orderIndex: 1, durationSeconds: 10, instructionsMarkdown: "Arms up")
    ])
    let vm = RoutinePlayerViewModel(routine: r,
                                    timeProvider: SystemTimeProvider(),
                                    notifications: LocalNotificationScheduler(),
                                    media: DefaultMediaLoader(),
                                    haptics: NoopHaptics())
    return RoutinePlayerView(vm: vm)
}
