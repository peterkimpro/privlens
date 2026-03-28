import Foundation

// MARK: - PerformanceMetric

/// A recorded performance measurement for a specific operation.
public struct PerformanceMetric: Codable, Sendable, Identifiable {
    public let id: UUID
    public let operation: String
    public let durationSeconds: Double
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        operation: String,
        durationSeconds: Double,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.operation = operation
        self.durationSeconds = durationSeconds
        self.timestamp = timestamp
        self.metadata = metadata
    }

    /// Human-readable formatted duration.
    public var formattedDuration: String {
        if durationSeconds < 1.0 {
            return String(format: "%.0fms", durationSeconds * 1000)
        } else {
            return String(format: "%.1fs", durationSeconds)
        }
    }
}

// MARK: - PerformanceMonitorProtocol

/// Protocol for performance measurement and tracking.
public protocol PerformanceMonitorProtocol: Sendable {
    /// Measures the duration of an async operation.
    func measure<T: Sendable>(
        operation: String,
        metadata: [String: String],
        body: @Sendable () async throws -> T
    ) async throws -> (result: T, metric: PerformanceMetric)

    /// Returns all recorded metrics.
    func getMetrics() -> [PerformanceMetric]

    /// Returns the average duration for a named operation.
    func averageDuration(for operation: String) -> Double?

    /// Clears all stored metrics.
    func clearMetrics()
}

// MARK: - PerformanceMonitor

/// Tracks and reports performance metrics for key operations.
public final class PerformanceMonitor: PerformanceMonitorProtocol, @unchecked Sendable {

    /// Maximum number of metrics to retain in memory.
    private let maxMetrics: Int
    private let lock = NSLock()
    private var metrics: [PerformanceMetric] = []

    public init(maxMetrics: Int = 500) {
        self.maxMetrics = maxMetrics
    }

    public func measure<T: Sendable>(
        operation: String,
        metadata: [String: String] = [:],
        body: @Sendable () async throws -> T
    ) async throws -> (result: T, metric: PerformanceMetric) {
        let start = ContinuousClock.now
        let result = try await body()
        let elapsed = start.duration(to: ContinuousClock.now)
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18

        let metric = PerformanceMetric(
            operation: operation,
            durationSeconds: seconds,
            metadata: metadata
        )
        recordMetric(metric)
        return (result, metric)
    }

    public func getMetrics() -> [PerformanceMetric] {
        getMetricsSync()
    }

    public func averageDuration(for operation: String) -> Double? {
        averageDurationSync(for: operation)
    }

    public func clearMetrics() {
        clearMetricsSync()
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func recordMetric(_ metric: PerformanceMetric) {
        lock.lock()
        defer { lock.unlock() }
        metrics.append(metric)
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
    }

    private func getMetricsSync() -> [PerformanceMetric] {
        lock.lock()
        defer { lock.unlock() }
        return metrics
    }

    private func averageDurationSync(for operation: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }
        let matching = metrics.filter { $0.operation == operation }
        guard !matching.isEmpty else { return nil }
        let total = matching.reduce(0.0) { $0 + $1.durationSeconds }
        return total / Double(matching.count)
    }

    private func clearMetricsSync() {
        lock.lock()
        defer { lock.unlock() }
        metrics.removeAll()
    }
}
