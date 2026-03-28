import Foundation
import Testing
@testable import PrivlensCore

@Suite("InputValidator Tests")
struct InputValidatorTests {

    private let validator = InputValidator()

    // MARK: - Document Text Validation

    @Test("Empty text is invalid")
    func emptyTextIsInvalid() {
        let result = validator.validateDocumentText("")
        #expect(result.isValid == false)
        #expect(!result.warnings.isEmpty)
    }

    @Test("Whitespace-only text is invalid")
    func whitespaceOnlyIsInvalid() {
        let result = validator.validateDocumentText("   \n\t  ")
        #expect(result.isValid == false)
    }

    @Test("Text below minimum length is invalid")
    func shortTextIsInvalid() {
        let result = validator.validateDocumentText("Hi there.")
        #expect(result.isValid == false)
    }

    @Test("Valid document text passes validation")
    func validTextPasses() {
        let text = "This is a lease agreement between the landlord and the tenant for the property located at 123 Main Street."
        let result = validator.validateDocumentText(text)
        #expect(result.isValid == true)
    }

    @Test("Very long text generates warning but still valid")
    func longTextGeneratesWarning() {
        let text = String(repeating: "This is a long lease agreement paragraph with many terms and conditions. ", count: 10000)
        let result = validator.validateDocumentText(text)
        #expect(result.isValid == true)
        #expect(result.warnings.contains { $0.contains("very large") })
    }

    @Test("Text with no readable words is invalid")
    func noReadableWordsIsInvalid() {
        let result = validator.validateDocumentText("12345 67890 !@#$% ^&*() +++===")
        #expect(result.isValid == false)
    }

    @Test("Sanitized text is returned for valid input")
    func sanitizedTextReturned() {
        let text = "This is a valid document   with   extra   spaces and readable content."
        let result = validator.validateDocumentText(text)
        #expect(result.isValid == true)
        #expect(result.sanitizedText != nil)
        #expect(result.sanitizedText?.contains("  ") == false)
    }

    // MARK: - OCR Text Sanitization

    @Test("Sanitize collapses multiple spaces")
    func sanitizeCollapsesSpaces() {
        let result = validator.sanitizeOCRText("Hello   world   test")
        #expect(result == "Hello world test")
    }

    @Test("Sanitize normalizes line endings")
    func sanitizeNormalizesLineEndings() {
        let result = validator.sanitizeOCRText("line1\r\nline2\rline3\nline4")
        #expect(result.contains("\r") == false)
    }

    @Test("Sanitize collapses excessive blank lines")
    func sanitizeCollapsesBlankLines() {
        let result = validator.sanitizeOCRText("para1\n\n\n\n\npara2")
        #expect(result == "para1\n\npara2")
    }

    @Test("Sanitize trims leading/trailing whitespace per line")
    func sanitizeTrimsLines() {
        let result = validator.sanitizeOCRText("  hello  \n  world  ")
        #expect(result == "hello\nworld")
    }

    // MARK: - Title Validation

    @Test("Empty title gets default name")
    func emptyTitleGetsDefault() {
        let result = validator.validateTitle("")
        #expect(result == "Untitled Document")
    }

    @Test("Whitespace-only title gets default name")
    func whitespaceOnlyTitleGetsDefault() {
        let result = validator.validateTitle("   \t  ")
        #expect(result == "Untitled Document")
    }

    @Test("Long title gets truncated")
    func longTitleGetsTruncated() {
        let longTitle = String(repeating: "A", count: 300)
        let result = validator.validateTitle(longTitle)
        #expect(result.count == InputValidator.maxTitleLength)
    }

    @Test("Normal title passes through")
    func normalTitlePassesThrough() {
        let result = validator.validateTitle("Medical Bill - January 2026")
        #expect(result == "Medical Bill - January 2026")
    }
}
