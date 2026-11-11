import Foundation
import SwiftData

/*--------------------------------known-kanji---------------------------------*/

extension SwiftDataLearnerStore {
    public func declareKnown(_ kanjiIDs: Set<String>, at date: Date) async throws {
        guard !kanjiIDs.isEmpty else { return }
        let context = modelExecutor.modelContext
        var rows = try progressRows(in: context)

        var marked = 0
        for id in kanjiIDs.sorted() {
            let row = Self.row(for: id, in: &rows, context: context)
            // Learning, familiar and known kanji already have progress that marking must not overwrite.
            guard row.stage == .new else { continue }
            Self.mark(row, at: date, byHand: true, position: marked)
            marked += 1
        }
        try context.save()
    }

    public func undeclareKnown(_ kanjiIDs: Set<String>) async throws {
        guard !kanjiIDs.isEmpty else { return }
        let context = modelExecutor.modelContext
        let declared = try context.fetch(declaredDescriptor())
        for row in declared where kanjiIDs.contains(row.kanjiID) {
            Self.unmark(row)
        }
        try context.save()
    }

    public func declaredKnownIDs() async throws -> Set<String> {
        Set(try modelExecutor.modelContext.fetch(declaredDescriptor()).map(\.kanjiID))
    }

    public func syncAutoKnown(_ kanjiIDs: Set<String>, at date: Date) async throws {
        let context = modelExecutor.modelContext
        var rows = try progressRows(in: context)

        for row in rows.values where row.declaredKnownAt != nil && !row.wasHandKnown && !kanjiIDs.contains(row.kanjiID) {
            Self.unmark(row)
        }
        var marked = 0
        for id in kanjiIDs.sorted() {
            let row = Self.row(for: id, in: &rows, context: context)
            guard row.stage == .new else { continue }
            Self.mark(row, at: date, byHand: false, position: marked)
            marked += 1
        }
        try context.save()
    }

    /*-------------------------------rows-----------------------------------*/

    private func progressRows(in context: ModelContext) throws -> [String: KanjiProgress] {
        let existing = try context.fetch(FetchDescriptor<KanjiProgress>())
        return Dictionary(existing.map { ($0.kanjiID, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func row(for id: String, in rows: inout [String: KanjiProgress], context: ModelContext) -> KanjiProgress {
        if let row = rows[id] { return row }
        let row = KanjiProgress(kanjiID: id)
        context.insert(row)
        rows[id] = row
        return row
    }

    /// A mark keeps the kanji out of Today but puts it in the review queue. Kanji marked together come due
    /// `marksPerDay` at a time starting today, so a learner finishing onboarding has reviews on day one
    /// and marking a whole level does not bury one day.
    static let marksPerDay = 10

    private static func mark(_ row: KanjiProgress, at date: Date, byHand: Bool, position: Int) {
        row.stage = .learning
        row.nextReviewAt = ReviewScheduler.dueDate(
            addingDays: position / marksPerDay,
            to: date,
            calendar: .current
        )
        row.declaredKnownAt = date
        row.wasHandKnown = byHand
    }

    private static func unmark(_ row: KanjiProgress) {
        row.stage = .new
        row.nextReviewAt = nil
        row.declaredKnownAt = nil
        row.wasHandKnown = true
    }

    private func declaredDescriptor() -> FetchDescriptor<KanjiProgress> {
        FetchDescriptor<KanjiProgress>(predicate: #Predicate { $0.declaredKnownAt != nil })
    }
}
