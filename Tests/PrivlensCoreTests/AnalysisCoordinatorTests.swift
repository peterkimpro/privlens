import Foundation
import Testing
@testable import PrivlensCore

// MARK: - Mock Services

/// Mock AI analysis service that returns predetermined results.
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

/// Mock AI analysis service that always throws.
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

/// Mock storage service that stores results in memory.
private final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UUID: AnalysisResult] = [:]

    func saveAnalysisResult(_ result: AnalysisResult, for documentId: UUID) async throws {
        lock.lock()
        defer { lock.unlock() }
        storage[documentId] = result
    }

    func loadAnalysisResult(for documentId: UUID) async throws -> AnalysisResult? {
        lock.lock()
        defer { lock.unlock() }
        return storage[documentId]
    }

    func deleteAnalysisResult(for documentId: UUID) async throws {
        lock.lock()
        defer { lock.unlock() }
        storage[documentId] = nil
    }

    func getAnalysisCount() async throws -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storage.count
    }
}

/// Mock paywall service with configurable behavior.
private final class MockPaywallService: PaywallServiceProtocol, @unchecked Sendable {
    let currentTier: SubscriptionTier
    private let lock = NSLock()
    private var usageCount: Int
    private let limit: Int

    init(tier: SubscriptionTier = .free, usageCount: Int = 0, limit: Int = 3) {
        self.currentTier = tier
        self.usageCount = usageCount
        self.limit = limit
    }

    func canPerformAnalysis() async -> Bool {
        if currentTier == .pro { return true }
        lock.lock()
        defer { lock.unlock() }
        return usageCount < limit
    }

    func recordAnalysis() async {
        lock.lock()
        defer { lock.unlock() }
        usageCount += 1
    }

    func remainingFreeAnalyses() async -> Int {
        if currentTier == .pro { return Int.max }
        lock.lock()
        defer { lock.unlock() }
        return max(0, limit - usageCount)
    }
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

    @Test("Successful analysis saves result and records usage")
    func successfulAnalysis() async throws {
        let storageService = MockStorageService()
        let paywallService = MockPaywallService(tier: .free, usageCount: 0)
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: storageService,
            paywallService: paywallService
        )

        let document = makeDocument()
        let result = try await coordinator.analyzeDocument(document)

        #expect(result.summary == "Test summary")
        #expect(!result.keyInsights.isEmpty)
        #expect(result.keyInsights.first?.contains("Insight 1") == true)

        // Verify result was saved
        let savedResult = try await storageService.loadAnalysisResult(for: document.id)
        #expect(savedResult != nil)
        #expect(savedResult?.summary == "Test summary")

        // Verify usage was recorded
        let remaining = await paywallService.remainingFreeAnalyses()
        #expect(remaining == 2)
    }

    @Test("Analysis blocked when free limit reached")
    func paywallBlocksAnalysis() async {
        let paywallService = MockPaywallService(tier: .free, usageCount: 3, limit: 3)
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: MockStorageService(),
            paywallService: paywallService
        )

        let document = makeDocument()

        do {
            _ = try await coordinator.analyzeDocument(document)
            Issue.record("Expected analysis to throw when limit is reached")
        } catch let error as AnalysisCoordinatorError {
            if case .analysisLimitReached(let remaining) = error {
                #expect(remaining == 0)
            } else {
                Issue.record("Expected analysisLimitReached error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Pro tier allows unlimited analysis")
    func proTierUnlimited() async throws {
        let paywallService = MockPaywallService(tier: .pro, usageCount: 100)
        let coordinator = AnalysisCoordinator(
            chunkingService: ChunkingService(),
            aiAnalysisService: MockAIAnalysisService(),
            storageService: MockStorageService(),
            paywallService: paywallService
        )

        let document = makeDocument()
        let result = try await coordinator.analyzeDocument(document)

        #expect(result.summary == "Test summary")
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
        #expect(stages.count >= 4)
        // First stage should be checkingPaywall
        if case .checkingPaywall = stages[0] {} else {
            Issue.record("First stage should be checkingPaywall")
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
            // Expected — analysis service failed
        }
    }
}

// MARK: - Thread-Safe Helper

/// A thread-safe array for collecting values across async contexts.
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
