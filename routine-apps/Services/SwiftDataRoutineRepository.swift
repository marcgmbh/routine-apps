import Foundation
import SwiftData

final class SwiftDataRoutineRepository: RoutineRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchRoutines() throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ routine: Routine) throws {
        context.insert(routine)
        try context.save()
    }

    func update(_ routine: Routine) throws {
        routine.updatedAt = .now
        try context.save()
    }

    func delete(_ routine: Routine) throws {
        context.delete(routine)
        try context.save()
    }
}
