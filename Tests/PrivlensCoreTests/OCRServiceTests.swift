import Testing
import Foundation
@testable import PrivlensCore

@Suite("OCRResult Model Tests")
struct OCRResultTests {

    @Test("Empty result has zero confidence and no regions")
    func emptyResult() {
        let result = OCRResult.empty
        #expect(result.text == "")
        #expect(result.averageConfidence == 0)
        #expect(result.regions.isEmpty)
        #expect(result.recognitionLevel == "accurate")
        #expect(result.languageCorrectionApplied == false)
    }

    @Test("OCRResult stores text and confidence correctly")
    func resultProperties() {
        let regions = [
            OCRTextRegion(text: "Hello", confidence: 0.95, boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.1)),
            OCRTextRegion(text: "World", confidence: 0.85, boundingBox: CGRect(x: 0, y: 0.1, width: 0.5, height: 0.1)),
        ]
        let result = OCRResult(
            text: "Hello\nWorld",
            averageConfidence: 0.90,
            regions: regions,
            recognitionLevel: "accurate",
            languageCorrectionApplied: true
        )

        #expect(result.text == "Hello\nWorld")
        #expect(result.averageConfidence == 0.90)
        #expect(result.regions.count == 2)
        #expect(result.recognitionLevel == "accurate")
        #expect(result.languageCorrectionApplied == true)
    }

    @Test("OCRTextRegion is identifiable with unique IDs")
    func regionIdentifiable() {
        let r1 = OCRTextRegion(text: "A", confidence: 1.0, boundingBox: .zero)
        let r2 = OCRTextRegion(text: "B", confidence: 0.9, boundingBox: .zero)
        #expect(r1.id != r2.id)
    }

    @Test("OCRTextRegion stores bounding box")
    func regionBoundingBox() {
        let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let region = OCRTextRegion(text: "Test", confidence: 0.99, boundingBox: box)
        #expect(region.boundingBox == box)
        #expect(region.confidence == 0.99)
    }

    @Test("OCRResult is Codable (round-trip)")
    func codableRoundTrip() throws {
        let regions = [
            OCRTextRegion(text: "Line 1", confidence: 0.92, boundingBox: CGRect(x: 0, y: 0, width: 1, height: 0.5)),
        ]
        let original = OCRResult(
            text: "Line 1",
            averageConfidence: 0.92,
            regions: regions,
            recognitionLevel: "fast",
            languageCorrectionApplied: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OCRResult.self, from: data)

        #expect(decoded.text == original.text)
        #expect(decoded.averageConfidence == original.averageConfidence)
        #expect(decoded.regions.count == 1)
        #expect(decoded.regions[0].text == "Line 1")
        #expect(decoded.recognitionLevel == "fast")
        #expect(decoded.languageCorrectionApplied == false)
    }
}

@Suite("OCRRecognitionLevel Tests")
struct OCRRecognitionLevelTests {

    @Test("Recognition levels are distinct")
    func levelsDistinct() {
        let accurate = OCRRecognitionLevel.accurate
        let fast = OCRRecognitionLevel.fast
        // Verify they can be used in switch
        switch accurate {
        case .accurate: #expect(true)
        case .fast: #expect(Bool(false))
        }
        switch fast {
        case .accurate: #expect(Bool(false))
        case .fast: #expect(true)
        }
    }
}

@Suite("MockOCRService Tests")
struct MockOCRServiceTests {

    @Test("Mock returns configured result")
    func mockReturnsResult() async throws {
        let regions = [
            OCRTextRegion(text: "Mock text", confidence: 0.88, boundingBox: .zero),
        ]
        let expected = OCRResult(
            text: "Mock text",
            averageConfidence: 0.88,
            regions: regions,
            recognitionLevel: "accurate",
            languageCorrectionApplied: true
        )
        let mock = MockOCRService(mockResult: expected)
        let result = try await mock.extractText()

        #expect(result.text == "Mock text")
        #expect(result.averageConfidence == 0.88)
        #expect(mock.extractCallCount == 1)
    }

    @Test("Mock tracks call count")
    func mockCallCount() async throws {
        let mock = MockOCRService()
        _ = try await mock.extractText()
        _ = try await mock.extractText()
        _ = try await mock.extractText()
        #expect(mock.extractCallCount == 3)
    }

    @Test("Mock throws configured error")
    func mockThrowsError() async {
        let mock = MockOCRService()
        mock.shouldThrow = OCRError.invalidImageData
        do {
            _ = try await mock.extractText()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is OCRError)
        }
    }

    @Test("Mock supports different recognition levels")
    func mockRecognitionLevels() async throws {
        let mock = MockOCRService()
        _ = try await mock.extractText(recognitionLevel: .fast)
        _ = try await mock.extractText(recognitionLevel: .accurate, languageCorrection: false)
        #expect(mock.extractCallCount == 2)
    }
}

@Suite("OCRError Tests")
struct OCRErrorTests {

    @Test("Error descriptions are meaningful")
    func errorDescriptions() {
        let invalid = OCRError.invalidImageData
        #expect(invalid.errorDescription?.contains("image data") == true)

        let failed = OCRError.recognitionFailed("timeout")
        #expect(failed.errorDescription?.contains("timeout") == true)
    }

    #if !canImport(Vision)
    @Test("Unavailable error on non-Apple platforms")
    func unavailableError() {
        let unavail = OCRError.unavailable
        #expect(unavail.errorDescription?.contains("not available") == true)
    }

    @Test("OCRService throws unavailable on Linux")
    func serviceThrowsOnLinux() async {
        let service = OCRService()
        do {
            _ = try await service.extractText(from: Data())
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is OCRError)
        }
    }
    #endif
}
