import Foundation
import Testing
@testable import PrivlensCore

// MARK: - Mock Services

private final class MockAIAnalysisService: AIAnalysisServiceProtocol, Sendable {
    private let mockSummary: String
    private let mockInsights: [Insight]

    init(
        summary: String = "Test summary",
        insights: [Insight] = [
            Insight(
                title: "Insight 1",
                description: "Test insight description",
                category: .keyTerm,
                confidence: 0.8,
                sourceAttributions: []
            )
        ]
    ) {
        self.mockSummary = summary
        self.mockInsights = insights
    }

    func analyzeChunk(_ chunk: TextChunk, documentType: String?) async throws -> [Insight] {
        return mockInsights
    }

    func generateSummary(from insights: [Insight], documentContext: String?) async throws -> String {
        return mockSummary
    }

    func analyzeDocument(chunks: [TextChunk], documentType: String?) async throws -> AnalysisResult {
        var allInsights: [Insight] = []
        for chunk in chunks {
            let chunkInsights = try await analyzeChunk(chunk, documentType: documentType)
            allInsights.append(contentsOf: chunkInsights)
        }
        let summary = try await generateSummary(from: allInsights, documentContext: documentType)
        return AnalysisResult(
            summary: summary,
            keyInsights: allInsights.map { "\($0.title): \($0.description)" },
            redFlags: [],
            actionItems: [],
            documentType: .lease
        )
    }
}

private final class FailingAIAnalysisService: AIAnalysisServiceProtocol, Sendable {
    func analyzeChunk(_ chunk: TextChunk, documentType: String?) async throws -> [Insight] {
        throw AnalysisCoordinatorError.analysisServiceFailed("mock failure")
    }

    func generateSummary(from insights: [Insight], documentContext: String?) async throws -> String {
        throw AnalysisCoordinatorError.analysisServiceFailed("mock failure")
    }

    func analyzeDocument(chunks: [TextChunk], documentType: String?) async throws -> AnalysisResult {
        throw AnalysisCoordinatorError.analysisServiceFailed("mock failure")
    }
}

private final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UUID: AnalysisResult] = [:]

    private func saveSync(_ result: AnalysisResult, for documentId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        storage[documentId] = result
    }

    private func loadSync(for documentId: UUID) -> AnalysisResult? {
        lock.lock()
        defer { lock.unlock() }
        return storage[documentId]
    }

    private func deleteSync(for documentId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        storage[documentId] = nil
    }

    private func countSync() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storage.count
    }

    func saveAnalysisResult(_ result: AnalysisResult, for documentId: UUID) async throws {
        saveSync(result, for: documentId)
    }

    func loadAnalysisResult(for documentId: UUID) async throws -> AnalysisResult? {
        loadSync(for: documentId)
    }

    func deleteAnalysisResult(for documentId: UUID) async throws {
        deleteSync(for: documentId)
    }

    func getAnalysisCount() async throws -> Int {
        countSync()
    }
}

private final class MockPaywallService: PaywallServiceProtocol, Sendable {
    let currentTier: SubscriptionTier = .pro

    func canPerformAnalysis() async -> Bool { true }
    func recordAnalysis() async {}
    func remainingFreeAnalyses() async -> Int { Int.max }
}

// MARK: - Tests

@Suite("AnalysisCoordinator Tests")
struct AnalysisCoordinatorTests {

    private func makeDocument(
        id: UUID = UUID(),
        rawText: String = "This is a test document with enough text to analyze.",
        documentType: DocumentType = .lease
    ) -> Document {
        Document(
            id: id,
            title: "Test Document",
            rawText: rawText,
            documentType: documentType
        )
    }

    @Test("Successful analysis saves result")
    func successfulAnalysis() async throws {
        let storageService = MockStorageService()
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: storageService,
            paywallService: MockPaywallService()
        )

        let document = makeDocument()
        let result = try await coordinator.analyzeDocument(document)

        #expect(result.summary == "Test summary")
        #expect(!result.keyInsights.isEmpty)

        let savedResult = try await storageService.loadAnalysisResult(for: document.id)
        #expect(savedResult != nil)
        #expect(savedResult?.summary == "Test summary")
    }

    @Test("Empty document text throws error")
    func emptyDocumentText() async {
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: MockStorageService(),
            paywallService: MockPaywallService()
        )

        let document = makeDocument(rawText: "")

        do {
            _ = try await coordinator.analyzeDocument(document)
            Issue.record("Expected error for empty document text")
        } catch let error as AnalysisCoordinatorError {
            if case .emptyDocumentText = error {
                // Expected
            } else {
                Issue.record("Expected emptyDocumentText error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Progress callback is invoked in order")
    func progressCallbacks() async throws {
        let progressStages = LockedArray<AnalysisProgress>()

        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: MockStorageService(),
            paywallService: MockPaywallService(),
            onProgress: { stage in
                progressStages.append(stage)
            }
        )

        let document = makeDocument()
        _ = try await coordinator.analyzeDocument(document)

        let stages = progressStages.values
        #expect(stages.count >= 3)
        // First stage should be chunkingText
        if case .chunkingText = stages[0] {} else {
            Issue.record("First stage should be chunkingText")
        }
        // Last stage should be complete
        if case .complete = stages[stages.count - 1] {} else {
            Issue.record("Last stage should be complete")
        }
    }

    @Test("Analysis service failure propagates error")
    func analysisServiceFailure() async {
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: FailingAIAnalysisService(),
            storageService: MockStorageService(),
            paywallService: MockPaywallService()
        )

        let document = makeDocument()

        do {
            _ = try await coordinator.analyzeDocument(document)
            Issue.record("Expected analysis to throw")
        } catch {
            // Expected
        }
    }
}

// MARK: - Thread-Safe Helper

private final class LockedArray<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [Element] = []

    var values: [Element] {
        lock.lock()
        defer { lock.unlock() }
        return _values
    }

    func append(_ element: Element) {
        lock.lock()
        defer { lock.unlock() }
        _values.append(element)
    }
}
