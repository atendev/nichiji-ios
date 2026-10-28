import Testing
import SwiftData
import Foundation
@testable import Nichiji

/*-----------------------------learner-tests------------------------------*/

@Suite("LearnerStore Tests")
struct LearnerStoreTests {
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            KanjiProgress.self,
            DailyAssignment.self,
            CustomKanjiSelection.self,
            StudyLogEntry.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    @Test("Learner models initialize cleanly in memory")
    func inMemoryContainerSetup() throws {
        let container = try makeInMemoryContainer()
        #expect(container.schema.entities.count == 4)
    }

    // TODO: Verify markLearned advances stage to .learning and records StudyLogEntry in Slice 3.
    // TODO: Verify forgetIt resets stage to .new and restores kanji to the unlearned pool in Slice 3.
    // TODO: Verify reassignToday swaps an unlearned assignment without modifying learned assignments in Slice 3.
}
