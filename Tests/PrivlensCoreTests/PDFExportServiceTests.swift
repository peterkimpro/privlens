import Foundation
import Testing
@testable import PrivlensCore

@Suite("PDFExportService Tests")
struct PDFExportServiceTests {
    let service = PDFExportService()

    // MARK: - Text Report Tests

    @Test("Text report includes document title")
    func textReportIncludesTitle() {
        let doc = Document(title: "My Medical Bill", rawText: "Patient: John", documentType: .medicalBill)
        let result = AnalysisResult(
            summary: "A medical bill summary.",
            keyInsights: ["Insight 1"],
            redFlags: [],
            actionItems: [],
            documentType: .medicalBill
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("My Medical Bill"))
    }

    @Test("Text report includes document type")
    func textReportIncludesType() {
        let doc = Document(title: "Test", rawText: "text", documentType: .lease)
        let result = AnalysisResult(
            summary: "Summary",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .lease
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("Lease Agreement"))
    }

    @Test("Text report includes summary")
    func textReportIncludesSummary() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "This is the document summary.",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("This is the document summary."))
    }

    @Test("Text report includes red flags")
    func textReportIncludesRedFlags() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "Summary",
            keyInsights: [],
            redFlags: ["Hidden fee of $500", "Automatic renewal"],
            actionItems: [],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("RED FLAGS"))
        #expect(report.contains("Hidden fee of $500"))
        #expect(report.contains("Automatic renewal"))
    }

    @Test("Text report includes key insights")
    func textReportIncludesInsights() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "Summary",
            keyInsights: ["Deductible is $5,000"],
            redFlags: [],
            actionItems: [],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("KEY INSIGHTS"))
        #expect(report.contains("Deductible is $5,000"))
    }

    @Test("Text report includes action items")
    func textReportIncludesActionItems() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "Summary",
            keyInsights: [],
            redFlags: [],
            actionItems: ["Review before signing", "Negotiate rent amount"],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("ACTION ITEMS"))
        #expect(report.contains("Review before signing"))
        #expect(report.contains("Negotiate rent amount"))
    }

    @Test("Text report includes privacy disclaimer")
    func textReportIncludesDisclaimer() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "Summary",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(report.contains("Privlens"))
        #expect(report.contains("on-device"))
    }

    // MARK: - PDF Export Tests

    @Test("Export analysis generates non-empty data")
    func exportAnalysisGeneratesData() throws {
        let doc = Document(title: "Test Doc", rawText: "Some text content", documentType: .medicalBill)
        let result = AnalysisResult(
            summary: "A test summary for export.",
            keyInsights: ["Insight A"],
            redFlags: ["Red flag A"],
            actionItems: ["Action A"],
            documentType: .medicalBill
        )

        let data = try service.exportAnalysis(document: doc, result: result)

        #expect(!data.isEmpty)
    }

    @Test("Export comparison generates non-empty data")
    func exportComparisonGeneratesData() throws {
        let comparison = ComparisonResult(
            documentAId: UUID(),
            documentBId: UUID(),
            documentATitle: "Lease 2025",
            documentBTitle: "Lease 2026",
            summary: "Documents are 65% similar.",
            differences: [
                ComparisonDifference(
                    category: .financial,
                    label: "Rent amount",
                    documentAValue: "$2,100",
                    documentBValue: "$2,400",
                    severity: 0.8
                )
            ],
            similarityScore: 0.65
        )

        let data = try service.exportComparison(comparison)

        #expect(!data.isEmpty)
    }

    @Test("Text report omits empty sections")
    func textReportOmitsEmptySections() {
        let doc = Document(title: "Test", rawText: "text", documentType: .unknown)
        let result = AnalysisResult(
            summary: "Only summary",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .unknown
        )

        let report = service.generateTextReport(document: doc, result: result)

        #expect(!report.contains("RED FLAGS"))
        #expect(!report.contains("KEY INSIGHTS"))
        #expect(!report.contains("ACTION ITEMS"))
    }
}
