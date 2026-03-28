import Foundation
import Testing
@testable import PrivlensCore

@Suite("PerformanceMonitor Tests")
struct PerformanceMonitorTests {

    @Test("Measure records a metric")
    func measureRecordsMetric() async throws {
        let monitor = PerformanceMonitor()

        let (result, metric) = try await monitor.measure(operation: "test_op") {
            return 42
        }

        #expect(result == 42)
        #expect(metric.operation == "test_op")
        #expect(metric.durationSeconds >= 0)
        #expect(monitor.getMetrics().count == 1)
    }

    @Test("Measure propagates errors")
    func measurePropagatesErrors() async {
        let monitor = PerformanceMonitor()

        do {
            _ = try await monitor.measure(operation: "failing") { () -> Int in
                throw TestError.intentional
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    @Test("Multiple measurements are tracked")
    func multipleMetricsTracked() async throws {
        let monitor = PerformanceMonitor()

        _ = try await monitor.measure(operation: "op1") { 1 }
        _ = try await monitor.measure(operation: "op2") { 2 }
        _ = try await monitor.measure(operation: "op1") { 3 }

        #expect(monitor.getMetrics().count == 3)
    }

    @Test("Average duration calculation")
    func averageDuration() async throws {
        let monitor = PerformanceMonitor()

        // Measure a few quick operations
        _ = try await monitor.measure(operation: "fast") { 1 }
        _ = try await monitor.measure(operation: "fast") { 2 }

        let avg = monitor.averageDuration(for: "fast")
        #expect(avg != nil)
        #expect(avg! >= 0)
    }

    @Test("Average duration for unknown operation returns nil")
    func averageDurationUnknownOperation() {
        let monitor = PerformanceMonitor()
        #expect(monitor.averageDuration(for: "nonexistent") == nil)
    }

    @Test("Clear removes all metrics")
    func clearRemovesAll() async throws {
        let monitor = PerformanceMonitor()
        _ = try await monitor.measure(operation: "op") { 1 }
        #expect(monitor.getMetrics().count == 1)

        monitor.clearMetrics()
        #expect(monitor.getMetrics().isEmpty)
    }

    @Test("Eviction keeps only maxMetrics entries")
    func evictionKeepsMaxEntries() async throws {
        let monitor = PerformanceMonitor(maxMetrics: 3)

        for i in 0..<5 {
            _ = try await monitor.measure(operation: "op\(i)") { i }
        }

        #expect(monitor.getMetrics().count == 3)
    }

    @Test("Metric formatted duration shows milliseconds for fast ops")
    func formattedDurationMilliseconds() {
        let metric = PerformanceMetric(
            operation: "fast",
            durationSeconds: 0.045
        )
        #expect(metric.formattedDuration == "45ms")
    }

    @Test("Metric formatted duration shows seconds for slow ops")
    func formattedDurationSeconds() {
        let metric = PerformanceMetric(
            operation: "slow",
            durationSeconds: 2.5
        )
        #expect(metric.formattedDuration == "2.5s")
    }

    @Test("Metadata is passed through to metric")
    func metadataPassedThrough() async throws {
        let monitor = PerformanceMonitor()
        let (_, metric) = try await monitor.measure(
            operation: "op",
            metadata: ["chunks": "5", "type": "lease"]
        ) { 1 }

        #expect(metric.metadata["chunks"] == "5")
        #expect(metric.metadata["type"] == "lease")
    }
}

private enum TestError: Error {
    case intentional
}
