import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - DocumentType

public enum DocumentType: String, Codable, Sendable, CaseIterable {
    case medicalBill
    case lease
    case insurance
    case unknown

    public var displayName: String {
        switch self {
        case .medicalBill: return "Medical Bill"
        case .lease: return "Lease Agreement"
        case .insurance: return "Insurance Document"
        case .unknown: return "Unknown"
        }
    }

    public var systemIcon: String {
        switch self {
        case .medicalBill: return "cross.case.fill"
        case .lease: return "house.fill"
        case .insurance: return "shield.fill"
        case .unknown: return "doc.fill"
        }
    }
}

// MARK: - Document (SwiftData Model)

#if canImport(SwiftData)
@Model
public final class Document {
    public var id: UUID
    public var title: String
    public var rawText: String
    public var documentTypeRaw: String
    public var dateScanned: Date
    public var analysisResult: String?
    public var redFlags: [String]
    public var keyInsights: [String]
    @Attribute(.externalStorage)
    public var thumbnailData: Data?
    /// JPEG data for each scanned page, stored externally to keep the DB lean.
    @Attribute(.externalStorage)
    public var pageImageData: [Data]
    /// Number of pages in the original scan.
    public var pageCount: Int

    public var documentType: DocumentType {
        get { DocumentType(rawValue: documentTypeRaw) ?? .unknown }
        set { documentTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        rawText: String,
        documentType: DocumentType = .unknown,
        dateScanned: Date = Date(),
        analysisResult: String? = nil,
        redFlags: [String] = [],
        keyInsights: [String] = [],
        thumbnailData: Data? = nil,
        pageImageData: [Data] = [],
        pageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.documentTypeRaw = documentType.rawValue
        self.dateScanned = dateScanned
        self.analysisResult = analysisResult
        self.redFlags = redFlags
        self.keyInsights = keyInsights
        self.thumbnailData = thumbnailData
        self.pageImageData = pageImageData
        self.pageCount = pageCount
    }
}
#else
public final class Document: Codable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var rawText: String
    public var documentTypeRaw: String
    public var dateScanned: Date
    public var analysisResult: String?
    public var redFlags: [String]
    public var keyInsights: [String]
    public var thumbnailData: Data?
    public var pageImageData: [Data]
    public var pageCount: Int

    public var documentType: DocumentType {
        get { DocumentType(rawValue: documentTypeRaw) ?? .unknown }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        rawText: String,
        documentType: DocumentType = .unknown,
        dateScanned: Date = Date(),
        analysisResult: String? = nil,
        redFlags: [String] = [],
        keyInsights: [String] = [],
        thumbnailData: Data? = nil,
        pageImageData: [Data] = [],
        pageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.documentTypeRaw = documentType.rawValue
        self.dateScanned = dateScanned
        self.analysisResult = analysisResult
        self.redFlags = redFlags
        self.keyInsights = keyInsights
        self.thumbnailData = thumbnailData
        self.pageImageData = pageImageData
        self.pageCount = pageCount
    }
}
#endif
