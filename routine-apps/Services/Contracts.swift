import Foundation
import AVKit

protocol RoutineRepository {
    func fetchRoutines() throws -> [Routine]
    func insert(_ routine: Routine) throws
    func update(_ routine: Routine) throws
    func delete(_ routine: Routine) throws
}

protocol TimeProvider { var now: Date { get } }
struct SystemTimeProvider: TimeProvider { var now: Date { Date() } }

protocol NotificationScheduler {
    func requestAuthorization() async throws
    func scheduleStepNotification(at fireDate: Date, title: String, body: String, id: String) async throws
    func clearPending(forRoutineID id: UUID) async
}

protocol MediaLoader {
    func makePlayer(url: URL) -> AVPlayer
    func preload(url: URL)
}

protocol Haptics {
    func stepTick()
    func stepComplete()
}

struct NoopHaptics: Haptics {
    func stepTick() {}
    func stepComplete() {}
}
