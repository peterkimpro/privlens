import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - DocumentType

public enum DocumentType: String, Codable, Sendable, CaseIterable {
    case medicalBill
    case lease
    case insurance
    case taxForm
    case employmentContract
    case nda
    case governmentForm
    case loanAgreement
    case homePurchase
    case unknown

    public var displayName: String {
        switch self {
        case .medicalBill: return "Medical Bill"
        case .lease: return "Lease Agreement"
        case .insurance: return "Insurance Document"
        case .taxForm: return "Tax Form"
        case .employmentContract: return "Employment Contract"
        case .nda: return "NDA"
        case .governmentForm: return "Government Form"
        case .loanAgreement: return "Loan Agreement"
        case .homePurchase: return "Home Purchase"
        case .unknown: return "Unknown"
        }
    }

    public var systemIcon: String {
        switch self {
        case .medicalBill: return "cross.case.fill"
        case .lease: return "house.fill"
        case .insurance: return "shield.fill"
        case .taxForm: return "doc.text.fill"
        case .employmentContract: return "briefcase.fill"
        case .nda: return "lock.doc.fill"
        case .governmentForm: return "building.columns.fill"
        case .loanAgreement: return "banknote.fill"
        case .homePurchase: return "house.and.flag.fill"
        case .unknown: return "doc.fill"
        }
    }

    public var documentDescription: String {
        switch self {
        case .medicalBill: return "Medical bills, EOBs, and healthcare-related charges"
        case .lease: return "Rental and lease agreements for residential or commercial property"
        case .insurance: return "Insurance policies, coverage documents, and claims"
        case .taxForm: return "Tax returns, W-2s, 1099s, and related tax documents"
        case .employmentContract: return "Employment agreements, offer letters, and work contracts"
        case .nda: return "Non-disclosure and confidentiality agreements"
        case .governmentForm: return "Tax forms (W-2, 1099, 1040), DMV forms, social security letters, and immigration documents"
        case .loanAgreement: return "Mortgages, auto loans, student loans, and personal loan agreements"
        case .homePurchase: return "Closing disclosures, title reports, home inspection reports, and HOA documents"
        case .unknown: return "Unclassified document"
        }
    }

    public var themeColorName: String {
        switch self {
        case .medicalBill: return "red"
        case .lease: return "brown"
        case .insurance: return "blue"
        case .taxForm: return "green"
        case .employmentContract: return "purple"
        case .nda: return "gray"
        case .governmentForm: return "indigo"
        case .loanAgreement: return "orange"
        case .homePurchase: return "teal"
        case .unknown: return "secondary"
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

    /// The folder this document belongs to, if any.
    public var folder: Folder?

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
        pageCount: Int = 0,
        folder: Folder? = nil
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
        self.folder = folder
    }
}
#else
public final class Document: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let rawText: String
    public let documentTypeRaw: String
    public let dateScanned: Date
    public let analysisResult: String?
    public let redFlags: [String]
    public let keyInsights: [String]
    public let thumbnailData: Data?
    public let pageImageData: [Data]
    public let pageCount: Int
    public let folder: String?

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
        pageCount: Int = 0,
        folder: String? = nil
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
        self.folder = folder
    }
}
#endif
