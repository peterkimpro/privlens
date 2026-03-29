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

    @Test("Financial differences are detected")
    func detectsFinancialDifferences() async throws {
        let docA = Document(title: "A", rawText: "The total amount is $1,000 with a deposit of $500.", documentType: .unknown)
        let docB = Document(title: "B", rawText: "The total amount is $2,000 with a deposit of $750.", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        let financialDiffs = result.differences.filter { $0.category == .financial }
        #expect(!financialDiffs.isEmpty)
    }

    @Test("Legal term differences are detected")
    func detectsLegalTermDifferences() async throws {
        let docA = Document(title: "A", rawText: "This agreement includes an arbitration clause.", documentType: .unknown)
        let docB = Document(title: "B", rawText: "This agreement has standard terms.", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        let legalDiffs = result.differences.filter { $0.category == .legal }
        #expect(!legalDiffs.isEmpty)
    }

    @Test("Critical differences filter works")
    func criticalDifferencesFilter() async throws {
        let docA = Document(title: "A", rawText: "Non-compete clause applies for 2 years. Penalty of $10,000.", documentType: .unknown)
        let docB = Document(title: "B", rawText: "Standard terms apply.", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        let critical = result.criticalDifferences(threshold: 0.7)
        let allAboveThreshold = critical.allSatisfy { $0.severity >= 0.7 }
        #expect(allAboveThreshold)
    }

    @Test("Summary includes similarity percentage")
    func summaryIncludesSimilarity() async throws {
        let docA = Document(title: "A", rawText: "Hello world test document", documentType: .unknown)
        let docB = Document(title: "B", rawText: "Goodbye universe different content", documentType: .unknown)

        let result = try await service.compare(documentA: docA, documentB: docB)

        #expect(result.summary.contains("similar"))
    }
}
