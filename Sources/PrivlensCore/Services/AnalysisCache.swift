import Foundation

// MARK: - CacheEntry

/// A cached analysis result with metadata for expiration.
struct CacheEntry: Codable, Sendable {
    let result: AnalysisResult
    let textHash: String
    let cachedAt: Date
    let documentType: String

    var age: TimeInterval {
        Date().timeIntervalSince(cachedAt)
    }
}

// MARK: - AnalysisCacheProtocol

/// Protocol for caching analysis results to avoid redundant processing.
public protocol AnalysisCacheProtocol: Sendable {
    /// Returns a cached result if one exists for the given text content and document type.
    func getCachedResult(for text: String, documentType: DocumentType) -> AnalysisResult?

    /// Stores an analysis result in the cache.
    func cacheResult(_ result: AnalysisResult, for text: String, documentType: DocumentType)

    /// Removes all cached entries.
    func clearCache()

    /// Returns the current number of cached entries.
    var cacheCount: Int { get }
}

// MARK: - AnalysisCache

/// In-memory cache for analysis results, keyed by content hash.
/// Avoids re-analyzing identical document content.
public final class AnalysisCache: AnalysisCacheProtocol, @unchecked Sendable {

    /// Maximum number of entries to cache.
    private let maxEntries: Int

    /// Maximum age in seconds before a cache entry expires.
    private let maxAge: TimeInterval

    private let lock = NSLock()
    private var cache: [String: CacheEntry] = [:]

    /// Creates a new cache.
    /// - Parameters:
    ///   - maxEntries: Maximum number of cached results (default 50).
    ///   - maxAgeSeconds: Maximum age of cache entries in seconds (default 1 hour).
    public init(maxEntries: Int = 50, maxAgeSeconds: TimeInterval = 3600) {
        self.maxEntries = maxEntries
        self.maxAge = maxAgeSeconds
    }

    public func getCachedResult(for text: String, documentType: DocumentType) -> AnalysisResult? {
        getCachedResultSync(for: text, documentType: documentType)
    }

    public func cacheResult(_ result: AnalysisResult, for text: String, documentType: DocumentType) {
        cacheResultSync(result, for: text, documentType: documentType)
    }

    public func clearCache() {
        clearCacheSync()
    }

    public var cacheCount: Int {
        cacheCountSync()
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func getCachedResultSync(for text: String, documentType: DocumentType) -> AnalysisResult? {
        lock.lock()
        defer { lock.unlock() }

        let hash = Self.computeHash(text: text, documentType: documentType)
        guard let entry = cache[hash] else { return nil }

        // Check expiration
        if entry.age > maxAge {
            cache.removeValue(forKey: hash)
            return nil
        }

        return entry.result
    }

    private func cacheResultSync(_ result: AnalysisResult, for text: String, documentType: DocumentType) {
        lock.lock()
        defer { lock.unlock() }

        let hash = Self.computeHash(text: text, documentType: documentType)
        let entry = CacheEntry(
            result: result,
            textHash: hash,
            cachedAt: Date(),
            documentType: documentType.rawValue
        )
        cache[hash] = entry

        // Evict oldest entries if over capacity
        if cache.count > maxEntries {
            evictOldestEntries()
        }
    }

    private func clearCacheSync() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }

    private func cacheCountSync() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }

    private func evictOldestEntries() {
        // Already called under lock
        let sorted = cache.sorted { $0.value.cachedAt < $1.value.cachedAt }
        let toRemove = cache.count - maxEntries
        for (key, _) in sorted.prefix(toRemove) {
            cache.removeValue(forKey: key)
        }
    }

    // MARK: - Hashing

    /// Computes a simple content hash from the text and document type.
    /// Uses a deterministic hash suitable for cache key usage.
    static func computeHash(text: String, documentType: DocumentType) -> String {
        let combined = "\(documentType.rawValue)|\(text)"
        // Simple but deterministic hash using the built-in Hasher
        // We use a stable approach: prefix + length + sample characters
        let length = combined.count
        let prefix = String(combined.prefix(100))
        let suffix = String(combined.suffix(100))
        let middle: String
        if combined.count > 200 {
            let midStart = combined.index(combined.startIndex, offsetBy: combined.count / 2 - 50)
            let midEnd = combined.index(combined.startIndex, offsetBy: combined.count / 2 + 50)
            middle = String(combined[midStart..<midEnd])
        } else {
            middle = ""
        }
        return "\(length)_\(prefix.hashValue)_\(middle.hashValue)_\(suffix.hashValue)"
    }
}
