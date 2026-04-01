import Foundation
import Testing
@testable import PrivlensCore

@Suite("ErrorRecoveryService Tests")
struct ErrorRecoveryServiceTests {

    private let service = ErrorRecoveryService()

    // MARK: - Analysis Coordinator Errors

    @Test("Empty document text suggests rescan")
    func emptyDocumentSuggestsRescan() {
        let error = AnalysisCoordinatorError.emptyDocumentText
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.rescan))
        #expect(info.isRetryable == false)
    }

    @Test("Analysis service failure is retryable")
    func analysisServiceFailureIsRetryable() {
        let error = AnalysisCoordinatorError.analysisServiceFailed("timeout")
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.retry))
        #expect(info.isRetryable == true)
    }

    // MARK: - AI Analysis Errors

    @Test("AI unavailable has no retry")
    func aiUnavailableNoRetry() {
        let error = AIAnalysisError.unavailable
        let info = service.recoveryInfo(for: error)

        #expect(info.isRetryable == false)
    }

    @Test("No chunks provided suggests rescan")
    func noChunksSuggestsRescan() {
        let error = AIAnalysisError.noChunksProvided
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.rescan))
    }

    @Test("Chunk analysis failure is retryable")
    func chunkFailureIsRetryable() {
        let error = AIAnalysisError.chunkAnalysisFailed(chunkIndex: 2, underlying: "timeout")
        let info = service.recoveryInfo(for: error)

        #expect(info.isRetryable == true)
        #expect(info.actions.contains(.retry))
    }

    // MARK: - Validation Errors

    @Test("Empty text suggests rescan")
    func emptyTextSuggestsRescan() {
        let error = ValidationError.emptyText
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.rescan))
    }

    @Test("Text too short suggests rescan")
    func textTooShortSuggestsRescan() {
        let error = ValidationError.textTooShort(minimum: 20, actual: 5)
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.rescan))
    }

    @Test("Text too long suggests reducing pages")
    func textTooLongSuggestsReduce() {
        let error = ValidationError.textTooLong(maximum: 500000, actual: 600000)
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.reducePages))
    }

    // MARK: - Storage Errors

    @Test("File write failure suggests checking storage")
    func fileWriteFailureSuggestsCheckStorage() {
        let error = StorageError.fileWriteFailed("/path/to/file")
        let info = service.recoveryInfo(for: error)

        #expect(info.actions.contains(.checkStorage))
        #expect(info.isRetryable == true)
    }

    @Test("Encoding failure is retryable")
    func encodingFailureIsRetryable() {
        let error = StorageError.encodingFailed
        let info = service.recoveryInfo(for: error)

        #expect(info.isRetryable == true)
        #expect(info.actions.contains(.retry))
    }

    // MARK: - Generic Errors

    @Test("Unknown error has retry and support actions")
    func unknownErrorHasRetryAndSupport() {
        struct UnknownError: Error {}
        let info = service.recoveryInfo(for: UnknownError())

        #expect(info.actions.contains(.retry))
        #expect(info.actions.contains(.contactSupport))
        #expect(info.isRetryable == true)
    }

    // MARK: - RecoveryAction Properties

    @Test("Recovery actions have display text")
    func recoveryActionsHaveDisplayText() {
        for action in RecoveryAction.allCases where action != .none {
            #expect(!action.displayText.isEmpty)
            #expect(!action.systemIcon.isEmpty)
        }
    }
}
