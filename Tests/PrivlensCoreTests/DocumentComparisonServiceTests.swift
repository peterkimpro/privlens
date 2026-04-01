import Foundation
import Testing
@testable import PrivlensCore

@Suite("DocumentComparisonService Tests")
struct DocumentComparisonServiceTests {
    let service = DocumentComparisonService()

    @Test("Compare two different documents produces a result")
    func compareTwoDifferentDocuments() async throws {
        let docA = Document(
            title: "Lease 2025",
            rawText: "Monthly rent: $2,100. Security deposit: $4,200. Lease term: 12 months. Late fee of $50 applies. Pet policy: no pets allowed.",
            documentType: .lease
        )
        let docB = Document(
            title: "Lease 2026",
            rawText: "Monthly rent: $2,400. Security deposit: $4,800. Lease term: 12 months. Late fee of $75 applies. Automatic renewal clause included.",
            documentType: .lease
        )

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(result.documentAId == docA.id)
        #expect(result.documentBId == docB.id)
        #expect(result.documentATitle == "Lease 2025")
        #expect(result.documentBTitle == "Lease 2026")
        #expect(!result.summary.isEmpty)
        #expect(result.similarityScore >= 0.0 && result.similarityScore <= 1.0)
    }

    @Test("Compare identical text yields high similarity")
    func compareIdenticalText() async throws {
        let text = "This is a standard lease agreement with rent of $1,500 per month."
        let docA = Document(title: "Doc A", rawText: text, documentType: .lease)
        let docB = Document(title: "Doc B", rawText: text, documentType: .lease)

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(result.similarityScore > 0.9)
    }

    @Test("Compare completely different text yields low similarity")
    func compareCompletelyDifferent() async throws {
        let docA = Document(title: "A", rawText: "apple banana cherry date elderberry fig grape", documentType: .unknown)
        let docB = Document(title: "B", rawText: "quantum physics thermodynamics relativity entropy", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(result.similarityScore < 0.3)
    }

    @Test("Comparing same document throws error")
    func compareSameDocumentThrows() async {
        let doc = Document(title: "Same", rawText: "content", documentType: .unknown)

        do {
            _ = try await service.compare(documentA: doc, documentB: doc)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DocumentComparisonError)
        }
    }

    @Test("Comparing empty document A throws error")
    func compareEmptyDocAThrows() async {
        let docA = Document(title: "Empty", rawText: "", documentType: .unknown)
        let docB = Document(title: "Full", rawText: "Some content here", documentType: .unknown)

        do {
            _ = try await service.compare(documentA: docA, documentB: docB)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DocumentComparisonError)
        }
    }

    @Test("Comparing empty document B throws error")
    func compareEmptyDocBThrows() async {
        let docA = Document(title: "Full", rawText: "Some content here", documentType: .unknown)
        let docB = Document(title: "Empty", rawText: "", documentType: .unknown)

        do {
            _ = try await service.compare(documentA: docA, documentB: docB)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DocumentComparisonError)
        }
    }

    @Test("Result contains valid document IDs and titles")
    func resultContainsDocumentInfo() async throws {
        let docA = Document(title: "Quote A", rawText: "Window replacement quote: $5,000 for 10 windows.", documentType: .unknown)
        let docB = Document(title: "Quote B", rawText: "Window replacement quote: $6,500 for 10 windows with warranty.", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(result.documentAId == docA.id)
        #expect(result.documentBId == docB.id)
        #expect(result.documentATitle == "Quote A")
        #expect(result.documentBTitle == "Quote B")
    }

    @Test("Critical differences filter works")
    func criticalDifferencesFilter() async throws {
        // Build a result with known severities to test the filter
        let result = ComparisonResult(
            documentAId: UUID(),
            documentBId: UUID(),
            documentATitle: "A",
            documentBTitle: "B",
            summary: "Test",
            differences: [
                ComparisonDifference(category: .financial, label: "High", documentAValue: "$100", documentBValue: "$200", severity: 0.9),
                ComparisonDifference(category: .other, label: "Low", documentAValue: "X", documentBValue: "Y", severity: 0.3),
            ],
            similarityScore: 0.5
        )

        let critical = result.criticalDifferences(threshold: 0.7)
        #expect(critical.count == 1)
        #expect(critical.first?.label == "High")
    }

    @Test("Summary is non-empty for valid comparison")
    func summaryIsNonEmpty() async throws {
        let docA = Document(title: "A", rawText: "Hello world test document", documentType: .unknown)
        let docB = Document(title: "B", rawText: "Goodbye universe different content", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(!result.summary.isEmpty)
    }
}
