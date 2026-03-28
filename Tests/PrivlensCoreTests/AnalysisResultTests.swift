import Foundation
import Testing
@testable import PrivlensCore

@Suite("AnalysisResult & Source Attribution Tests")
struct AnalysisResultTests {

    // MARK: - InsightCategory

    @Test("InsightCategory has all expected cases")
    func insightCategoryCases() {
        let allCases = InsightCategory.allCases
        #expect(allCases.count == 9)
        #expect(allCases.contains(.personalInfo))
        #expect(allCases.contains(.financialInfo))
        #expect(allCases.contains(.legalClause))
        #expect(allCases.contains(.expirationDate))
        #expect(allCases.contains(.obligation))
        #expect(allCases.contains(.risk))
        #expect(allCases.contains(.recommendation))
        #expect(allCases.contains(.keyTerm))
        #expect(allCases.contains(.other))
    }

    @Test("InsightCategory Codable round-trip")
    func insightCategoryCodable() throws {
        let category = InsightCategory.financialInfo
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(InsightCategory.self, from: data)
        #expect(decoded == category)
    }

    // MARK: - SourceAttribution

    @Test("SourceAttribution initializes with correct values")
    func sourceAttributionInit() {
        let attr = SourceAttribution(
            chunkIndex: 2,
            startOffset: 10,
            endOffset: 25,
            matchedText: "monthly payment",
            pageIndex: 1
        )
        #expect(attr.chunkIndex == 2)
        #expect(attr.startOffset == 10)
        #expect(attr.endOffset == 25)
        #expect(attr.matchedText == "monthly payment")
        #expect(attr.pageIndex == 1)
    }

    @Test("SourceAttribution pageIndex defaults to nil")
    func sourceAttributionDefaultPageIndex() {
        let attr = SourceAttribution(
            chunkIndex: 0,
            startOffset: 0,
            endOffset: 5,
            matchedText: "hello"
        )
        #expect(attr.pageIndex == nil)
    }

