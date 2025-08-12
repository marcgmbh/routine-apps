import Foundation
import Combine
import AVKit

@MainActor
final class RoutinePlayerViewModel: ObservableObject {
    enum State { case idle, playing, paused, finished }
    @Published var state: State = .idle
    @Published var currentIndex: Int = 0
    @Published var remainingInStep: TimeInterval = 0
    @Published var player: AVPlayer?

    let routine: Routine
    private let timeProvider: TimeProvider
    private let notifications: NotificationScheduler
    private let media: MediaLoader
    private let haptics: Haptics

    private var stepStartWallTime: Date?
    private var tickCancellable: AnyCancellable?

    init(routine: Routine,
         timeProvider: TimeProvider,
         notifications: NotificationScheduler,
         media: MediaLoader,
         haptics: Haptics) {
        self.routine = routine
        self.timeProvider = timeProvider
        self.notifications = notifications
        self.media = media
        self.haptics = haptics
        if !routine.steps.isEmpty { remainingInStep = TimeInterval(routine.steps[0].durationSeconds) }
    }

    func start() {
        guard !routine.steps.isEmpty else { state = .finished; return }
        state = .playing
        currentIndex = 0
        stepStartWallTime = timeProvider.now
        prepareMediaForCurrentStep()
        scheduleNextNotification()
        startTicking()
    }

    func pause() {
        state = .paused
        tickCancellable?.cancel()
        player?.pause()
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
        // Recompute start so remaining stays the same
        let duration = TimeInterval(routine.steps[currentIndex].durationSeconds)
        stepStartWallTime = timeProvider.now.addingTimeInterval(-(duration - remainingInStep))
        startTicking()
        player?.play()
    }

    func stop() {
        state = .idle
        tickCancellable?.cancel()
        player?.pause()
        Task { await notifications.clearPending(forRoutineID: routine.id) }
    }

    func appBecameActive() { recomputeRemainingFromWallClock() }

    private func startTicking() {
        tickCancellable?.cancel()
        tickCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        player?.play()
    }

    private func tick() {
        guard state == .playing, currentIndex < routine.steps.count else { return }
        recomputeRemainingFromWallClock()
        if remainingInStep <= 0.0 {
            advanceStep()
        } else if Int(remainingInStep) % 5 == 0 {
            haptics.stepTick()
        }
    }

    private func recomputeRemainingFromWallClock() {
        guard let stepStart = stepStartWallTime else { return }
        let elapsed = timeProvider.now.timeIntervalSince(stepStart)
        let duration = TimeInterval(routine.steps[currentIndex].durationSeconds)
        remainingInStep = max(0, duration - elapsed)
    }

    func advanceStep() {
        haptics.stepComplete()
        currentIndex += 1
        if currentIndex >= routine.steps.count {
            state = .finished
            Task { await notifications.clearPending(forRoutineID: routine.id) }
            player?.pause()
            return
        }
        stepStartWallTime = timeProvider.now
        remainingInStep = TimeInterval(routine.steps[currentIndex].durationSeconds)
        prepareMediaForCurrentStep()
        scheduleNextNotification()
    }

    private func prepareMediaForCurrentStep() {
        guard let url = routine.steps[currentIndex].videoURL else { player = nil; return }
        media.preload(url: url)
        player = media.makePlayer(url: url)
    }

    private func scheduleNextNotification() {
        guard let stepStart = stepStartWallTime else { return }
        let nextFire = stepStart.addingTimeInterval(TimeInterval(routine.steps[currentIndex].durationSeconds))
        Task {
            let nextTitle = nextStepTitle ?? "Done"
            let body = nextStepInstructionsPreview ?? ""
            try? await notifications.scheduleStepNotification(
                at: nextFire,
                title: "Next: \(nextTitle)",
                body: body,
                id: routine.id.uuidString
            )
        }
    }

    private var nextStepTitle: String? {
        let idx = currentIndex + 1
        return idx < routine.steps.count ? routine.steps[idx].title : nil
    }

    private var nextStepInstructionsPreview: String? {
        let idx = currentIndex + 1
        guard idx < routine.steps.count else { return nil }
        return String(routine.steps[idx].instructionsMarkdown.prefix(120))
    }
}
