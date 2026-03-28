import Foundation
import Testing
@testable import PrivlensCore

@Suite("AnalysisCache Tests")
struct AnalysisCacheTests {

    private func makeSampleResult(summary: String = "Test summary") -> AnalysisResult {
        AnalysisResult(
            summary: summary,
            keyInsights: ["Insight 1"],
            redFlags: ["Red flag 1"],
            actionItems: ["Action 1"],
            documentType: .lease
        )
    }

    // MARK: - Basic Cache Operations

    @Test("Cache miss returns nil")
    func cacheMissReturnsNil() {
        let cache = AnalysisCache()
        let result = cache.getCachedResult(for: "test text", documentType: .lease)
        #expect(result == nil)
    }

    @Test("Cache hit returns stored result")
    func cacheHitReturnsResult() {
        let cache = AnalysisCache()
        let expected = makeSampleResult()
        cache.cacheResult(expected, for: "test text", documentType: .lease)

        let retrieved = cache.getCachedResult(for: "test text", documentType: .lease)
        #expect(retrieved != nil)
        #expect(retrieved?.summary == "Test summary")
    }

    @Test("Different text produces cache miss")
    func differentTextMisses() {
        let cache = AnalysisCache()
        cache.cacheResult(makeSampleResult(), for: "text A", documentType: .lease)

        let result = cache.getCachedResult(for: "text B", documentType: .lease)
        #expect(result == nil)
    }

    @Test("Different document type produces cache miss")
    func differentTypeMisses() {
        let cache = AnalysisCache()
        cache.cacheResult(makeSampleResult(), for: "test text", documentType: .lease)

        let result = cache.getCachedResult(for: "test text", documentType: .medicalBill)
        #expect(result == nil)
    }

    @Test("Cache count reflects stored entries")
    func cacheCountIsCorrect() {
        let cache = AnalysisCache()
        #expect(cache.cacheCount == 0)

        cache.cacheResult(makeSampleResult(), for: "text 1", documentType: .lease)
        #expect(cache.cacheCount == 1)

        cache.cacheResult(makeSampleResult(), for: "text 2", documentType: .lease)
        #expect(cache.cacheCount == 2)
    }

    @Test("Clear cache removes all entries")
    func clearCacheRemovesAll() {
        let cache = AnalysisCache()
        cache.cacheResult(makeSampleResult(), for: "text 1", documentType: .lease)
        cache.cacheResult(makeSampleResult(), for: "text 2", documentType: .lease)

        cache.clearCache()
        #expect(cache.cacheCount == 0)
        #expect(cache.getCachedResult(for: "text 1", documentType: .lease) == nil)
    }

    // MARK: - Eviction

    @Test("Cache evicts oldest when over capacity")
    func evictsOldestWhenOverCapacity() {
        let cache = AnalysisCache(maxEntries: 3)

        cache.cacheResult(makeSampleResult(summary: "first"), for: "text 1", documentType: .lease)
        cache.cacheResult(makeSampleResult(summary: "second"), for: "text 2", documentType: .lease)
        cache.cacheResult(makeSampleResult(summary: "third"), for: "text 3", documentType: .lease)
        cache.cacheResult(makeSampleResult(summary: "fourth"), for: "text 4", documentType: .lease)

        #expect(cache.cacheCount == 3)
        // First entry should have been evicted
        #expect(cache.getCachedResult(for: "text 1", documentType: .lease) == nil)
        // Most recent entries should still be present
        #expect(cache.getCachedResult(for: "text 4", documentType: .lease)?.summary == "fourth")
    }

    // MARK: - Expiration

    @Test("Expired entries return nil")
    func expiredEntriesReturnNil() {
        // Create cache with 0-second max age (everything expires immediately)
        let cache = AnalysisCache(maxEntries: 50, maxAgeSeconds: 0)
        cache.cacheResult(makeSampleResult(), for: "test text", documentType: .lease)

        let result = cache.getCachedResult(for: "test text", documentType: .lease)
        #expect(result == nil)
    }

    // MARK: - Hash Computation

    @Test("Same input produces same hash")
    func sameInputSameHash() {
        let hash1 = AnalysisCache.computeHash(text: "test", documentType: .lease)
        let hash2 = AnalysisCache.computeHash(text: "test", documentType: .lease)
        #expect(hash1 == hash2)
    }

    @Test("Different input produces different hash")
    func differentInputDifferentHash() {
        let hash1 = AnalysisCache.computeHash(text: "text A", documentType: .lease)
        let hash2 = AnalysisCache.computeHash(text: "text B", documentType: .lease)
        #expect(hash1 != hash2)
    }

    @Test("Same text different type produces different hash")
    func sameTextDifferentTypeHash() {
        let hash1 = AnalysisCache.computeHash(text: "text", documentType: .lease)
        let hash2 = AnalysisCache.computeHash(text: "text", documentType: .medicalBill)
        #expect(hash1 != hash2)
    }

    // MARK: - Overwrite

    @Test("Re-caching same key updates the value")
    func reCachingUpdatesValue() {
        let cache = AnalysisCache()
        cache.cacheResult(makeSampleResult(summary: "old"), for: "text", documentType: .lease)
        cache.cacheResult(makeSampleResult(summary: "new"), for: "text", documentType: .lease)

        let result = cache.getCachedResult(for: "text", documentType: .lease)
        #expect(result?.summary == "new")
        #expect(cache.cacheCount == 1)
    }
}
