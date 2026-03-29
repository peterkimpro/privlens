# Privlens

**Your documents, understood. Privately.**

Privlens is a private, on-device AI document analyzer for iOS. Scan any document, get plain-English insights, and never send a single byte to the cloud.

> **App Store listing:** Privlens - Private Document AI

---

## Table of Contents

1. [Product Vision](#product-vision)
2. [Product Requirements (PRD)](#product-requirements-prd)
3. [System Requirements (SRD)](#system-requirements-srd)
4. [Features](#features)
5. [Technical Architecture](#technical-architecture)
6. [User Flows](#user-flows)
7. [Document Types](#document-types)
8. [Monetization](#monetization)
9. [Roadmap](#roadmap)
10. [Marketing Strategy](#marketing-strategy)
11. [Competitive Analysis](#competitive-analysis)
12. [Risk & Mitigations](#risk--mitigations)
13. [Development Setup](#development-setup)

---

## Product Vision

**Problem:** People deal with complex documents every day -- medical bills, leases, insurance policies, contracts -- and don't understand them. Existing tools either scan without analyzing (Adobe Scan, Genius Scan) or analyze via cloud (ChatGPT, Claude), forcing users to upload sensitive documents to external servers.

**Solution:** Privlens combines document scanning + AI-powered analysis + 100% on-device processing. No cloud. No API costs. No privacy trade-offs.

**Why now:**
- Apple Foundation Models (~3B param on-device LLM) shipped with iOS 26, enabling real AI analysis without cloud
- 65% of iOS users opt out of tracking -- privacy is a default expectation
- Foundation Models adoption has been "slower than anticipated" -- first-mover window is wide open
- GenAI apps generated $5B+ in IAP revenue in 2025, tripling YoY

**Target user:** Any iPhone user who deals with confusing documents and cares about privacy (200M+ US adults).

---

## Product Requirements (PRD)

### Core Value Proposition

| What | Detail |
|------|--------|
| **One-line pitch** | Scan any document, get a plain-English summary with key terms, red flags, and action items -- all on-device |
| **Differentiator** | Only app that combines scanning + AI analysis + on-device processing |
| **Privacy promise** | Documents never leave the device. Zero network calls for analysis. Period. |
| **Revenue model** | Soft paywall: 7-day reverse trial → free tier (3 analyses/month) → Pro annual ($29.99/yr) or Lifetime ($49.99) |

### User Stories

**P0 -- Must Have (MVP)**
- As a user, I can scan a document using my camera and get a clean digital copy
- As a user, I can import documents from Photos, Files, or other apps
- As a user, I can get a plain-English summary of any scanned document
- As a user, I can see key terms, dates, and amounts extracted from my document
- As a user, I can see red flags and hidden clauses highlighted with explanations
- As a user, I can see action items ("things you should do") based on the document
- As a user, I can view the source text alongside every AI interpretation
- As a user, I know that nothing leaves my device (visible privacy indicators)
- As a user, I can organize my analyzed documents in folders
- As a user, I get 7 days of full Pro access when I first install the app
- As a user, I can unlock unlimited analyses with a subscription or lifetime purchase

**P1 -- Should Have (v1.1)**
- As a user, I can compare two documents side-by-side (e.g., old lease vs new lease)
- As a user, I can export analysis results as PDF or share via native share sheet
- As a user, I can search across all my analyzed documents
- As a user, I can see a "What This Means For You" section in plain language
- As a user, I can add personal notes to any document analysis

**P2 -- Nice to Have (v2.0)**
- As a user, I can ask follow-up questions about my document
- As a user, I can auto-detect the document type without selecting manually
- As a user, I can process documents in multiple languages
- As a user, I can batch-analyze a stack of related documents (e.g., closing package)
- As a user, I can set reminders for key dates found in documents

### Success Metrics

| Metric | Target | Timeframe |
|--------|--------|-----------|
| App Store downloads | 500K | Year 1 |
| Free-to-paid conversion | 5%+ | Ongoing |
| App Store rating | 4.5+ stars | Ongoing |
| Day-7 retention | 40%+ | Ongoing |
| Revenue | $300K-$500K | Year 1 |

### Constraints

- **iOS 26+ only** (required for Apple Foundation Models)
- **A17 Pro / M1 chip minimum** (required for Apple Intelligence)
- **4,096 token context window** (input + output combined) -- requires chunking strategy for long documents
- **Text-only LLM** -- Vision framework handles all image/camera input, Foundation Models handles reasoning
- **No backend** -- local-first architecture, no servers to maintain
- **No legal/medical advice** -- always disclaim AI analysis, show source text

---

## System Requirements (SRD)

### Minimum Device Requirements

| Requirement | Specification |
|-------------|--------------|
| **Operating System** | iOS 26.0+ |
| **Processor** | A17 Pro or M1 chip (or newer) |
| **Compatible Devices** | iPhone 15 Pro, 15 Pro Max, 16 series, 17 series, all M-series iPads |
| **Storage** | ~50MB app install + user documents |
| **Network** | Not required (fully offline) |
| **Camera** | Required for document scanning (rear camera) |

### Frameworks & Dependencies

| Framework | Version | Purpose |
|-----------|---------|---------|
| **SwiftUI** | iOS 26+ | UI layer -- declarative, modern, fast dev velocity |
| **Apple Foundation Models** | iOS 26+ | On-device LLM (~3B params) for document analysis |
| **Vision** | iOS 26+ | OCR, text recognition, document detection |
| **VisionKit** | iOS 26+ | Camera-based document capture with edge detection |
| **NaturalLanguage** | iOS 26+ | Tokenization, NER, language detection |
| **SwiftData** | iOS 26+ | Local persistent storage for documents & analyses |
| **StoreKit 2** | iOS 26+ | In-app purchases, paywall |
| **RevenueCat SDK** | Latest | Purchase management, analytics, A/B testing |

### Architecture Requirements

| Requirement | Detail |
|-------------|--------|
| **Architecture pattern** | MVVM with SwiftUI |
| **Data persistence** | SwiftData (local SQLite) -- no CloudKit, no sync |
| **Network calls** | ZERO for core functionality. Only StoreKit/RevenueCat for purchases |
| **Permissions** | Camera (scanning), Photo Library (import) -- nothing else |
| **Data encryption** | iOS Data Protection (Complete Protection class) for stored documents |
| **Concurrency** | Swift Concurrency (async/await, actors) for all AI processing |
| **Minimum test coverage** | Unit tests for document parsing, AI prompt templates, chunking logic |

### Performance Requirements

| Metric | Target |
|--------|--------|
| **App launch** | < 2 seconds to interactive |
| **Document scan** | < 1 second capture-to-OCR |
| **AI analysis (1-page doc)** | < 5 seconds |
| **AI analysis (10-page doc)** | < 30 seconds (chunked) |
| **Token generation** | ~30 tokens/sec (Apple Silicon baseline) |
| **Memory usage** | < 200MB during analysis |
| **App size** | < 50MB (no bundled models -- Apple provides them) |

---

## Features

### MVP Features (Phase 1 -- Launch)

#### Document Scanning
- Camera-based scanning with VisionKit
- Automatic edge detection and perspective correction
- Multi-page document capture
- Import from Photos, Files app, or any share source
- High-quality OCR via Vision framework

#### AI-Powered Analysis
- **Plain-English Summary** -- "Here's what this document says in simple terms"
- **Key Terms & Dates** -- Important amounts, deadlines, parties, obligations extracted
- **Red Flag Detection** -- Hidden fees, penalty clauses, unusual terms highlighted
- **Action Items** -- "Things you should do" based on the document content
- **Source Attribution** -- Every AI insight links back to the exact source text

#### Privacy & Trust
- 100% on-device processing -- no network calls for analysis
- Privacy indicator visible during analysis ("Processing on your iPhone")
- Minimal permissions (Camera + Photos only)
- Clean App Privacy Nutrition Label
- No accounts, no sign-up, no tracking

#### Document Management
- Folder organization
- Document thumbnails and previews
- Date-based sorting
- Swipe-to-delete

#### Paywall
- 7-day reverse trial (full Pro access, no payment info required)
- After trial: 3 free AI analyses per month (unlimited scanning + OCR always free)
- Pro unlock: $4.99/mo, $29.99/yr, or $49.99 lifetime
- StoreKit 2 + RevenueCat integration
- Review prompt triggered after 2nd successful analysis

### v1.1 Features (Phase 2)

- **Document Comparison** -- Side-by-side analysis of two versions
- **Export & Share** -- PDF export of analysis, native share sheet
- **Full-Text Search** -- Search across all analyzed documents
- **Custom Notes** -- Add personal annotations to any analysis
- **Additional Document Types** -- Tax forms (W-2, 1099), employment contracts, NDAs
- **Paywall optimization** -- A/B test tighter limits based on review velocity

### v2.0 Features (Phase 3)

- **Follow-Up Questions** -- Ask the AI about specific parts of your document
- **Smart Auto-Detection** -- Automatically classify document type
- **Batch Analysis** -- Process a stack of related documents
- **Date Reminders** -- Set alerts for key dates found in documents
- **Government Forms** -- Immigration, benefits, court paperwork
- **Multi-Language Support** -- Analysis in 9 Foundation Models-supported languages

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Privlens App                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐  │
│  │   SwiftUI    │    │  View Models │    │  SwiftData │  │
│  │   Views      │◄──►│  (MVVM)      │◄──►│  Store    │  │
│  └──────────────┘    └──────┬───────┘    └───────────┘  │
│                             │                           │
│                    ┌────────▼────────┐                   │
│                    │  Analysis Engine │                  │
│                    └────────┬────────┘                   │
│                             │                           │
│         ┌───────────────────┼───────────────────┐       │
│         │                   │                   │       │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌───────▼─────┐ │
│  │  VisionKit  │    │   Vision    │    │  Foundation  │ │
│  │  (Camera    │    │   (OCR /    │    │   Models    │ │
│  │   Capture)  │    │   Text Rec) │    │  (On-Device │ │
│  └─────────────┘    └─────────────┘    │    LLM)     │ │
│                                        └─────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │              ALL PROCESSING ON-DEVICE            │    │
│  │           Zero network calls for analysis        │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │  StoreKit 2  │    │  RevenueCat  │  (only network)   │
│  │  (Purchases) │    │  (Analytics) │                   │
│  └──────────────┘    └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

### Analysis Pipeline

```
Document Input (Camera / Photos / Files)
       │
       ▼
VisionKit — Document capture with edge detection
       │
       ▼
Vision Framework — On-device OCR (text recognition)
       │
       ▼
Text Preprocessing
  ├── Section detection
  ├── Table extraction
  └── NaturalLanguage NER (names, dates, amounts)
       │
       ▼
Document Classifier — What type? (lease, medical bill, tax form, etc.)
       │
       ▼
Type-Specific Prompt Template — Optimized per document category
       │
       ▼
Chunking Engine (if document > 4K token limit)
  ├── Split into semantic sections
  ├── Summarize each chunk independently
  └── Meta-summary across all chunks
       │
       ▼
Apple Foundation Models — On-device ~3B param LLM
       │
       ▼
Structured Output via @Generable macro
  ├── PlainEnglishSummary
  ├── KeyTerms: [Term, Value, SourceLocation]
  ├── RedFlags: [Flag, Severity, Explanation, SourceText]
  ├── ActionItems: [Action, Priority, Deadline?]
  └── WhatThisMeansForYou: String
```

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **LLM** | Apple Foundation Models only | Zero cost, zero latency, zero privacy risk. No cloud fallback needed for MVP |
| **Structured output** | `@Generable` macro | Type-safe Swift structs from LLM output. No JSON parsing hacks |
| **Long doc handling** | Section-by-section chunking → meta-summary | Proven pattern for 4K context limit. 30-page lease = ~10 chunks |
| **Storage** | SwiftData (local SQLite) | No backend needed. Fast, reliable, encrypted by iOS |
| **No CloudKit sync** | Deliberate omission | Privacy-first = no cloud. Users can export/share manually |
| **MVVM** | Standard SwiftUI pattern | Best balance of testability and dev velocity for solo dev |

### Foundation Models Integration

```swift
// Core analysis call -- as simple as 3 lines
let session = LanguageModelSession()
let response = try await session.respond(to: prompt)

// Structured output with @Generable
@Generable
struct DocumentAnalysis {
    var summary: String
    var keyTerms: [KeyTerm]
    var redFlags: [RedFlag]
    var actionItems: [ActionItem]
}

// Type-specific prompt template
let prompt = """
You are a document analyst. Analyze this \(documentType) and extract:
1. A plain-English summary (2-3 sentences)
2. All key terms, dates, and amounts
3. Any red flags, hidden fees, or unusual clauses
4. Recommended action items for the reader

Document text:
\(ocrText)
"""
```

---

## User Flows

### Primary Flow: Scan & Analyze

```
[Launch App]
     │
     ▼
[Home Screen — Document List]
     │
     ├── Tap "+" → [Camera Scan]
     │                  │
     │                  ▼
     │            [Auto-detect edges]
     │                  │
     │                  ▼
     │            [Capture pages] (multi-page support)
     │                  │
     │                  ▼
     │            [Confirm scan]
     │
     ├── Tap "Import" → [Photo Library / Files picker]
     │
     ▼
[Select Document Type] (or auto-detect in v2)
  ├── Medical Bill / EOB
  ├── Lease Agreement
  ├── Insurance Policy
  ├── Contract / NDA
  ├── Tax Form
  └── Other
     │
     ▼
[Analyzing...] (on-device indicator, ~3-15 sec)
     │
     ▼
[Analysis Results Screen]
  ├── Summary tab — plain-English overview
  ├── Key Terms tab — extracted dates, amounts, parties
  ├── Red Flags tab — hidden fees, penalties, unusual clauses
  ├── Actions tab — recommended next steps
  └── Source tab — original document with highlights
     │
     ▼
[Save to Library] → [Home Screen]
```

### Paywall Flow

```
[First Launch]
     │
     ▼
[Welcome — "You have 7 days of full Pro access"]
     │
     ▼
[Days 1-7: Full Pro — unlimited AI analyses]
  ├── Day 2-3: Review prompt after 2nd analysis
  └── Day 6: "Your Pro trial ends tomorrow" notification
     │
     ▼
[Day 8: Features lock to Free tier]
  ├── Unlimited scanning + OCR (always free)
  └── 3 AI analyses/month
     │
     ▼
[User hits monthly limit]
     │
     ▼
[Soft paywall — "Upgrade to Privlens Pro"]
  ├── Monthly: $4.99/mo
  ├── Annual: $29.99/yr (⭐ "Save 58%")
  ├── Lifetime: $49.99 (🏆 "Best Value — Pay Once")
  └── "Maybe later" — can still scan, view past analyses
```

---

## Document Types

### MVP (Phase 1) -- Highest Pain, Strongest Privacy Sensitivity

| Document Type | Pain Level | Why MVP | Key Extractions |
|---------------|-----------|---------|-----------------|
| **Medical Bills & EOBs** | Extreme | #1 most confusing doc in America. 60-80% contain errors | Amount owed vs. insurance paid, procedure codes, provider info, appeal deadlines |
| **Lease Agreements** | High | Hidden fees, renewal traps, penalty clauses | Rent, deposit, lease term, penalties, maintenance responsibilities, renewal terms |
| **Insurance Policies** | High | Dense legal language, buried exclusions | Coverage limits, deductibles, exclusions, claim procedures, cancellation terms |

### Phase 2 (v1.1)

| Document Type | Key Extractions |
|---------------|-----------------|
| **Tax Forms** (W-2, 1099, K-1) | Income, withholdings, deductions, filing deadlines |
| **Employment Contracts** | Salary, benefits, non-compete, IP assignment, termination |
| **NDAs** | Scope, duration, exclusions, penalties |

### Phase 3 (v2.0)

| Document Type | Key Extractions |
|---------------|-----------------|
| **Government Forms** | Eligibility, deadlines, required documents |
| **Loan Agreements** | APR, total cost, prepayment penalties, collateral |
| **Home Purchase Docs** | Price, contingencies, closing costs, inspection requirements |
| **Financial Aid Letters** | Grants vs loans, true cost, acceptance deadlines |

---

## Monetization

### Pricing Strategy (Research-Backed)

| Tier | Price | Access |
|------|-------|--------|
| **Free** | $0 | Unlimited scanning + OCR forever, 3 AI analyses/month |
| **Pro Monthly** | $4.99/mo | Unlimited AI analyses, all doc types, export, full insights |
| **Pro Annual** | $29.99/yr | Same as monthly (~$2.50/mo, shown as "Save 58%") |
| **Lifetime** | $49.99 | All Pro features forever (shown as "Best Value — Pay Once") |

### Paywall Strategy: Soft Paywall with Reverse Trial

**Phase 1 — Reverse Trial (Days 1-7):**
Every new user gets full Pro access for 7 days automatically. No payment info required. This lets users experience the AI analysis value before any paywall appears.

**Phase 2 — Free Tier (Day 8+):**
Features lock to free tier: unlimited scanning + OCR, 3 AI analyses/month. Users can still view all past analyses.

**Phase 3 — Paywall Trigger:**
When user hits the 3-analysis monthly limit, soft paywall appears with all 3 pricing options. "Lifetime" shown with "Best Value" badge. Annual shown with "Save 58%" badge.

**Phase 4 — Tighten After Traction (50-100+ reviews):**
A/B test reducing to 1 free analysis/month, or shortening reverse trial to 3 days.

### Why This Model (Based on Research)

**Why soft paywall (not hard):**
- New apps with no brand recognition need free users for App Store reviews
- Soft paywall generates **8-25 reviews per 1,000 installs** vs **1-3 with hard paywall**
- Every top scanner app (Adobe Scan, Genius Scan, Scanner Pro, CamScanner, SwiftScan) uses soft freemium
- Hard paywall only succeeds with pre-existing brand/press

**Why reverse trial:**
- Reverse trials convert **10-20% higher** than standard opt-in trials (RevenueCat/Superwall data)
- Every user experiences full value → stronger loss aversion when features lock
- No payment info friction at install = higher Day-1 retention

**Why annual subscription + lifetime option:**
- Scanner category standard is **$30-50/year** — we're right in range at $29.99/yr
- "Lifetime Access" framing converts **10-20% better** than "One-Time Purchase" (A/B test data)
- Lifetime option chosen ~12-18% of the time when shown alongside subs — zero churn, highest satisfaction
- Subscription provides recurring revenue; lifetime captures subscription-fatigued users
- Annual subscribers have **higher 12-month LTV** ($29.99 recurring) than one-time ($9.99-$14.99 once)

**Why $29.99/yr and $49.99 lifetime:**
- $29.99/yr matches Scanner Pro ($29.99/yr), undercuts Adobe Scan ($69.99/yr) and SwiftScan ($34.99-$59.99/yr)
- $49.99 lifetime = ~1.7x annual price — optimal "lifetime = 1.5-2x annual" anchoring ratio
- "Lifetime" framing converts 10-20% better than "one-time purchase"

**Why NOT hard paywall / one-time only:**
- Original plan ($9.99-$14.99 one-time) caps Year 1 LTV at $14.99 max per user
- With annual sub: Year 1 LTV = $29.99 (2x), Year 2 = $59.98 (4x), recurring
- Scanner Pro literally migrated FROM one-time ($6.99) TO subscription ($29.99/yr) — the industry has spoken

**Other principles:**
- **$0 marginal cost per user** -- on-device AI means no API bills, no cloud infra
- **No ads** -- contradicts the privacy brand
- **Usage-based gating (3 analyses/month) beats time-based** for scanner apps: 70-80% 12-month retention vs 45-55% for time-gated

### Revenue Projections

| Scenario | Downloads | Conversion | Model | Revenue |
|----------|-----------|------------|-------|---------|
| **Conservative** | 500K | 5% | 70% annual ($29.99) / 30% lifetime ($49.99) | **$475K Year 1** |
| **With press** | 1M | 6% | 70% annual / 30% lifetime | **$1.16M Year 1** |
| **Year 2 (recurring)** | +500K new | 5% + renewals | 55% renewal rate | **$700K-$1.5M** |

### Review Velocity Strategy

- Trigger `SKStoreReviewController` after 2nd successful AI analysis (the "aha moment")
- Free tier retains users in-app → more review-eligible users
- Target: **50+ reviews in first 30 days** (enables A/B testing paywall tightening)
- Reverse trial means 100% of users reach the review trigger (not just paying users)

### Implementation

- **StoreKit 2** for native iOS purchase handling (subscriptions + non-consumable lifetime)
- **RevenueCat SDK** for analytics, A/B price testing, remote paywall configuration, and subscription management
- **Remote paywall config** — adjust pricing, trial length, and free limits without app updates
- **Receipt validation** on-device (no server needed)

### Competitive Pricing Landscape

| Competitor | Model | Annual Price | Our Advantage |
|-----------|-------|-------------|---------------|
| **Adobe Scan** | Sub | $69.99/yr | We're 57% cheaper |
| **Scanner Pro** | Sub | $29.99/yr | Same price, we add AI analysis |
| **SwiftScan VIP** | Sub | $34.99/yr | Cheaper + on-device privacy |
| **CamScanner** | Sub | $49.99/yr | No ads, no trust issues, cheaper |
| **ChatGPT Plus** | Sub | $240/yr | 87% cheaper, on-device, specialized |
| **Privlens** | Sub + Lifetime | $29.99/yr or $49.99 once | Only private, on-device option |

---

## Roadmap

### Phase 0 -- Project Scaffolding ✅ COMPLETE (March 2026)

- [x] Swift Package structure (PrivlensCore + PrivlensUI)
- [x] MVVM architecture with SwiftUI
- [x] Data models (Document, DocumentType, AnalysisResult)
- [x] 3-tab navigation (Scan, Documents, Settings)
- [x] GitHub Actions CI (macOS + Linux)
- [x] Platform-guarded stubs (`#if canImport`) for Linux cross-compilation

### Phase 1 -- Scanning + OCR ✅ COMPLETE (March 2026)

- [x] **ScannerService** — VisionKit `VNDocumentCameraViewController` wrapper with protocol-based design (`DocumentScannerProtocol`) for testability
- [x] **OCRService** — Vision framework `VNRecognizeTextRequest` with accurate recognition level, language correction, and revision 3
- [x] **DocumentClassifier** — Keyword-scoring classifier for medical bills, leases, and insurance documents
- [x] **AIAnalysisService** — Apple Foundation Models integration with type-specific prompt templates and `@Generable` structured output
- [x] **ScanViewModel** — Full scan → OCR → classify → analyze pipeline with progress tracking
- [x] **MockScannerService** — Test/preview mock for scanner
- [x] **ScannerView** — SwiftUI wrapper for VisionKit document camera with `UIViewControllerRepresentable`
- [x] **Unit tests** — DocumentClassifier tests (5 cases) + Document model tests
- [x] **CI** — Dual-platform GitHub Actions: Linux SPM build + macOS iOS Simulator build & test

#### Scanning + OCR Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Phase 1 Pipeline                          │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │  ScannerView │    │  OCRService  │    │  Document     │   │
│  │  (VisionKit) │───►│  (Vision)    │───►│  Classifier   │   │
│  └──────────────┘    └──────────────┘    └──────┬───────┘   │
│                                                  │           │
│  User taps scan       VNRecognizeTextRequest     Keyword     │
│  → camera opens       → accurate recognition     scoring     │
│  → captures pages     → language correction      per type    │
│  → returns [CGImage]  → returns String           → DocType   │
│                                                  │           │
│                                          ┌───────▼───────┐  │
│                                          │ AIAnalysis     │  │
│                                          │ Service        │  │
│                                          │ (Foundation    │  │
│                                          │  Models stub)  │  │
│                                          └───────┬───────┘  │
│                                                  │           │
│                                          ┌───────▼───────┐  │
│                                          │ AnalysisResult │  │
│                                          │ (structured)   │  │
│                                          └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Key design decisions:**
- Protocol-based `DocumentScannerProtocol` enables mocking for tests and previews
- `#if canImport(VisionKit)` / `#if canImport(Vision)` guards allow PrivlensCore to compile on Linux (CI + VDI development)
- `#if ENABLE_FOUNDATION_MODELS` guard for AI service — stubs return error on non-Apple platforms
- OCR supports both `CGImage` and raw `Data` (JPEG/PNG) input paths
- Classifier uses keyword-frequency scoring (no ML model needed) — fast, deterministic, testable

### Phase 2 -- AI Analysis with Apple Foundation Models ✅ COMPLETE (March 2026)

- [x] **ChunkingService** — Sentence-boundary-aware text splitting into ~4K char chunks with configurable overlap
- [x] **TextChunk model** — Chunk indexing with character-range tracking for source attribution
- [x] **AttributionService** — Fuzzy keyword matching to link AI insights back to source text locations
- [x] **AnalysisResult model** — Structured Insight + SourceAttribution types with severity levels
- [x] **AIAnalysisService** — Apple Foundation Models integration with `LanguageModelSession`, per-chunk analysis + meta-summary
- [x] **AnalysisCoordinator** — Orchestrates full pipeline: chunk → analyze → attribute → persist via StorageService
- [x] **PromptTemplates** — Type-specific prompt engineering for medical bills, leases, insurance, contracts, tax forms
- [x] **Unit tests** — ChunkingService (4 cases), AnalysisResult (serialization), AnalysisCoordinator (pipeline)
- [x] **CI** — Dual-platform passing: Linux SPM + macOS iOS Simulator build & test

### Phase 3 -- TestFlight Prep ✅ COMPLETE (March 2026)

- [x] **App Store Connect metadata** — Full app description, keywords (87/100 chars), promotional text, review notes
- [x] **Privacy Nutrition Label** — All "Not Collected" responses documented (strongest possible label)
- [x] **Screenshot plan** — 8 required screenshots defined with device sizes
- [x] **Xcode project config** — Bundle ID (`com.peterkimpro.privlens`), version 1.0.0, build 1, iOS 26.0 minimum
- [x] **Info.plist** — Camera + Photo Library usage descriptions, arm64 requirement, launch screen
- [x] **TestFlight guide** — Step-by-step `TESTFLIGHT.md` for Mac submission (signing, archive, upload, testing)
- [x] **Metadata reference file** — `App/Privlens/Metadata/AppStoreMetadata.swift` with all App Store copy
- [x] **Privacy/legal URL placeholders** — privlens.com/privacy, GitHub Issues support URL

### Phase 4 -- Polish & Launch ✅ COMPLETE (March 2026)

- [x] **PerformanceMonitor** — Operation timing and metrics tracking with eviction and averages
- [x] **InputValidator** — Document text validation, OCR sanitization, title normalization, edge case handling
- [x] **AnalysisCache** — In-memory result cache keyed by content hash with expiration and LRU eviction
- [x] **AppReadinessChecker** — Device capability checks (platform, AI engine, storage, disk, camera)
- [x] **ReviewPromptManager** — App Store review prompt timing (after 2nd analysis, 90-day cooldown)
- [x] **ErrorRecoveryService** — User-friendly error messages with suggested recovery actions for all error types
- [x] **AccessibilityHelpers** — Centralized VoiceOver labels and UI test identifiers for all screens
- [x] **OnboardingView** — 3-page onboarding flow (scan, AI analysis, privacy) with accessibility support
- [x] **UI Polish** — Privacy indicators, accessibility identifiers, error alerts with recovery actions across all views
- [x] **Unit tests** — InputValidator (11 cases), AnalysisCache (10 cases), PerformanceMonitor (10 cases), AppReadinessChecker (6 cases), ErrorRecoveryService (12 cases), ReviewPromptManager (6 cases), AccessibilityHelpers (11 cases)
- [x] **CI** — Dual-platform passing: Linux SPM + macOS iOS Simulator build & test

### Phase 5 -- v1.1 (Target: Nov 2026) ✅ COMPLETE (March 2026)

- [x] **Document comparison mode** — Side-by-side analysis of two documents with financial, legal, date, and term difference detection, Jaccard similarity scoring, and critical difference highlighting
- [x] **Export & share (PDF reports)** — PDFExportService with UIKit CoreText rendering (iOS) and plain-text fallback (Linux), ExportView with PDF and text share options, integrated into AnalysisView toolbar
- [x] **Full-text search across documents** — Dedicated SearchView tab with full-text search across titles, content, and analysis results, matching snippet previews
- [x] **Tax forms, employment contracts, NDAs** — Three new DocumentType cases with keyword-based classification (scoreTaxForm, scoreEmploymentContract, scoreNDA), type-specific prompt templates for targeted analysis
- [x] **Pro+ annual subscription tier** — New SubscriptionTier.proPlus, PaywallManager.ProductID.proPlusAnnual ($49.99/yr), supportsComparison gating
- [x] **ComparisonView** — Document picker sheets, similarity indicator, categorized differences (critical/other), share comparison report
- [x] **Updated navigation** — 5-tab layout: Scan, Documents, Compare, Search, Settings
- [x] **Accessibility** — Full VoiceOver support for comparison, export, and search views with new identifiers and labels
- [x] **Error recovery** — DocumentComparisonError and PDFExportError handled in ErrorRecoveryService with user-friendly messages
- [x] **Unit tests** — DocumentComparisonService (10 cases), PDFExportService (10 cases), DocumentClassifier v1.1 (10 cases) — all passing on Linux
- [x] **CI** — Dual-platform passing: Linux SPM build & test (183 tests)

### Phase 6 -- v2.0 (Target: Q1 2027)

- Follow-up questions (conversational document Q&A)
- Smart auto-detection (no manual document type selection)
- Batch analysis for document packages
- Date-based reminders
- Government forms, loan agreements, home purchase docs
- Multi-language support

### Future Considerations

- iPad optimization with larger screen layouts
- Mac Catalyst or native macOS app
- Widgets for key date reminders (WidgetKit)
- Live Activities for long analysis progress
- Shortcuts integration for automation
- WWDC 2026 (June) may expand Foundation Models capabilities -- adapt accordingly

---

## Marketing Strategy

### Positioning

> **Privlens** -- Your documents, understood. Privately.

### App Store Optimization (ASO)

| Field | Content |
|-------|---------|
| **Name** | Privlens - Private Document AI |
| **Subtitle** | 100% On-Device. Zero Cloud. |
| **Keywords** | scanner,OCR,medical bill,lease,contract,summarize,analyze,private,offline,insurance,tax,legal |
| **Category** | Productivity (primary), Business (secondary) |

### Key Marketing Angles

1. **Privacy Nutrition Label as a weapon** -- Show Privlens's minimal data collection vs. competitors' extensive collection side-by-side in screenshots
2. **"Finally understand your medical bill"** -- Lead with the pain, not the tech
3. **"Your documents never leave your iPhone"** -- The one-line differentiator
4. **Pay-once option vs. subscription competitors** -- "$49.99 once. Not $9.99/month forever."
5. **Apple feature potential** -- Aligns perfectly with Apple's privacy narrative. Strong App Store editorial candidate

### Target Communities

| Channel | Audience |
|---------|----------|
| r/privacy, r/degoogle, r/PrivacyGuides | Privacy-conscious users |
| r/apple, r/iphone, r/ios | Apple enthusiasts, early adopters |
| r/personalfinance, r/legaladvice | People dealing with confusing documents |
| r/IndieApps, r/SwiftUI | Dev community, cross-promotion |
| Hacker News | Tech-savvy early adopters |

### Press & PR

- Privacy-focused tech journalists (The Verge, Ars Technica, Wired)
- "On-device AI" angle for developer-focused outlets (9to5Mac, MacStories)
- Build-in-public on Twitter/X for indie dev community engagement

### Viral Hooks

- "Scan your lease before you sign it"
- "Finally understand your medical bill"
- "Privlens found 3 hidden fees in my lease"
- "Every document analyzer sends your data to the cloud. Except this one."

---

## Competitive Analysis

| App | Scanning | AI Analysis | On-Device | Privacy | Price | Our Advantage |
|-----|----------|-------------|-----------|---------|-------|---------------|
| **Adobe Scan** | Excellent | Cloud-only | OCR only | Adobe servers | Free + $9.99/mo | We analyze AND keep it private |
| **Genius Scan** | Good | None | OCR only | Decent | $2.99-$9.99/yr | We actually understand the document |
| **CamScanner** | Good | Cloud-only | No | Terrible (malware) | Free + $4.99/mo | Trust. Period. |
| **Microsoft Lens** | Good | Cloud-only | No | MS account required | Free | No account, no cloud |
| **ChatGPT** | N/A | Excellent | No | Cloud-processed | $20/mo | On-device, 87% cheaper annually |
| **Claude** | N/A | Excellent | No | Cloud-processed | $20/mo | On-device, integrated scanning, private |
| **Privlens** | **Vision OCR** | **Foundation Models** | **100%** | **Nothing leaves device** | **$29.99/yr or $49.99 once** | -- |

### Blue Ocean

No existing app combines all three: **document scanning + AI-powered analysis + fully on-device processing**. This is a genuine blue ocean.

---

## Risk & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **4K context limit for long docs** | Medium | Chunked summarization: section-by-section → meta-summary |
| **Model quality vs GPT-4/Claude** | Medium | Type-specific prompt templates; users expect "good enough" not "perfect" |
| **Only works on iPhone 15 Pro+** | Medium | Basic features (OCR, organization) for all; AI for compatible devices |
| **Hallucination in legal/financial context** | High | Always show source text alongside AI. Disclaimer: "AI analysis -- verify important details." |
| **Apple builds this into Files/Notes** | Low-Medium | Apple rarely builds specialized verticals. Window is 1-2+ years |
| **Competitor copies concept** | Medium | First-mover advantage + brand loyalty. Ship fast. |

---

## Development Setup

> **Workflow:** All code is written on the Linux VDI by the Claude orchestrator → pushed to GitHub → your personal Mac pulls and builds. The Mac is a **build terminal**, not a dev environment.

### Development Environment Overview

| Component | Where | What Happens | Cost |
|-----------|-------|--------------|------|
| **All coding & orchestration** | NVIDIA VDI (Linux) | Claude writes all Swift code, tests, configs | Free |
| **Swift logic testing** | NVIDIA VDI (Linux) | `swift build` / `swift test` for non-UI code | Free |
| **CI/CD validation** | GitHub Actions (macOS runner) | Auto-build + test on every push/PR | Free (2000 min/mo) |
| **Xcode build & Simulator** | Your personal Mac | `git pull` → Open Xcode → Build → Run | Free |
| **SwiftUI Previews** | Your personal Mac | Visual verification of UI | Free |
| **TestFlight & App Store** | Xcode Cloud | Archive → TestFlight → App Store submission | Free (25 hrs/mo) |
| **Apple Developer Program** | Apple | Code signing, TestFlight, App Store listing | $99/yr |
| **Total monthly cost** | | | **~$8.25/mo** |

### Architecture: VDI → GitHub → Mac

```
┌──────────────────────────────────┐                ┌──────────────────────────────┐
│     NVIDIA Cloud VDI (Linux)     │    GitHub      │    Your Personal Mac         │
│     ════════════════════════     │    (bridge)    │    ════════════════════      │
│                                  │                │                              │
│  • Claude orchestrator writes    │  git push ──►  │  • git pull                  │
│    ALL code (Swift, configs,     │                │  • Open Xcode                │
│    tests, CI workflows)          │  ◄── git push  │  • Build (⌘B)               │
│  • swift build / swift test      │    (if needed) │  • Run on Simulator (⌘R)     │
│    for non-UI logic              │                │  • SwiftUI Previews          │
│  • PR reviews & planning         │                │  • TestFlight upload         │
│  • Git operations                │                │  • App Store submission      │
│                                  │                │                              │
│  YOU NEVER OPEN AN EDITOR HERE   │                │  YOU NEVER WRITE CODE HERE   │
│  (Claude does all the writing)   │                │  (just pull, build, run)     │
└──────────────────────────────────┘                └──────────────────────────────┘
         │                                                      │
         │  git push (automated)                                │  Xcode Cloud
         ▼                                                      ▼
┌──────────────────────────────────┐              ┌──────────────────────────────┐
│        GitHub Actions            │              │     App Store Connect        │
│  • Build validation (PR checks)  │              │  • TestFlight distribution   │
│  • Unit tests on macOS runner    │              │  • App Store submission      │
│  • Catches build errors before   │              │  • App Review                │
│    you even touch the Mac        │              │                              │
└──────────────────────────────────┘              └──────────────────────────────┘
```

### The Daily Workflow

```
1. You tell Claude what to build (via Discord)
2. Claude writes code on the VDI → pushes to GitHub
3. GitHub Actions auto-runs build + tests (catches errors)
4. When ready to see it on device:
   a. Open Terminal on your Mac
   b. cd ~/Developer/privlens && git pull
   c. Open Xcode → Build & Run (⌘R)
   d. That's it.
```

**You touch the Mac maybe 2-3 times per week.** Everything else happens on the VDI.

### Step 1: One-Time Mac Setup

Do this once on your personal Mac:

```bash
# 1. Install Xcode (from App Store — requires macOS 16+ for iOS 26 SDK)
# Open App Store → search "Xcode" → Install Xcode 17+

# 2. Accept Xcode license and install CLI tools
sudo xcodebuild -license accept
xcode-select --install

# 3. Clone the repo
mkdir -p ~/Developer
git clone https://github.com/peterkimpro/privlens.git ~/Developer/privlens
cd ~/Developer/privlens

# 4. Open in Xcode
open Privlens.xcodeproj
# (or open Package.swift if using SwiftPM-only structure)

# 5. Select your target device (iPhone 16 Pro Simulator)
# Product → Destination → iPhone 16 Pro (iOS 26)

# 6. Build & Run (⌘R) — verify everything works
```

**Apple Developer Program** ($99/yr): Sign up at [developer.apple.com](https://developer.apple.com/programs/) when ready for TestFlight/App Store. Not needed for Simulator testing.

### Step 2: Swift on Linux (VDI — Auto-Configured)

The VDI has the Swift toolchain for building and testing non-UI code:

```bash
# Install Swift on the VDI (one-time)
wget https://download.swift.org/swift-6.1-release/ubuntu2404/swift-6.1-RELEASE/swift-6.1-RELEASE-ubuntu24.04.tar.gz
tar xzf swift-6.1-RELEASE-ubuntu24.04.tar.gz
sudo mv swift-6.1-RELEASE-ubuntu24.04 /opt/swift
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
swift --version
```

**What Claude can build + test on Linux:** Swift packages, data models, business logic, prompt templates, chunking engine, text processing, unit tests.

**What requires the Mac:** SwiftUI views, UIKit, Apple frameworks (Foundation Models, VisionKit, StoreKit), Simulator, Previews.

The project is structured so **~60% of code** (all non-UI logic) can be written and tested entirely on Linux:

```
Privlens/
├── PrivlensCore/              # Swift Package — builds on BOTH Linux and macOS
│   ├── Sources/
│   │   ├── Models/            # Document, DocumentAnalysis, DocumentType
│   │   ├── AI/                # PromptTemplates, ChunkingEngine
│   │   └── Utilities/         # Text processing, NER helpers
│   └── Tests/                 # These run on Linux via `swift test`
│       ├── ChunkingEngineTests.swift
│       └── PromptTemplateTests.swift
├── Privlens/                  # Xcode app target — macOS/iOS only
│   ├── App/
│   ├── Features/
│   └── Resources/
└── Package.swift
```

### Step 3: GitHub Actions CI/CD (Automatic)

Every push triggers a macOS build + test on GitHub's runners. This catches build errors **before you pull on the Mac**:

```yaml
# .github/workflows/build.yml — dual-platform CI
name: Build & Test
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  linux-spm:                           # Validates cross-platform stubs
    runs-on: ubuntu-latest
    container: swift:6.0
    steps:
      - uses: actions/checkout@v4
      - run: swift build --target PrivlensCore
      - run: swift test

  ios-build:                           # Full iOS Simulator build + tests
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      - run: swift build --target PrivlensCore
      - run: xcodebuild build -scheme Privlens -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
      - run: xcodebuild test -scheme Privlens -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

**Why this matters:** Claude pushes code → GitHub Actions builds it on a real macOS runner → if it fails, Claude fixes it → by the time you pull on your Mac, it's guaranteed to compile.

### Step 4: Xcode Cloud (App Store Deployment)

1. On your Mac: Xcode → Product → Xcode Cloud → Create Workflow
2. Configure: Build on push to `release` branch, archive for TestFlight
3. **25 free compute hours/month** with Apple Developer Program
4. Handles code signing, TestFlight uploads, and App Store submission

### Step 5: Testing on Physical Device

**TestFlight (recommended):** Xcode Cloud builds → auto-pushed to TestFlight → install on your iPhone via TestFlight app. No cable needed.

**Direct from Mac:** Connect iPhone via USB → select it in Xcode → Build & Run (⌘R).

**Foundation Models:** Work in iOS 26 Simulator on Apple Silicon Macs (M1+). For production testing, use TestFlight on iPhone 15 Pro+.

### When You Touch the Mac (Checklist)

| Task | Frequency | Time |
|------|-----------|------|
| `git pull` → Build → Run Simulator | 2-3x/week | 5 min |
| SwiftUI Preview check | When UI changes | 10 min |
| TestFlight upload (first time setup) | Once | 30 min |
| App Store submission | Once per release | 30 min |
| Debug device-specific issue | Rare | Varies |

**Total Mac time: ~1-2 hours/week max.** Everything else is VDI + GitHub.

### Project Structure (Planned)

```
Privlens/
├── App/
│   ├── PrivlensApp.swift              # App entry point
│   └── ContentView.swift              # Root navigation
├── Features/
│   ├── Scanning/
│   │   ├── ScannerView.swift          # VisionKit document camera
│   │   └── ScannerViewModel.swift
│   ├── Analysis/
│   │   ├── AnalysisView.swift         # Results display
│   │   ├── AnalysisViewModel.swift
│   │   └── AnalysisEngine.swift       # Core AI pipeline
│   ├── Library/
│   │   ├── LibraryView.swift          # Document list
│   │   └── LibraryViewModel.swift
│   └── Paywall/
│       ├── PaywallView.swift
│       └── PurchaseManager.swift
├── Core/
│   ├── Models/
│   │   ├── Document.swift             # SwiftData model
│   │   ├── DocumentAnalysis.swift     # @Generable output structs
│   │   └── DocumentType.swift         # Enum: medical, lease, insurance...
│   ├── AI/
│   │   ├── PromptTemplates.swift      # Type-specific prompt engineering
│   │   ├── ChunkingEngine.swift       # Long document handling
│   │   └── FoundationModelService.swift
│   ├── OCR/
│   │   └── TextRecognitionService.swift
│   └── Storage/
│       └── DataStore.swift            # SwiftData container config
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── AnalysisEngineTests.swift
    ├── ChunkingEngineTests.swift
    └── PromptTemplateTests.swift
```

---

## Brand Assets

| Asset | Value |
|-------|-------|
| **Name** | Privlens |
| **Tagline** | Your documents, understood. Privately. |
| **App Store Name** | Privlens - Private Document AI |
| **Primary Domain** | privlens.com (to register) |
| **Backup Domains** | privlensapp.com, getprivlens.com |
| **GitHub** | github.com/peterkimpro/privlens |

---

## Market Context

| Metric | Value |
|--------|-------|
| **Document scanning market** | $4.5-5.2B (2024) → $8-10B by 2030 |
| **Data privacy software market** | $5.37B (2025) → $45.13B by 2034 (35.5% CAGR) |
| **GenAI app revenue** | $5B+ in 2025 (tripled YoY) |
| **iOS users opting out of tracking** | 65% |
| **Users willing to pay for data protection** | 60% of US adults |
| **Privacy-first conversion premium** | 15-25% higher conversion rates |

---

## License

Copyright 2026 Peter Kim. All rights reserved.
