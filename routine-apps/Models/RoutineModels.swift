import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RoutineStep.routine)
    var steps: [RoutineStep]

    init(id: UUID = UUID(),
         title: String,
         summary: String,
         steps: [RoutineStep] = [],
         createdAt: Date = .now,
         updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.summary = summary
        self.steps = steps.sorted(by: { $0.orderIndex < $1.orderIndex })
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var totalDurationSeconds: Int {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }
}

@Model
final class RoutineStep {
    @Attribute(.unique) var id: UUID
    var title: String
    var orderIndex: Int
    var durationSeconds: Int
    var instructionsMarkdown: String
    var videoURLString: String?
    var imageURLString: String?
    var isRemote: Bool

    @Relationship var routine: Routine?

    init(id: UUID = UUID(),
         title: String,
         orderIndex: Int,
         durationSeconds: Int,
         instructionsMarkdown: String,
         videoURL: URL? = nil,
         imageURL: URL? = nil,
         isRemote: Bool = false) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.durationSeconds = durationSeconds
        self.instructionsMarkdown = instructionsMarkdown
        self.videoURLString = videoURL?.absoluteString
        self.imageURLString = imageURL?.absoluteString
        self.isRemote = isRemote
    }

    var videoURL: URL? {
        get { videoURLString.flatMap(URL.init(string:)) }
        set { videoURLString = newValue?.absoluteString }
    }

    var imageURL: URL? {
        get { imageURLString.flatMap(URL.init(string:)) }
        set { imageURLString = newValue?.absoluteString }
    }
}