    @Test("SourceAttribution Codable round-trip")
    func sourceAttributionCodable() throws {
        let original = SourceAttribution(
            chunkIndex: 1,
            startOffset: 5,
            endOffset: 20,
            matchedText: "security deposit",
            pageIndex: 3
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SourceAttribution.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Insight

    @Test("Insight initializes with correct defaults")
    func insightInit() {
        let insight = Insight(
            title: "High Fee",
            description: "An unusually high fee of $500",
            category: .financialInfo,
            confidence: 0.85
        )
        #expect(insight.title == "High Fee")
        #expect(insight.description == "An unusually high fee of $500")
        #expect(insight.category == .financialInfo)
        #expect(insight.confidence == 0.85)
        #expect(insight.sourceAttributions.isEmpty)
    }

    @Test("Insight Codable round-trip preserves all fields")
    func insightCodable() throws {
        let attribution = SourceAttribution(
            chunkIndex: 0,
            startOffset: 10,
            endOffset: 30,
            matchedText: "fee of $500",
            pageIndex: 1
        )
        let original = Insight(
            title: "High Fee",
            description: "An unusually high fee detected",
            category: .financialInfo,
            confidence: 0.92,
            sourceAttributions: [attribution]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Insight.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.title == original.title)
        #expect(decoded.description == original.description)
        #expect(decoded.category == original.category)
        #expect(decoded.confidence == original.confidence)
        #expect(decoded.sourceAttributions == original.sourceAttributions)
    }

    // MARK: - AttributedAnalysisResult

    @Test("AttributedAnalysisResult initializes correctly")
    func attributedAnalysisResultInit() {
        let docId = UUID()
        let insight = Insight(
            title: "Lease Term",
            description: "12-month lease term identified",
            category: .legalClause,
            confidence: 0.95
        )
        let result = AttributedAnalysisResult(
            documentId: docId,
            insights: [insight],
            summary: "A standard 12-month lease agreement.",
            totalChunksProcessed: 5
        )

        #expect(result.documentId == docId)
        #expect(result.insights.count == 1)
        #expect(result.summary == "A standard 12-month lease agreement.")
        #expect(result.totalChunksProcessed == 5)
    }

    @Test("AttributedAnalysisResult Codable round-trip")
    func attributedAnalysisResultCodable() throws {
        let attribution = SourceAttribution(
            chunkIndex: 0,
            startOffset: 0,
            endOffset: 15,
            matchedText: "security deposit"
        )
        let insight = Insight(
            title: "Security Deposit",
            description: "A security deposit of $2000 is required",
            category: .financialInfo,
            confidence: 0.88,
            sourceAttributions: [attribution]
        )
        let original = AttributedAnalysisResult(
            documentId: UUID(),
            insights: [insight],
            summary: "Lease with $2000 deposit.",
            analyzedAt: Date(timeIntervalSince1970: 1700000000),
            totalChunksProcessed: 3
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AttributedAnalysisResult.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.documentId == original.documentId)
        #expect(decoded.insights.count == 1)
        #expect(decoded.insights.first?.title == "Security Deposit")
        #expect(decoded.summary == original.summary)
        #expect(decoded.totalChunksProcessed == 3)
    }

    // MARK: - AttributionService

    @Test("AttributionService finds keyword matches in chunks")
    func attributionServiceFindsMatches() {
        let service = AttributionService()
        let chunk = TextChunk(
            text: "The monthly rent payment is $1500 due on the first of each month.",
            metadata: ChunkMetadata(
                chunkIndex: 0,
                startOffset: 0,
                endOffset: 65,
                sourcePageIndex: 0
            )
        )
        let insight = Insight(
            title: "Monthly Rent",
            description: "The rent payment amount is $1500",
            category: .financialInfo,
            confidence: 0.9
        )

        let attributions = service.findAttributions(for: insight, in: [chunk])
        #expect(!attributions.isEmpty)

        // Should find "monthly" and "rent" and "payment" at minimum.
        let matchedTexts = attributions.map { $0.matchedText.lowercased() }
        #expect(matchedTexts.contains("monthly"))
        #expect(matchedTexts.contains("rent"))
        #expect(matchedTexts.contains("payment"))
    }

    @Test("AttributionService returns empty for no matches")
    func attributionServiceNoMatches() {
        let service = AttributionService()
        let chunk = TextChunk(
            text: "The weather today is sunny and warm.",
            metadata: ChunkMetadata(
                chunkIndex: 0,
                startOffset: 0,
                endOffset: 35
            )
        )
        let insight = Insight(
            title: "Security Deposit",
            description: "A refundable security deposit of $2000",
            category: .financialInfo,
            confidence: 0.85
        )

        let attributions = service.findAttributions(for: insight, in: [chunk])
        #expect(attributions.isEmpty)
    }

    @Test("AttributionService reports correct offsets")
    func attributionServiceCorrectOffsets() {
        let service = AttributionService()
        let chunk = TextChunk(
            text: "The deposit amount is significant.",
            metadata: ChunkMetadata(
                chunkIndex: 0,
                startOffset: 0,
                endOffset: 33,
                sourcePageIndex: 2
            )
        )
        let insight = Insight(
            title: "Deposit Amount",
            description: "Large deposit required",
            category: .financialInfo,
            confidence: 0.8
        )

        let attributions = service.findAttributions(for: insight, in: [chunk])
        let depositAttr = attributions.first { $0.matchedText.lowercased() == "deposit" }
        #expect(depositAttr != nil)
        #expect(depositAttr?.startOffset == 4)
        #expect(depositAttr?.endOffset == 11)
        #expect(depositAttr?.pageIndex == 2)
        #expect(depositAttr?.chunkIndex == 0)
    }

    @Test("AttributionService searches across multiple chunks")
    func attributionServiceMultipleChunks() {
        let service = AttributionService()
        let chunk0 = TextChunk(
            text: "This lease agreement begins in January.",
            metadata: ChunkMetadata(chunkIndex: 0, startOffset: 0, endOffset: 39, sourcePageIndex: 0)
        )
        let chunk1 = TextChunk(
            text: "The tenant shall pay rent monthly.",
            metadata: ChunkMetadata(chunkIndex: 1, startOffset: 39, endOffset: 72, sourcePageIndex: 1)
        )
        let insight = Insight(
            title: "Lease Terms",
            description: "Tenant must pay rent under lease agreement",
            category: .legalClause,
            confidence: 0.9
        )

        let attributions = service.findAttributions(for: insight, in: [chunk0, chunk1])
        let chunkIndices = Set(attributions.map { $0.chunkIndex })
        #expect(chunkIndices.contains(0)) // "lease" in chunk0
        #expect(chunkIndices.contains(1)) // "tenant", "rent" in chunk1
    }
}
