import Foundation
import SwiftData

/*--------------------------------known-kanji---------------------------------*/

extension SwiftDataLearnerStore {
    public func declareKnown(_ kanjiIDs: Set<String>, at date: Date) async throws {
        guard !kanjiIDs.isEmpty else { return }
        let context = modelExecutor.modelContext
        let existing = try context.fetch(FetchDescriptor<KanjiProgress>())
        var rows = Dictionary(existing.map { ($0.kanjiID, $0) }, uniquingKeysWith: { first, _ in first })

        for id in kanjiIDs {
            let row = rows[id] ?? KanjiProgress(kanjiID: id)
            if rows[id] == nil {
                context.insert(row)
                rows[id] = row
            }
            // Learning, familiar and known kanji already have progress that marking must not overwrite.
            guard row.stage == .new else { continue }
            row.stage = .known
            row.nextReviewAt = nil
            row.declaredKnownAt = date
        }
        try context.save()
    }

    public func undeclareKnown(_ kanjiIDs: Set<String>) async throws {
        guard !kanjiIDs.isEmpty else { return }
        let context = modelExecutor.modelContext
        let declared = try context.fetch(declaredDescriptor())
        for row in declared where kanjiIDs.contains(row.kanjiID) {
            row.stage = .new
            row.nextReviewAt = nil
            row.declaredKnownAt = nil
        }
        try context.save()
    }

    public func declaredKnownIDs() async throws -> Set<String> {
        Set(try modelExecutor.modelContext.fetch(declaredDescriptor()).map(\.kanjiID))
    }

    private func declaredDescriptor() -> FetchDescriptor<KanjiProgress> {
        FetchDescriptor<KanjiProgress>(predicate: #Predicate { $0.declaredKnownAt != nil })
    }
}
