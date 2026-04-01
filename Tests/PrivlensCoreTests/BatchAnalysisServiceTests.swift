import Foundation
import Testing
@testable import PrivlensCore

// MARK: - Thread-safe helper

private final class LockedArray<Element: Sendable>: @unchecked Sendable {
    private var storage: [Element] = []
    private let lock = NSLock()

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage.count
    }

    func append(_ element: Element) {
        lock.lock()
        storage.append(element)
        lock.unlock()
    }
}

// MARK: - Mock Services for Batch Tests

private final class MockBatchAnalysisCoordinator: AnalysisCoordinatorProtocol, Sendable {
    private let mockResult: AnalysisResult

    init(mockResult: AnalysisResult? = nil) {
        self.mockResult = mockResult ?? AnalysisResult(
            summary: "Test summary for document analysis",
            keyInsights: ["Key insight 1"],
            redFlags: ["Red flag at 123 Main St"],
            actionItems: ["Action item 1"],
            documentType: .lease
        )
    }

    func analyzeDocument(_ document: Document) async throws -> AnalysisResult {
        return mockResult
    }
}

private final class FailingBatchAnalysisCoordinator: AnalysisCoordinatorProtocol, Sendable {
    func analyzeDocument(_ document: Document) async throws -> AnalysisResult {
        throw AnalysisCoordinatorError.analysisServiceFailed("mock batch failure")
    }
}

private final class MockBatchPaywallService: PaywallServiceProtocol, Sendable {
    let currentTier: SubscriptionTier = .pro

    func canPerformAnalysis() async -> Bool { true }
    func recordAnalysis() async {}
    func remainingFreeAnalyses() async -> Int { Int.max }
}

// MARK: - BatchJob Model Tests

@Suite("BatchJob Model Tests")
struct BatchJobModelTests {

    @Test("BatchJob initializes with correct defaults")
    func batchJobDefaults() {
        let entries = [
            BatchDocumentEntry(documentId: UUID(), title: "Doc 1"),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 2"),
        ]
        let job = BatchJob(title: "Test Batch", entries: entries)

        #expect(job.status == .pending)
        #expect(job.entries.count == 2)
        #expect(job.processedCount == 0)
        #expect(job.progress == 0.0)
        #expect(job.successCount == 0)
        #expect(job.failedCount == 0)
        #expect(job.crossDocumentInsights.isEmpty)
    }

    @Test("BatchJob progress calculation works correctly")
    func progressCalculation() {
        var entries = [
            BatchDocumentEntry(documentId: UUID(), title: "Doc 1", status: .completed),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 2", status: .failed),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 3", status: .pending),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 4", status: .pending),
        ]

        let job = BatchJob(title: "Test", entries: entries)
        #expect(job.processedCount == 2)
        #expect(job.progress == 0.5)
        #expect(job.successCount == 1)
        #expect(job.failedCount == 1)

        entries[2].status = .completed
        entries[3].status = .completed
        let finishedJob = BatchJob(title: "Test", entries: entries)
        #expect(finishedJob.progress == 1.0)
    }

    @Test("BatchJob combined summary aggregates results")
    func combinedSummary() {
        let result1 = AnalysisResult(
            summary: "First doc summary",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .lease
        )
        let result2 = AnalysisResult(
            summary: "Second doc summary",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .insurance
        )

        let entries = [
            BatchDocumentEntry(documentId: UUID(), title: "Doc 1", status: .completed, result: result1),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 2", status: .completed, result: result2),
        ]

        let job = BatchJob(title: "Test", entries: entries)
        #expect(job.combinedSummary.contains("First doc summary"))
        #expect(job.combinedSummary.contains("Second doc summary"))
    }

    @Test("BatchJob aggregates red flags across documents")
    func allRedFlags() {
        let result1 = AnalysisResult(
            summary: "Summary 1",
            keyInsights: [],
            redFlags: ["Flag A", "Flag B"],
            actionItems: [],
            documentType: .lease
        )
        let result2 = AnalysisResult(
            summary: "Summary 2",
            keyInsights: [],
            redFlags: ["Flag C"],
            actionItems: [],
            documentType: .insurance
        )

        let entries = [
            BatchDocumentEntry(documentId: UUID(), title: "Doc 1", status: .completed, result: result1),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 2", status: .completed, result: result2),
            BatchDocumentEntry(documentId: UUID(), title: "Doc 3", status: .pending),
        ]

        let job = BatchJob(title: "Test", entries: entries)
        #expect(job.allRedFlags.count == 3)
    }

    @Test("Empty batch returns zero progress")
    func emptyBatchProgress() {
        let job = BatchJob(title: "Empty", entries: [])
        #expect(job.progress == 0.0)
        #expect(job.combinedSummary == "No analysis results available.")
    }
}

