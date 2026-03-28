import Foundation

// MARK: - StorageError

public enum StorageError: Error, LocalizedError, Sendable {
    case encodingFailed
    case decodingFailed
    case fileWriteFailed(String)
    case fileReadFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode analysis result."
        case .decodingFailed:
            return "Failed to decode analysis result."
        case .fileWriteFailed(let path):
            return "Failed to write file at \(path)."
        case .fileReadFailed(let path):
            return "Failed to read file at \(path)."
        case .deleteFailed(let path):
            return "Failed to delete file at \(path)."
        }
    }
}

// MARK: - StorageServiceProtocol

/// Protocol for persisting analysis results locally.
public protocol StorageServiceProtocol: Sendable {
    /// Save an analysis result associated with a document.
    func saveAnalysisResult(_ result: AnalysisResult, for documentId: UUID) async throws

    /// Load a previously saved analysis result for a document.
    func loadAnalysisResult(for documentId: UUID) async throws -> AnalysisResult?

    /// Delete a saved analysis result for a document.
    func deleteAnalysisResult(for documentId: UUID) async throws

    /// Get the total number of saved analysis results.
    func getAnalysisCount() async throws -> Int
}

// MARK: - StorageService

public final class StorageService: StorageServiceProtocol, Sendable {

    private let baseDirectory: String

    public init() {
        #if canImport(UIKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.baseDirectory = documentsPath + "/PrivlensAnalysis"
        #elseif canImport(AppKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.baseDirectory = documentsPath + "/PrivlensAnalysis"
        #else
        self.baseDirectory = "/tmp/PrivlensAnalysis"
        #endif
    }

    /// Initialize with a custom base directory (useful for testing).
    public init(baseDirectory: String) {
        self.baseDirectory = baseDirectory
    }

    public func saveAnalysisResult(_ result: AnalysisResult, for documentId: UUID) async throws {
        try ensureDirectoryExists()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(result) else {
            throw StorageError.encodingFailed
        }

        let path = filePath(for: documentId)
        let url = URL(fileURLWithPath: path)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw StorageError.fileWriteFailed(path)
        }
    }

    public func loadAnalysisResult(for documentId: UUID) async throws -> AnalysisResult? {
        let path = filePath(for: documentId)
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw StorageError.fileReadFailed(path)
        }

        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(AnalysisResult.self, from: data) else {
            throw StorageError.decodingFailed
        }

        return result
    }

    public func deleteAnalysisResult(for documentId: UUID) async throws {
        let path = filePath(for: documentId)

        guard FileManager.default.fileExists(atPath: path) else {
            return
        }

        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw StorageError.deleteFailed(path)
        }
    }

    public func getAnalysisCount() async throws -> Int {
        let url = URL(fileURLWithPath: baseDirectory)

        guard FileManager.default.fileExists(atPath: baseDirectory) else {
            return 0
        }

        let contents: [String]
        do {
            contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return 0
        }

        return contents.filter { $0.hasSuffix(".json") }.count
    }

    // MARK: - Private Helpers

    private func filePath(for documentId: UUID) -> String {
        return baseDirectory + "/\(documentId.uuidString).json"
    }

    private func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: baseDirectory) {
            try FileManager.default.createDirectory(
                atPath: baseDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
