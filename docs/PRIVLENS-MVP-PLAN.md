# Privlens MVP Development Plan

> "Your documents, understood. Privately."

**App Store Listing:** Privlens - Private Document AI
**Author:** Peter Kim
**Created:** 2026-03-28
**Target App Store Submission:** May 8, 2026 (~6 weeks)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [App Architecture](#2-app-architecture)
3. [Core Features for MVP](#3-core-features-for-mvp)
4. [Data Model & Local Storage](#4-data-model--local-storage)
5. [UI/UX Flow](#5-uiux-flow)
6. [Technical Implementation Phases](#6-technical-implementation-phases)
7. [App Store Strategy](#7-app-store-strategy)
8. [Risk Register](#8-risk-register)
9. [Success Metrics](#9-success-metrics)

---

## 1. Executive Summary

### What We Are Building

Privlens is an iOS app that scans physical or digital documents, extracts text via on-device OCR, and runs the extracted content through Apple Foundation Models (the ~3B parameter LLM shipping with iOS 26) to produce structured, actionable insights -- summaries, key terms, red flags, and plain-English explanations. Every byte of processing happens on-device. Documents never leave the phone.

### Why This Exists

There is a gap in the market. Existing document scanners (Adobe Scan, Genius Scan, CamScanner) offer OCR but either lack AI analysis entirely or route data through cloud servers. General-purpose AI assistants (ChatGPT, Claude) offer excellent document analysis but require uploading sensitive documents to remote servers. No shipping product combines scanning, AI analysis, and complete on-device privacy.

With iOS 26 shipping Apple Foundation Models on-device, the technical barrier is gone. Privlens can deliver cloud-quality document understanding with zero cloud dependency.

### Why Now

- Apple Foundation Models ship with iOS 26 (fall 2026 public, developer beta summer 2026)
- 65% of iOS users opt out of tracking -- privacy demand is proven
- Privacy software market growing from $5.37B to $45.13B by 2034
- Document scanning market heading from ~$5B to $8-10B by 2030
- Apple actively promotes privacy-first apps -- feature potential is real

### Target Launch

| Milestone | Date |
|---|---|
| Development start | March 30, 2026 |
| Phase 0 complete (shell + CI) | April 5, 2026 |
| Phase 1 complete (scanning + OCR) | April 19, 2026 |
| Phase 2 complete (AI engine) | May 3, 2026 |
| Phase 3 complete (polish + monetization) | May 8, 2026 |
| App Store submission | May 8, 2026 |
| Target approval + launch | May 15, 2026 |

### MVP Document Types

Phase 1 (MVP): Medical Bills & EOBs, Insurance Policies, Lease Agreements

---

## 2. App Architecture

### High-Level Architecture Diagram

```
+------------------------------------------------------------------+
|                        Privlens iOS App                          |
|                                                                  |
|  +------------------+    +------------------+    +-----------+   |
|  |   Presentation   |    |    Domain Layer   |    |   Data    |   |
|  |     Layer         |    |                  |    |   Layer   |   |
|  |                  |    |                  |    |           |   |
|  |  SwiftUI Views   |--->|  ViewModels      |--->| SwiftData |   |
|  |  NavigationStack |    |  (@Observable)   |    | Models    |   |
|  |  Components      |    |                  |    | FileManager|  |
|  +------------------+    +--------+---------+    +-----------+   |
|                                   |                              |
|                    +--------------+--------------+               |
|                    |              |              |                |
|              +-----v----+  +-----v----+  +------v-----+         |
|              | Scanning  |  |    AI     |  | Document   |         |
|              | Service   |  |  Analysis |  | Storage    |         |
|              |           |  |  Engine   |  | Service    |         |
|              | - Camera  |  |           |  |            |         |
|              | - Photos  |  | - Prompt  |  | - Images   |         |
|              | - Files   |  |   Builder |  | - Text     |         |
|              | - Vision  |  | - Chunker |  | - Analysis |         |
|              |   OCR     |  | - FndnMdl |  | - Export   |         |
|              |           |  | - Output  |  |            |         |
|              +-----------+  |   Parser  |  +------------+         |
|                             +-----------+                        |
|                                                                  |
|  +------------------------------------------------------------+  |
|  |              Apple Frameworks (On-Device Only)              |  |
|  |  Vision | Foundation Models | Natural Language | Core ML    |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
            |
            | NOTHING leaves the device.
            | No network calls. No analytics. No telemetry.
```

### Pattern: MVVM with Service Layer

The app follows MVVM using Swift's `@Observable` macro (not the legacy `ObservableObject`). Business logic lives in ViewModels. Framework interactions are abstracted behind service protocols for testability.

### Module Breakdown

| Module | Responsibility | Key Types |
|---|---|---|
| `App` | Entry point, navigation, dependency injection | `PrivlensApp`, `AppRouter` |
| `Features/Scanning` | Camera capture, photo import, file import, OCR | `ScanningView`, `ScanningViewModel`, `OCRService` |
| `Features/Analysis` | AI pipeline, prompt construction, structured output | `AnalysisView`, `AnalysisViewModel`, `AnalysisEngine` |
| `Features/Library` | Document list, search, organization | `LibraryView`, `LibraryViewModel` |
| `Features/Insights` | Display analysis results, export | `InsightsView`, `InsightsViewModel` |
| `Features/Settings` | Pro unlock, preferences, about | `SettingsView`, `SettingsViewModel` |
| `Features/Onboarding` | First-launch privacy walkthrough | `OnboardingView` |
| `Services/OCR` | Vision framework OCR wrapper | `OCRService` protocol + `VisionOCRService` |
| `Services/AI` | Foundation Models wrapper, chunking, prompts | `AIService` protocol + `FoundationModelService` |
| `Services/Storage` | SwiftData operations, file management | `StorageService` |
| `Services/Monetization` | StoreKit 2 integration | `StoreService` |
| `Models` | SwiftData models, DTOs, enums | `Document`, `AnalysisResult`, `DocumentType` |
| `Shared` | Extensions, utilities, design tokens | `Color+`, `Font+`, `Constants` |

### Dependency Graph

```
Views --> ViewModels --> Services --> Apple Frameworks
                    --> Models (SwiftData)
```

All services are injected via SwiftUI `@Environment` or initializer injection. No singletons. This keeps everything testable with mock services in previews and unit tests.

### Concurrency Model (Swift 6)

- ViewModels are `@MainActor` (they drive UI)
- Services use structured concurrency (`async`/`await`)
- OCR and AI work dispatched to background via `Task` and actors
- `AIService` is an `actor` to serialize Foundation Model access
- Streaming responses use `AsyncSequence` for real-time UI updates

```swift
@MainActor
@Observable
final class AnalysisViewModel {
    var document: Document
    var analysisState: AnalysisState = .idle
    var streamedText: String = ""

    private let aiService: AIServiceProtocol
    private let storageService: StorageServiceProtocol

    func analyze() async {
        analysisState = .analyzing
        do {
            for try await chunk in aiService.analyzeStream(document: document) {
                streamedText += chunk
            }
            let result = try await aiService.parseStructuredResult(streamedText)
            document.analysisResult = result
            try storageService.save(document)
            analysisState = .complete
        } catch {
            analysisState = .failed(error)
        }
    }
}
```

---

## 3. Core Features for MVP

### 3.1 Document Scanning (Camera + Import)

**Camera Scanning**

| Spec | Detail |
|---|---|
| Framework | `VNDocumentCameraViewController` via `UIViewControllerRepresentable` |
| Multi-page | Yes, user can scan multiple pages in one session |
| Auto-detect | Automatic edge detection + perspective correction (built into Vision) |
| Output | Array of `UIImage` (one per page) |
| Storage | Saved as JPEG (quality 0.8) to app sandbox |

**Photo Library Import**

| Spec | Detail |
|---|---|
| Framework | `PhotosUI` / `PhotosPicker` (SwiftUI native) |
| Selection | Single or multi-image selection |
| Types | JPEG, PNG, HEIC |

**File Import**

| Spec | Detail |
|---|---|
| Framework | `UIDocumentPickerViewController` via representable |
| Types | PDF, images (JPEG/PNG/HEIC) |
| PDF handling | Render each page to image via `PDFKit`, then OCR |

**OCR Pipeline**

```swift
protocol OCRServiceProtocol: Sendable {
    func extractText(from images: [UIImage]) async throws -> ExtractedDocument
}

struct ExtractedDocument: Sendable {
    let pages: [PageText]
    let fullText: String
    let confidence: Double
}

struct PageText: Sendable {
    let pageNumber: Int
    let text: String
    let blocks: [TextBlock]  // preserves spatial layout
}

actor VisionOCRService: OCRServiceProtocol {
    func extractText(from images: [UIImage]) async throws -> ExtractedDocument {
        var pages: [PageText] = []
        for (index, image) in images.enumerated() {
            guard let cgImage = image.cgImage else { continue }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let observations = request.results else { continue }
            let blocks = observations.compactMap { obs -> TextBlock? in
                guard let text = obs.topCandidates(1).first else { return nil }
                return TextBlock(
                    text: text.string,
                    confidence: text.confidence,
                    boundingBox: obs.boundingBox
                )
            }
            let pageText = blocks.map(\.text).joined(separator: "\n")
            pages.append(PageText(pageNumber: index + 1, text: pageText, blocks: blocks))
        }
        let fullText = pages.map(\.text).joined(separator: "\n\n--- Page Break ---\n\n")
        let avgConfidence = pages.flatMap(\.blocks).map(\.confidence).reduce(0, +)
            / Double(max(pages.flatMap(\.blocks).count, 1))
        return ExtractedDocument(pages: pages, fullText: fullText, confidence: Double(avgConfidence))
    }
}
```

### 3.2 On-Device AI Analysis Pipeline

**Pipeline Flow**

```
Extracted Text
      |
      v
Text Preprocessor (NLP)
  - Section detection (headers, tables, lists)
  - Key entity extraction (dates, dollar amounts, names)
  - Token count estimation
      |
      v
Document Classifier
  - Classifies into: medical_bill, insurance_policy, lease, unknown
  - Uses keyword matching + NL framework (fast, no LLM needed)
      |
      v
Chunking Strategy (if > ~3500 tokens)
  - Split by detected sections
  - Each chunk gets section-level analysis
  - Final meta-summary pass combines chunk results
      |
      v
Prompt Template (type-specific)
  - Inserts extracted text + type-specific instructions
  - Requests structured output via @Generable schema
      |
      v
Apple Foundation Models (~3B params, on-device)
  - Streaming response (~30 tok/sec on A17 Pro)
  - Structured output via @Generable macro
      |
      v
Structured Analysis Result
  - Summary (plain English)
  - Key Terms & Dates
  - Red Flags / Concerns
  - Action Items
  - "What This Means For You"
```

**Structured Output with @Generable**

```swift
import FoundationModels

@Generable
struct DocumentAnalysis {
    @Guide(description: "A 2-3 sentence plain-English summary of the document")
    var summary: String

    @Guide(description: "Important terms, dates, and deadlines extracted from the document")
    var keyTerms: [KeyTerm]

    @Guide(description: "Potential concerns, unusual clauses, or items that need attention")
    var redFlags: [RedFlag]

    @Guide(description: "Specific actions the reader should take, with deadlines if applicable")
    var actionItems: [ActionItem]

    @Guide(description: "A plain-English explanation of what this document means for the reader")
    var whatThisMeansForYou: String
}

@Generable
struct KeyTerm {
    var term: String
    var value: String
    var category: TermCategory
}

@Generable
enum TermCategory: String {
    case date, money, duration, name, clause, other
}

@Generable
struct RedFlag {
    var title: String
    var explanation: String
    var severity: Severity
    var sourceQuote: String  // always ground in source text
}

@Generable
enum Severity: String {
    case low, medium, high
}

@Generable
struct ActionItem {
    var action: String
    var deadline: String?
    var priority: Priority
}

@Generable
enum Priority: String {
    case low, medium, high, urgent
}
```

**Chunked Summarization for Long Documents**

```swift
actor AnalysisEngine {
    private let model: SystemLanguageModel

    init() {
        self.model = SystemLanguageModel.default
    }

    func analyze(document: ExtractedDocument, type: DocumentType) async throws -> DocumentAnalysis {
        let tokenEstimate = document.fullText.count / 4  // rough approximation

        if tokenEstimate <= 3000 {
            // Single-pass analysis
            return try await singlePassAnalysis(text: document.fullText, type: type)
        } else {
            // Chunked analysis with meta-summary
            return try await chunkedAnalysis(document: document, type: type)
        }
    }

    private func chunkedAnalysis(
        document: ExtractedDocument,
        type: DocumentType
    ) async throws -> DocumentAnalysis {
        let sections = TextPreprocessor.splitIntoSections(document.fullText)
        var sectionResults: [DocumentAnalysis] = []

        for section in sections {
            let result = try await singlePassAnalysis(text: section, type: type)
            sectionResults.append(result)
        }

        // Meta-summary pass: combine section results into final analysis
        let combinedSummaries = sectionResults.map(\.summary).joined(separator: "\n")
        return try await metaSummary(sectionResults: sectionResults, type: type)
    }
}
```

**Document-Type-Specific Prompt Templates**

```swift
enum PromptTemplate {
    static func build(for type: DocumentType, text: String) -> String {
        let typeInstructions: String
        switch type {
        case .medicalBill:
            typeInstructions = """
            This is a medical bill or Explanation of Benefits (EOB).
            Pay special attention to:
            - Total amount owed vs. insurance-covered amount
            - Out-of-pocket costs and deductible status
            - Billing codes and whether charges seem standard
            - Payment deadlines and late fee terms
            - Whether this is a final bill or estimate
            Flag any charges that seem unusually high or duplicate.
            """
        case .insurancePolicy:
            typeInstructions = """
            This is an insurance policy document.
            Pay special attention to:
            - Coverage limits and exclusions
            - Deductibles and copay amounts
            - Renewal terms and cancellation clauses
            - Waiting periods and pre-existing condition clauses
            - Claim filing deadlines and procedures
            Flag any exclusions that could surprise the policyholder.
            """
        case .lease:
            typeInstructions = """
            This is a lease or rental agreement.
            Pay special attention to:
            - Monthly rent and security deposit amounts
            - Lease duration, renewal, and early termination terms
            - Maintenance responsibilities (landlord vs. tenant)
            - Pet policies, subletting rules, and guest restrictions
            - Move-out requirements and deposit return conditions
            Flag any clauses that are unusually restrictive or one-sided.
            """
        case .unknown:
            typeInstructions = """
            Analyze this document. Identify the most important information,
            obligations, deadlines, and anything that could affect the reader.
            """
        }

        return """
        You are a document analysis assistant. Analyze the following document
        and provide structured insights. Be specific and actionable.
        Always quote relevant text from the document to support your findings.

        \(typeInstructions)

        DOCUMENT TEXT:
        \(text)
        """
    }
}
```

### 3.3 Privacy-First Design

This is not a feature -- it is an architectural constraint. The app has zero network capability.

| Principle | Implementation |
|---|---|
| No network calls | App Transport Security set to deny all. No `URLSession` usage anywhere. |
| No analytics | No Firebase, no Mixpanel, no Amplitude, nothing. |
| No crash reporting | Rely on Apple's built-in crash reports via App Store Connect. |
| No third-party SDKs | Only Apple-provided frameworks. Zero CocoaPods/SPM dependencies at MVP. |
| Minimal permissions | Camera (for scanning), Photo Library (for import). No contacts, no location, no microphone. |
| No iCloud by default | Local storage only. Optional iCloud sync is user-initiated (post-MVP). |
| Privacy manifest | `PrivacyInfo.xcprivacy` declares zero tracking, zero required reason APIs (or only those needed with documented reasons). |
| On-device processing | Vision OCR + Apple Foundation Models = everything on-device |
| Source text grounding | Every AI-generated insight links back to the source quote to combat hallucination |

**App Transport Security Configuration (Info.plist)**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

The app literally cannot make network requests even if a bug tried to. StoreKit 2 for in-app purchases is the only framework that touches the network, and that is handled entirely by the OS.

### 3.4 Document Library & Organization

| Feature | Detail |
|---|---|
| List view | All scanned documents, sorted by date (newest first) |
| Search | Full-text search across document text and analysis results |
| Filters | By document type, by date range, by flagged/unflagged |
| Document detail | Tap to see original scan images + analysis results |
| Delete | Swipe to delete with confirmation. Deletes images, text, and analysis. |
| Re-analyze | Re-run analysis on existing document (e.g., after OS update improves model) |
| Export | Share analysis as plain text or PDF (post-MVP for PDF) |

---

## 4. Data Model & Local Storage

### SwiftData Schema

```swift
import SwiftData
import Foundation

@Model
final class Document {
    var id: UUID
    var title: String
    var documentType: DocumentType
    var createdAt: Date
    var updatedAt: Date
    var pageCount: Int

    // OCR results
    var extractedText: String
    var ocrConfidence: Double

    // Analysis
    @Relationship(deleteRule: .cascade)
    var analysisResult: AnalysisResultModel?
    var analysisStatus: AnalysisStatus

    // Image references (filenames in app sandbox, not stored in DB)
    var imageFileNames: [String]

    // User metadata
    var isFavorite: Bool
    var notes: String

    init(
        title: String,
        documentType: DocumentType = .unknown,
        extractedText: String = "",
        ocrConfidence: Double = 0,
        pageCount: Int = 0,
        imageFileNames: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.documentType = documentType
        self.createdAt = Date()
        self.updatedAt = Date()
        self.extractedText = extractedText
        self.ocrConfidence = ocrConfidence
        self.pageCount = pageCount
        self.imageFileNames = imageFileNames
        self.analysisStatus = .pending
        self.isFavorite = false
        self.notes = ""
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case medicalBill = "medical_bill"
    case insurancePolicy = "insurance_policy"
    case lease = "lease"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .medicalBill: "Medical Bill / EOB"
        case .insurancePolicy: "Insurance Policy"
        case .lease: "Lease Agreement"
        case .unknown: "Other Document"
        }
    }

    var icon: String {
        switch self {
        case .medicalBill: "cross.case.fill"
        case .insurancePolicy: "shield.fill"
        case .lease: "house.fill"
        case .unknown: "doc.fill"
        }
    }
}

enum AnalysisStatus: String, Codable {
    case pending
    case analyzing
    case complete
    case failed
}

@Model
final class AnalysisResultModel {
    var id: UUID
    var createdAt: Date
    var summary: String
    var whatThisMeansForYou: String

    @Relationship(deleteRule: .cascade)
    var keyTerms: [KeyTermModel]

    @Relationship(deleteRule: .cascade)
    var redFlags: [RedFlagModel]

    @Relationship(deleteRule: .cascade)
    var actionItems: [ActionItemModel]

    @Relationship(inverse: \Document.analysisResult)
    var document: Document?

    init(from analysis: DocumentAnalysis) {
        self.id = UUID()
        self.createdAt = Date()
        self.summary = analysis.summary
        self.whatThisMeansForYou = analysis.whatThisMeansForYou
        self.keyTerms = analysis.keyTerms.map { KeyTermModel(from: $0) }
        self.redFlags = analysis.redFlags.map { RedFlagModel(from: $0) }
        self.actionItems = analysis.actionItems.map { ActionItemModel(from: $0) }
    }
}

@Model
final class KeyTermModel {
    var term: String
    var value: String
    var category: String

    init(from keyTerm: KeyTerm) {
        self.term = keyTerm.term
        self.value = keyTerm.value
        self.category = keyTerm.category.rawValue
    }
}

@Model
final class RedFlagModel {
    var title: String
    var explanation: String
    var severity: String
    var sourceQuote: String

    init(from redFlag: RedFlag) {
        self.title = redFlag.title
        self.explanation = redFlag.explanation
        self.severity = redFlag.severity.rawValue
        self.sourceQuote = redFlag.sourceQuote
    }
}

@Model
final class ActionItemModel {
    var action: String
    var deadline: String?
    var priority: String

    init(from actionItem: ActionItem) {
        self.action = actionItem.action
        self.deadline = actionItem.deadline
        self.priority = actionItem.priority.rawValue
    }
}
```

### Image Storage Strategy

Images are NOT stored in SwiftData. They are saved as JPEG files in the app's `Documents` directory with a structured path:

```
Documents/
  scans/
    {document-uuid}/
      page_001.jpg
      page_002.jpg
      page_003.jpg
      thumbnail.jpg    (256px wide, for library grid)
```

The `Document` model stores only the filenames. This keeps the SwiftData database small and fast.

```swift
struct ImageStorageService {
    private let fileManager = FileManager.default

    var scansDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("scans", isDirectory: true)
    }

    func save(images: [UIImage], for documentID: UUID) throws -> [String] {
        let docDir = scansDirectory.appendingPathComponent(documentID.uuidString)
        try fileManager.createDirectory(at: docDir, withIntermediateDirectories: true)

        var fileNames: [String] = []
        for (index, image) in images.enumerated() {
            let fileName = String(format: "page_%03d.jpg", index + 1)
            let fileURL = docDir.appendingPathComponent(fileName)
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            try data.write(to: fileURL)
            fileNames.append(fileName)

            // Generate thumbnail from first page
            if index == 0, let thumbnail = image.preparingThumbnail(of: CGSize(width: 256, height: 256)) {
                let thumbURL = docDir.appendingPathComponent("thumbnail.jpg")
                try thumbnail.jpegData(compressionQuality: 0.7)?.write(to: thumbURL)
            }
        }
        return fileNames
    }

    func deleteImages(for documentID: UUID) throws {
        let docDir = scansDirectory.appendingPathComponent(documentID.uuidString)
        try fileManager.removeItem(at: docDir)
    }
}
```

### iCloud Sync Strategy (Post-MVP, User-Controlled)

Not included in MVP. When added:

- Use CloudKit via SwiftData's built-in sync (set `ModelConfiguration` with `cloudKitDatabase: .automatic`)
- Disabled by default -- user must explicitly enable in Settings
- Clear disclosure: "Your documents will be stored in YOUR iCloud account. Apple can access iCloud data."
- Images synced via CloudKit Assets
- Respect user's iCloud storage limits

---

## 5. UI/UX Flow

### Complete User Flow

```
App Launch
    |
    v
First Launch? --yes--> Onboarding (3 screens)
    |                       |
    no                      v
    |                   Library (empty state)
    v                       |
Library (populated)  <------+
    |
    +-- Tap "+" FAB --> Scan/Import Sheet
    |                       |
    |                  +----+----+
    |                  |    |    |
    |               Camera Photo Files
    |                  |    |    |
    |                  v    v    v
    |               Captured Images
    |                       |
    |                       v
    |               OCR Processing (progress)
    |                       |
    |                       v
    |               Document Preview
    |               - Shows extracted text
    |               - Auto-detected type (editable)
    |               - Title (auto-generated, editable)
    |               - [Analyze] button
    |                       |
    |                       v
    |               Analysis Running
    |               - Streaming text display
    |               - Progress indicator
    |               - ~15-45 seconds
    |                       |
    |                       v
    |               Insights Screen
    |               - Summary card
    |               - Key Terms list
    |               - Red Flags (color-coded)
    |               - Action Items (checkable)
    |               - "What This Means" card
    |               - [View Source] to see original text
    |                       |
    |                       v
    +---<--- Back to Library (document saved)
    |
    +-- Tap document --> Document Detail
    |                       |
    |                  +----+----+
    |                  |         |
    |               Scans    Analysis
    |               (images)  (insights)
    |                          |
    |                     [Re-Analyze]
    |                     [Export]
    |
    +-- Settings gear --> Settings
                            |
                      +-----+-----+
                      |     |     |
                    Pro   About  Privacy
                  Unlock  Info   Policy
```

### Screen-by-Screen Breakdown

#### Screen 1: Onboarding (first launch only, 3 pages)

| Page | Content |
|---|---|
| 1 | "Your documents, understood." -- Hero illustration of a document transforming into clear insights. |
| 2 | "100% Private." -- Emphasis that nothing leaves device. Show a phone with a lock icon. No cloud icons. |
| 3 | "Get Started" -- Camera permission request with explanation. Minimal, not aggressive. |

Design: Full-screen pages, swipeable. Subtle, professional. No cartoons. Dark mode by default with light mode support.

#### Screen 2: Library (Main Screen)

```
+----------------------------------+
|  Privlens              [Gear]    |
|  [Search bar]                    |
|  [All] [Medical] [Insurance]     |
|  [Lease]                         |
|                                  |
|  +---+  Medical Bill - Dr. Smith |
|  |img|  Analyzed Mar 28, 2026    |
|  +---+  2 red flags              |
|                                  |
|  +---+  Lease - 123 Oak St      |
|  |img|  Analyzed Mar 27, 2026    |
|  +---+  5 action items           |
|                                  |
|  (empty state: illustration +    |
|   "Scan your first document")    |
|                                  |
|                          [+ FAB] |
+----------------------------------+
```

- NavigationStack as root
- List with `.searchable` modifier
- Filter chips for document types
- Each row: thumbnail, title, date, quick stats (red flag count, action item count)
- Swipe actions: delete, favorite
- Floating action button (bottom-right) for new scan

#### Screen 3: Scan/Import Action Sheet

Presented as a `.confirmationDialog` or custom bottom sheet:
- Scan Document (camera)
- Choose from Photos
- Import from Files

#### Screen 4: Document Preview (Post-OCR)

```
+----------------------------------+
|  [Cancel]   New Document  [Save] |
|                                  |
|  [Image preview carousel]       |
|  Page 1 of 3                     |
|                                  |
|  Title: [Auto-generated title]   |
|                                  |
|  Type: [Medical Bill     v]      |
|  (auto-detected, dropdown to     |
|   override)                      |
|                                  |
|  Extracted Text:                 |
|  "Patient: John Smith..."        |
|  (scrollable, read-only)         |
|                                  |
|  OCR Confidence: 94%             |
|                                  |
|  [    Analyze Document     ]     |
|  (primary button, full width)    |
+----------------------------------+
```

#### Screen 5: Analysis Running

```
+----------------------------------+
|        Analyzing Document        |
|                                  |
|  [Animated progress ring]        |
|                                  |
|  Reading your document...        |
|                                  |
|  (Streaming text preview:)       |
|  "This medical bill from..."     |
|  (text appears word by word)     |
|                                  |
|  Estimated: ~30 seconds          |
+----------------------------------+
```

Uses `AsyncSequence` streaming to show text appearing in real time. Gives the user confidence that something is happening.

#### Screen 6: Insights (Analysis Results)

```
+----------------------------------+
|  [Back]    Insights    [Share]   |
|                                  |
|  -- Summary --                   |
|  "This is a medical bill from    |
|   City Hospital for $2,340.      |
|   Your insurance covered $1,890, |
|   leaving $450 out-of-pocket."   |
|                                  |
|  -- Key Terms --                 |
|  $ Total Billed     $2,340.00   |
|  $ Insurance Paid   $1,890.00   |
|  $ You Owe          $450.00     |
|  D Payment Due      Apr 15, 2026|
|                                  |
|  -- Red Flags (2) --             |
|  [!] Duplicate charge for labs   |
|      "CBC panel appears twice    |
|       on lines 4 and 7..."       |
|      Severity: HIGH              |
|                                  |
|  [!] Short payment window        |
|      "Payment due in 15 days..." |
|      Severity: MEDIUM            |
|                                  |
|  -- Action Items --              |
|  [ ] Call billing dept about     |
|      duplicate CBC charge        |
|      By: Apr 1, 2026             |
|  [ ] Pay $450 or set up plan     |
|      By: Apr 15, 2026            |
|                                  |
|  -- What This Means For You --   |
|  "You had a procedure at City    |
|   Hospital. Most of it was       |
|   covered by insurance, but..."  |
|                                  |
|  [View Original Document]        |
|                                  |
|  -- Disclaimer --                |
|  "AI-generated analysis. Not     |
|   legal or medical advice.       |
|   Always verify with the         |
|   original document."            |
+----------------------------------+
```

- Each section is a collapsible card
- Red flags are color-coded by severity (red/orange/yellow)
- Source quotes shown in gray italic beneath each red flag
- Action items are interactive checkboxes (state persisted)
- "View Original Document" links to image viewer with extracted text overlay
- Disclaimer is always visible at the bottom

#### Screen 7: Settings

```
+----------------------------------+
|  [Back]      Settings            |
|                                  |
|  -- Privlens Pro --              |
|  [Unlock Privlens Pro - $X.XX]   |
|  Unlimited analyses, red flags,  |
|  key term extraction, and more.  |
|                                  |
|  -- About --                     |
|  Version 1.0.0                   |
|  Privacy Policy                  |
|  Terms of Service                |
|                                  |
|  -- Data --                      |
|  Delete All Documents            |
|                                  |
|  -- Privacy --                   |
|  "Privlens processes everything  |
|   on your device. We have no     |
|   servers. We collect nothing."   |
+----------------------------------+
```

---

## 6. Technical Implementation Phases

### Phase 0: Project Setup, CI, Basic App Shell (1 week)

**Timeline:** March 30 - April 5, 2026

| Task | Details | Days |
|---|---|---|
| Create Xcode project | iOS 26 target, SwiftUI lifecycle, Swift 6 strict concurrency | 0.5 |
| Project structure | Create all module folders per architecture section | 0.5 |
| SwiftData setup | Configure `ModelContainer`, define all `@Model` types (can be stubs) | 0.5 |
| Navigation shell | `NavigationStack` + `TabView` or single-stack with router | 0.5 |
| Design system | Color palette, typography scale, spacing tokens, dark mode | 1 |
| Git repo + CI | GitHub repo, branch protection, basic Xcode Cloud or GitHub Actions (build + test) | 0.5 |
| Onboarding screens | Static onboarding flow (3 pages) | 0.5 |
| Empty library screen | Library view with empty state, FAB, basic navigation | 0.5 |
| Settings skeleton | Settings screen with static content, StoreKit 2 product stub | 0.5 |

**Deliverable:** App launches, shows onboarding on first run, navigates to empty library, settings accessible. All SwiftData models compile. CI runs green.

**Milestone checklist:**
- [ ] App builds and runs on device (iOS 26 beta)
- [ ] Onboarding flow works
- [ ] Empty library screen with FAB
- [ ] Navigation to all screens (even if empty)
- [ ] SwiftData models defined and container configured
- [ ] CI pipeline runs build + test on every push

### Phase 1: Scanning + OCR Pipeline (2 weeks)

**Timeline:** April 6 - April 19, 2026

**Week 1: Scanning**

| Task | Details | Days |
|---|---|---|
| Camera scanning | Integrate `VNDocumentCameraViewController`, handle delegate callbacks | 1 |
| Photo picker | `PhotosPicker` integration, multi-select | 0.5 |
| File import | `UIDocumentPickerViewController` for PDF + images | 0.5 |
| PDF page rendering | `PDFKit` to render PDF pages as images for OCR | 0.5 |
| Image storage | `ImageStorageService` -- save scanned images to sandbox, thumbnail generation | 1 |
| Scan flow UI | Complete scan/import sheet, image preview carousel | 1.5 |

**Week 2: OCR + Classification**

| Task | Details | Days |
|---|---|---|
| Vision OCR service | `VisionOCRService` implementation with accurate recognition | 1 |
| Text preprocessing | Section detection, NL framework entity extraction | 1 |
| Document classifier | Keyword-based + NL framework classification into document types | 1 |
| Document preview screen | Show extracted text, auto-detected type, editable title | 1 |
| SwiftData persistence | Save documents with images, text, and metadata | 0.5 |
| Library integration | Documents appear in library after scanning, thumbnails, search | 0.5 |

**Deliverable:** User can scan via camera, import from photos/files, see extracted text, auto-classified type, save to library, search and browse saved documents.

**Milestone checklist:**
- [ ] Camera scanning works, multi-page
- [ ] Photo library import works
- [ ] PDF file import works
- [ ] OCR extracts text with >90% accuracy on clean documents
- [ ] Document type auto-detected
- [ ] Documents persist in library across app restarts
- [ ] Search works across document text
- [ ] Thumbnails display in library list

### Phase 2: AI Analysis Engine + Structured Output (2 weeks)

**Timeline:** April 20 - May 3, 2026

**Week 1: Core AI Engine**

| Task | Details | Days |
|---|---|---|
| FoundationModelService | Wrapper around Apple Foundation Models, session management | 1 |
| Prompt templates | Type-specific prompts for medical bill, insurance, lease, unknown | 1 |
| @Generable models | Structured output types, test generation on device | 1 |
| Chunking engine | Token estimation, section-based splitting, meta-summary pass | 1 |
| Streaming UI | Real-time text display during analysis | 1 |

**Week 2: Integration + Results Display**

| Task | Details | Days |
|---|---|---|
| Analysis flow | Wire up: scan -> OCR -> classify -> prompt -> analyze -> save | 1 |
| Insights screen | Full insights display: summary, key terms, red flags, actions, explainer | 2 |
| Source grounding | Tap any insight to see the source quote highlighted in original text | 1 |
| Re-analysis | Re-analyze existing documents | 0.5 |
| Error handling | Graceful failure for model unavailability, low memory, timeouts | 0.5 |

**Deliverable:** Complete pipeline works end-to-end. User scans a medical bill and gets a structured analysis with summary, key terms, red flags, action items, and a plain-English explanation.

**Milestone checklist:**
- [ ] Analysis runs end-to-end on all 3 document types
- [ ] Structured output parses correctly via @Generable
- [ ] Chunked analysis works for documents longer than 4K token context
- [ ] Streaming text appears during analysis
- [ ] Insights screen displays all sections with proper formatting
- [ ] Red flags show severity and source quotes
- [ ] Action items are interactive checkboxes
- [ ] Source text viewable alongside insights
- [ ] Disclaimer displayed
- [ ] Re-analyze works on existing documents

### Phase 3: Polish, Monetization, App Store Prep (1 week)

**Timeline:** May 4 - May 8, 2026

| Task | Details | Days |
|---|---|---|
| StoreKit 2 integration | Configure products in ASC, implement paywall, purchase flow, restore | 1 |
| Free tier limits | 3 analyses/month counter, gate premium features behind Pro | 0.5 |
| Export (plain text) | Share analysis as formatted plain text via `ShareLink` | 0.5 |
| Visual polish | Animations, transitions, loading states, haptic feedback | 1 |
| Privacy manifest | `PrivacyInfo.xcprivacy`, audit all API usage | 0.5 |
| App Store assets | Screenshots (6.7", 6.1"), app icon, preview video (optional) | 0.5 |
| App Store listing | Title, subtitle, description, keywords, privacy labels | 0.5 |
| Final testing | Full regression on device, edge cases, memory profiling | 0.5 |

**Deliverable:** App is ready for App Store submission. Monetization works. All screens polished. Privacy manifest complete.

**Milestone checklist:**
- [ ] IAP purchase and restore work correctly
- [ ] Free tier limits enforced (3/month)
- [ ] Pro unlock removes limits
- [ ] Export works
- [ ] No crashes on supported devices
- [ ] Memory usage acceptable (< 200MB peak during analysis)
- [ ] App icon finalized
- [ ] Screenshots captured for both sizes
- [ ] App Store listing complete
- [ ] Privacy manifest complete and accurate
- [ ] TestFlight build distributed for external beta test
- [ ] Submit to App Store review

---

## 7. App Store Strategy

### App Store Listing

**App Name:** Privlens - Private Document AI

**Subtitle:** Scan. Understand. Privately.

**Description:**

```
Privlens scans your documents and uses on-device AI to give you
clear, actionable insights -- without ever sending your data to
the cloud.

UNDERSTAND YOUR DOCUMENTS IN SECONDS
Point your camera at a medical bill, insurance policy, or lease
agreement. Privlens extracts the text, identifies the document
type, and explains what it means for you in plain English.

100% ON-DEVICE. ZERO CLOUD.
Every byte of processing happens on your iPhone. Your documents
are never uploaded, transmitted, or shared. Period. We have no
servers. We collect no data.

WHAT YOU GET
- Plain-English document summaries
- Key terms, dates, and amounts highlighted
- Red flags and unusual clauses identified
- Specific action items with deadlines
- "What This Means For You" explanations

BUILT FOR REAL DOCUMENTS
- Medical bills and Explanation of Benefits (EOBs)
- Insurance policies
- Lease and rental agreements
- More document types coming soon

POWERED BY ON-DEVICE AI
Uses Apple's built-in AI models -- the same technology in your
iPhone -- to analyze documents locally. No internet required.

PRIVLENS PRO
Unlock unlimited document analyses, detailed red flag detection,
key term extraction, and document comparison with a one-time
purchase. No subscriptions.
```

**Keywords:**

```
document,scanner,AI,privacy,OCR,medical,bill,lease,insurance,
analyzer,on-device,private,scan
```

(100 character limit, no spaces after commas)

### Keyword Strategy

| Primary | Secondary | Long-tail |
|---|---|---|
| document scanner | medical bill analyzer | private document AI |
| AI document analyzer | lease agreement reader | on-device OCR |
| private scanner | insurance policy analyzer | no cloud scanner |
| OCR scanner | document AI | document privacy |

### Screenshot Plan (6 Screens)

| # | Screen | Message |
|---|---|---|
| 1 | Library with documents | "All your documents, one place." |
| 2 | Camera scanning a document | "Point. Scan. Done." |
| 3 | Insights screen (summary + red flags) | "AI-powered insights. On-device." |
| 4 | Red flags detail view | "Catch what you'd miss." |
| 5 | Action items view | "Know exactly what to do." |
| 6 | Privacy emphasis (lock icon + text) | "Your documents never leave your iPhone." |

**Style:** Clean, minimal chrome. Dark mode. Real (but fake) document content. Large text overlays with benefit statements.

### Privacy Nutrition Label

| Category | Declaration |
|---|---|
| Data Used to Track You | None |
| Data Linked to You | None |
| Data Not Linked to You | None |
| Data Collected | None |

This is the cleanest possible privacy label. It is a genuine competitive advantage -- call it out in marketing.

### Launch Marketing Checklist

- [ ] Press kit with screenshots + app description
- [ ] Post on Hacker News ("Show HN: Privlens -- On-device AI document analyzer for iOS")
- [ ] Post on r/apple, r/privacy, r/iphone
- [ ] Tweet thread about building with Apple Foundation Models
- [ ] Product Hunt launch
- [ ] Contact Apple Developer Relations about featuring potential (privacy narrative)
- [ ] Blog post: "Why we built a document scanner with zero servers"

---

## 8. Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Apple Foundation Models not available in iOS 26 beta during dev period | Low | Critical | Begin OCR pipeline first (Phase 1). Stub AI service with hardcoded responses. Swap in real model when available. |
| R2 | 4K token context too small for long documents | High | High | Chunked summarization already designed into architecture. Section-by-section analysis with meta-summary pass. Test with real 10+ page documents early. |
| R3 | Model hallucinations produce incorrect analysis | High | High | Always show source quotes. Disclaimer on every analysis. Never present AI output as authoritative. Use structured output (@Generable) to constrain responses. |
| R4 | @Generable structured output fails or returns malformed data | Medium | High | Implement fallback to raw text parsing with regex extraction. Cache partially completed analysis. Allow user to see raw AI output if structured parsing fails. |
| R5 | Analysis takes too long (>60 seconds), user abandons | Medium | Medium | Streaming UI shows progress in real time. Benchmark early on target devices. Optimize prompt length. Set user expectation in UI ("~30 seconds"). Allow background processing with notification. |
| R6 | OCR accuracy poor on certain document types | Medium | Medium | Use `.accurate` recognition level. Test with real documents from each category. Show OCR confidence to user. Allow manual text correction post-MVP. |
| R7 | App Store rejection | Low | High | No private APIs. Clean privacy manifest. Follow IAP guidelines exactly. Pre-submission review with Apple guidelines checklist. Prepare for resubmission within 48 hours. |
| R8 | Memory pressure on A17 Pro during analysis | Medium | Medium | Profile memory during development. Implement `didReceiveMemoryWarning` handling. Process images sequentially, not all at once. Release image data after OCR extraction. |
| R9 | Competitors ship similar feature before launch | Low | Medium | Speed to market is the mitigation. MVP in 6 weeks. First-mover on Apple Foundation Models + scanning combo. Brand around privacy. |
| R10 | StoreKit 2 issues (purchase not recognized, restore fails) | Low | High | Test IAP extensively in sandbox. Implement receipt validation. Handle all StoreKit error states. Support restore purchases prominently. |
| R11 | iOS 26 beta instability during development | Medium | Medium | Keep a stable Xcode 17 + iOS 26 beta environment. Test on physical device daily. File Feedback Assistant bugs early. Have a second device with stable beta. |
| R12 | Low conversion rate on one-time purchase | Medium | Medium | A/B test price points ($9.99 vs $14.99). Add annual subscription option alongside. Show clear value before paywall (free tier demonstrates quality). |

---

## 9. Success Metrics

### Launch KPIs (First 30 Days)

| Metric | Target | How Measured |
|---|---|---|
| Downloads | 1,000+ | App Store Connect |
| Day 1 retention | > 40% | App Store Connect (standard cohort) |
| Day 7 retention | > 20% | App Store Connect |
| Documents scanned (per active user) | > 3 | On-device counter (never transmitted) |
| Analysis completion rate | > 80% | On-device counter (started vs completed) |
| Pro conversion rate | > 5% of installers | StoreKit transaction count / downloads |
| App Store rating | >= 4.5 stars | App Store Connect |
| Crash-free rate | > 99.5% | Xcode Organizer / App Store Connect |
| App Store review approval | First submission | App Store Connect |

### How Metrics Are Tracked WITHOUT Analytics

Since we collect no analytics and make no network calls:

- **Downloads, retention, crashes:** Available in App Store Connect (Apple provides this by default for all apps, no SDK needed)
- **Revenue, conversion:** Available in App Store Connect financial reports and StoreKit dashboard
- **On-device usage metrics:** Store a local-only counter in `UserDefaults` for documents scanned and analyses completed. This data never leaves the device. It is for the user's own reference (e.g., "You've analyzed 12 documents") and useful during development/testing.
- **App Store ratings:** Prompt for review via `SKStoreReviewController` after 3rd successful analysis.

### 90-Day Goals

| Metric | Target |
|---|---|
| Total downloads | 5,000+ |
| Monthly active users | 1,500+ |
| Pro purchases | 250+ ($2,500-$3,750 revenue) |
| Average rating | >= 4.5 with 50+ ratings |
| Phase 2 document types shipped | 3 (tax, employment, NDA) |

### Longer-Term Signals to Watch

- Apple feature or editorial mention
- Organic search ranking for "private document scanner"
- User reviews mentioning privacy as a reason for choosing Privlens
- Request volume for new document types (signals product-market fit)

---

## Appendix A: Development Environment Setup

| Tool | Version |
|---|---|
| Xcode | 17.0+ beta (iOS 26 SDK) |
| Swift | 6.x |
| Minimum deployment target | iOS 26.0 |
| Test device | iPhone 15 Pro or later (A17 Pro required for Foundation Models) |
| Source control | Git + GitHub |
| CI/CD | Xcode Cloud or GitHub Actions |
| Dependencies | None (Apple frameworks only) |

## Appendix B: File/Folder Structure

```
Privlens/
  App/
    PrivlensApp.swift
    AppRouter.swift
    ContentView.swift
  Features/
    Onboarding/
      OnboardingView.swift
    Library/
      LibraryView.swift
      LibraryViewModel.swift
      DocumentRowView.swift
    Scanning/
      ScanningView.swift
      ScanningViewModel.swift
      CameraScanner.swift        (UIViewControllerRepresentable)
      DocumentPreviewView.swift
      DocumentPreviewViewModel.swift
    Analysis/
      AnalysisView.swift
      AnalysisViewModel.swift
      StreamingTextView.swift
    Insights/
      InsightsView.swift
      InsightsViewModel.swift
      SummaryCard.swift
      KeyTermsSection.swift
      RedFlagsSection.swift
      ActionItemsSection.swift
      WhatThisMeansCard.swift
    Settings/
      SettingsView.swift
      SettingsViewModel.swift
      PaywallView.swift
  Services/
    OCR/
      OCRServiceProtocol.swift
      VisionOCRService.swift
    AI/
      AIServiceProtocol.swift
      FoundationModelService.swift
      AnalysisEngine.swift
      PromptTemplate.swift
      TextPreprocessor.swift
      DocumentClassifier.swift
    Storage/
      StorageService.swift
      ImageStorageService.swift
    Monetization/
      StoreService.swift
  Models/
    Document.swift
    AnalysisResultModel.swift
    KeyTermModel.swift
    RedFlagModel.swift
    ActionItemModel.swift
    DocumentType.swift
    GenerableTypes.swift         (@Generable structs for Foundation Models)
  Shared/
    Extensions/
      Color+Privlens.swift
      Font+Privlens.swift
      View+Helpers.swift
    Components/
      LoadingView.swift
      ErrorView.swift
      SeverityBadge.swift
    Constants.swift
  Resources/
    Assets.xcassets
    PrivacyInfo.xcprivacy
  Tests/
    ServicesTests/
      VisionOCRServiceTests.swift
      AnalysisEngineTests.swift
      DocumentClassifierTests.swift
    ViewModelTests/
      LibraryViewModelTests.swift
      AnalysisViewModelTests.swift
    ModelTests/
      DocumentTests.swift
```

## Appendix C: Quick Reference -- Apple Foundation Models API

```swift
import FoundationModels

// Basic generation
let model = SystemLanguageModel.default
let response = try await model.generate("Summarize this document: ...")

// Streaming
for try await token in model.generateStream("Summarize...") {
    print(token, terminator: "")
}

// Structured output with @Generable
@Generable
struct Summary {
    @Guide(description: "A brief summary")
    var text: String
    @Guide(description: "Key dates mentioned")
    var dates: [String]
}

let result: Summary = try await model.generate(
    "Extract a summary and dates from: ...",
    as: Summary.self
)

// Check availability
if SystemLanguageModel.isAvailable {
    // proceed
} else {
    // show "requires iPhone 15 Pro or later" message
}
```

---

**This plan is ready to execute. Start with Phase 0 on March 30, 2026.**