// MARK: - BatchAnalysisService Tests

@Suite("BatchAnalysisService Tests")
struct BatchAnalysisServiceTests {

    @Test("Batch analysis processes all documents successfully")
    func batchAnalysisSuccess() async throws {
        let coordinator = MockBatchAnalysisCoordinator()
        let service = BatchAnalysisService(analysisCoordinator: coordinator)

        let doc1 = Document(title: "Doc 1", rawText: "Document text 1")
        let doc2 = Document(title: "Doc 2", rawText: "Document text 2")

        let entries = [
            BatchDocumentEntry(documentId: doc1.id, title: doc1.title),
            BatchDocumentEntry(documentId: doc2.id, title: doc2.title),
        ]
        let job = BatchJob(title: "Test Batch", entries: entries)

        let progressUpdates = LockedArray<BatchProgress>()
        let result = try await service.analyzeBatch(job, documents: [doc1, doc2]) { progress in
            progressUpdates.append(progress)
        }

        #expect(result.status == .completed)
        #expect(result.successCount == 2)
        #expect(result.failedCount == 0)
        #expect(result.completedAt != nil)
        #expect(progressUpdates.count == 2)
    }

    @Test("Batch analysis handles document failures gracefully")
    func batchAnalysisWithFailures() async throws {
        let coordinator = FailingBatchAnalysisCoordinator()
        let service = BatchAnalysisService(analysisCoordinator: coordinator)

        let doc1 = Document(title: "Doc 1", rawText: "Text 1")
        let entries = [BatchDocumentEntry(documentId: doc1.id, title: doc1.title)]
        let job = BatchJob(title: "Failing Batch", entries: entries)

        let result = try await service.analyzeBatch(job, documents: [doc1]) { _ in }

        #expect(result.status == .failed)
        #expect(result.failedCount == 1)
        #expect(result.entries[0].errorMessage != nil)
    }

    @Test("Batch analysis throws on empty batch")
    func batchAnalysisEmptyBatch() async {
        let coordinator = MockBatchAnalysisCoordinator()
        let service = BatchAnalysisService(analysisCoordinator: coordinator)

        let job = BatchJob(title: "Empty", entries: [])

        do {
            _ = try await service.analyzeBatch(job, documents: []) { _ in }
            Issue.record("Expected error for empty batch")
        } catch {
            #expect(error is BatchAnalysisError)
        }
    }

    @Test("Batch analysis handles missing documents")
    func batchAnalysisMissingDocument() async throws {
        let coordinator = MockBatchAnalysisCoordinator()
        let service = BatchAnalysisService(analysisCoordinator: coordinator)

        let missingId = UUID()
        let entries = [BatchDocumentEntry(documentId: missingId, title: "Missing Doc")]
        let job = BatchJob(title: "Missing", entries: entries)

        let result = try await service.analyzeBatch(job, documents: []) { _ in }

        #expect(result.entries[0].status == .failed)
        #expect(result.entries[0].errorMessage == "Document not found")
    }
}

// MARK: - BatchDocumentEntry Tests

@Suite("BatchDocumentEntry Tests")
struct BatchDocumentEntryTests {

    @Test("BatchDocumentEntry initializes with pending status")
    func defaultStatus() {
        let entry = BatchDocumentEntry(documentId: UUID(), title: "Test")
        #expect(entry.status == .pending)
        #expect(entry.result == nil)
        #expect(entry.errorMessage == nil)
    }
}

// MARK: - CrossDocumentInsight Tests

@Suite("CrossDocumentInsight Tests")
struct CrossDocumentInsightTests {

    @Test("CrossDocumentInsight is Codable")
    func codable() throws {
        let insight = CrossDocumentInsight(
            description: "Shared address at 123 Main St",
            relatedDocumentIds: [UUID(), UUID()],
            relatedDocumentTitles: ["Doc A", "Doc B"],
            patternType: .sharedAddress
        )

        let data = try JSONEncoder().encode(insight)
        let decoded = try JSONDecoder().decode(CrossDocumentInsight.self, from: data)

        #expect(decoded.description == insight.description)
        #expect(decoded.patternType == .sharedAddress)
        #expect(decoded.relatedDocumentTitles.count == 2)
    }
}
