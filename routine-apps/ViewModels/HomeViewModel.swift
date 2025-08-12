import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var routines: [Routine] = []

    init() {}

    func load(context: ModelContext) {
        let repo = SwiftDataRoutineRepository(context: context)
        do { routines = try repo.fetchRoutines() } catch { routines = [] }
    }

    func delete(at offsets: IndexSet, context: ModelContext) {
        let repo = SwiftDataRoutineRepository(context: context)
        for index in offsets { try? repo.delete(routines[index]) }
        load(context: context)
    }
}
