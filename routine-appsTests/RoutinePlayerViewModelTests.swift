import Foundation
import Testing
@testable import routine_apps

private struct FakeTime: TimeProvider {
    var base: Date
    var offset: TimeInterval = 0
    var now: Date { base.addingTimeInterval(offset) }
}

private struct NoopScheduler: NotificationScheduler {
    func requestAuthorization() async throws {}
    func scheduleStepNotification(at fireDate: Date, title: String, body: String, id: String) async throws {}
    func clearPending(forRoutineID id: UUID) async {}
}

private struct FakeMedia: MediaLoader {
    func makePlayer(url: URL) -> AVPlayer { AVPlayer() }
    func preload(url: URL) {}
}

private struct FakeHaptics: Haptics {
    func stepTick() {}
    func stepComplete() {}
}

struct RoutinePlayerViewModelTests {
    @Test mutating func countsDownUsingWallClock() async throws {
        var time = FakeTime(base: Date())
        let routine = Routine(title: "Test", summary: "",
                              steps: [RoutineStep(title: "A", orderIndex: 0, durationSeconds: 10, instructionsMarkdown: "")])
        let vm = await RoutinePlayerViewModel(
            routine: routine,
            timeProvider: time,
            notifications: NoopScheduler(),
            media: FakeMedia(),
            haptics: FakeHaptics()
        )
        await vm.start()
        // Advance 3 seconds
        time.offset = 3
        await vm.appBecameActive()
        #expect(Int(await vm.remainingInStep) <= 7 && Int(await vm.remainingInStep) >= 6)
    }
}
