import Foundation
import Testing
@testable import PrivlensCore

@Suite("Document Model Tests")
struct DocumentModelTests {

    @Test("Document initializes with correct defaults")
    func defaultInit() {
        let doc = Document(title: "Test Doc", rawText: "Some text")
        #expect(doc.title == "Test Doc")
        #expect(doc.rawText == "Some text")
        #expect(doc.documentType == .unknown)
        #expect(doc.redFlags.isEmpty)
        #expect(doc.keyInsights.isEmpty)
        #expect(doc.analysisResult == nil)
        #expect(doc.thumbnailData == nil)
        #expect(doc.pageImageData.isEmpty)
        #expect(doc.pageCount == 0)
    }

    @Test("Document stores document type via raw value")
    func documentTypeRawValue() {
        let doc = Document(title: "Lease", rawText: "text", documentType: .lease)
        #expect(doc.documentTypeRaw == "lease")
        #expect(doc.documentType == .lease)
    }

    @Test("DocumentType display names are correct")
    func displayNames() {
        #expect(DocumentType.medicalBill.displayName == "Medical Bill")
        #expect(DocumentType.lease.displayName == "Lease Agreement")
        #expect(DocumentType.insurance.displayName == "Insurance Document")
        #expect(DocumentType.unknown.displayName == "Unknown")
    }

    @Test("DocumentType system icons are set")
    func systemIcons() {
        for type in DocumentType.allCases {
            #expect(!type.systemIcon.isEmpty)
        }
    }

    @Test("Document stores page image data and count")
    func pageImageData() {
        let fakeJpeg = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let doc = Document(
            title: "Multi-page",
            rawText: "text",
            pageImageData: [fakeJpeg, fakeJpeg],
            pageCount: 2
        )
        #expect(doc.pageImageData.count == 2)
        #expect(doc.pageCount == 2)
    }

    @Test("AnalysisResult initializes correctly")
    func analysisResultInit() {
        let result = AnalysisResult(
            summary: "A medical bill summary",
            keyInsights: ["Insight 1"],
            redFlags: ["Red flag 1"],
            actionItems: ["Action 1"],
            documentType: .medicalBill
        )
        #expect(result.summary == "A medical bill summary")
        #expect(result.keyInsights.count == 1)
        #expect(result.redFlags.count == 1)
        #expect(result.actionItems.count == 1)
        #expect(result.documentType == .medicalBill)
    }
}
