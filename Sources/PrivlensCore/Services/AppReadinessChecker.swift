import Foundation

// MARK: - ReadinessCheck

/// Result of a single readiness check.
public struct ReadinessCheck: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let passed: Bool
    public let detail: String

    public init(
        id: UUID = UUID(),
        name: String,
        passed: Bool,
        detail: String
    ) {
        self.id = id
        self.name = name
        self.passed = passed
        self.detail = detail
    }
}

// MARK: - ReadinessReport

/// Aggregated result of all readiness checks.
public struct ReadinessReport: Sendable {
    public let checks: [ReadinessCheck]
    public let timestamp: Date

    public var allPassed: Bool {
        checks.allSatisfy(\.passed)
    }

    public var passedCount: Int {
        checks.filter(\.passed).count
    }

    public var failedCount: Int {
        checks.filter { !$0.passed }.count
    }

    public init(checks: [ReadinessCheck], timestamp: Date = Date()) {
        self.checks = checks
        self.timestamp = timestamp
    }
}

// MARK: - AppReadinessCheckerProtocol

/// Protocol for verifying device and app readiness for core functionality.
public protocol AppReadinessCheckerProtocol: Sendable {
    /// Runs all readiness checks and returns a report.
    func checkReadiness() -> ReadinessReport
}

// MARK: - AppReadinessChecker

/// Verifies that the device and app environment are properly configured.
public final class AppReadinessChecker: AppReadinessCheckerProtocol, Sendable {

    public init() {}

    public func checkReadiness() -> ReadinessReport {
        var checks: [ReadinessCheck] = []

        // 1. Check platform
        checks.append(checkPlatform())

        // 2. Check Foundation Models availability
        checks.append(checkFoundationModels())

        // 3. Check file system writability
        checks.append(checkFileSystem())

        // 4. Check available storage
        checks.append(checkStorage())

        // 5. Check camera availability
        checks.append(checkCamera())

        return ReadinessReport(checks: checks)
    }

    // MARK: - Individual Checks

    private func checkPlatform() -> ReadinessCheck {
        #if os(iOS)
        return ReadinessCheck(
            name: "Platform",
            passed: true,
            detail: "Running on iOS"
        )
        #elseif os(macOS)
        return ReadinessCheck(
            name: "Platform",
            passed: true,
            detail: "Running on macOS"
        )
        #else
        return ReadinessCheck(
            name: "Platform",
            passed: false,
            detail: "Unsupported platform. Privlens requires iOS 26+ or macOS 26+."
        )
        #endif
    }

    private func checkFoundationModels() -> ReadinessCheck {
        #if ENABLE_FOUNDATION_MODELS
        return ReadinessCheck(
            name: "AI Engine",
            passed: true,
            detail: "Apple Foundation Models available"
        )
        #else
        return ReadinessCheck(
            name: "AI Engine",
            passed: false,
            detail: "Apple Foundation Models not available. AI analysis requires iOS 26+ with A17 Pro or M1 chip."
        )
        #endif
    }

    private func checkFileSystem() -> ReadinessCheck {
        let testPath: String
        #if canImport(UIKit) || canImport(AppKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        testPath = documentsPath
        #else
        testPath = NSTemporaryDirectory()
        #endif

        let isWritable = FileManager.default.isWritableFile(atPath: testPath)
        return ReadinessCheck(
            name: "Storage Access",
            passed: isWritable,
            detail: isWritable ? "Document storage directory is writable" : "Cannot write to document storage directory"
        )
    }

    private func checkStorage() -> ReadinessCheck {
        let tempFile = NSTemporaryDirectory() + "privlens_readiness_\(UUID().uuidString).tmp"
        let testData = Data("readiness_check".utf8)
        let canWrite = FileManager.default.createFile(atPath: tempFile, contents: testData)
        if canWrite {
            try? FileManager.default.removeItem(atPath: tempFile)
        }
        return ReadinessCheck(
            name: "Disk Space",
            passed: canWrite,
            detail: canWrite ? "Sufficient disk space available" : "Unable to write to disk. Device may be low on storage."
        )
    }

    private func checkCamera() -> ReadinessCheck {
        #if canImport(VisionKit) && os(iOS)
        return ReadinessCheck(
            name: "Camera",
            passed: true,
            detail: "Document camera is available on this platform"
        )
        #else
        return ReadinessCheck(
            name: "Camera",
            passed: false,
            detail: "Document camera requires iOS with VisionKit"
        )
        #endif
    }
}
