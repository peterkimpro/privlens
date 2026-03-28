// AppStoreMetadata.swift
// Reference file for App Store Connect submission fields.
// Copy these values into App Store Connect when creating the app listing.
// This file is NOT compiled — it exists as a single source of truth.

// swiftlint:disable all
#if false

// MARK: - App Identity

let appName = "Privlens - Private Document AI"
let subtitle = "100% On-Device. Zero Cloud."
let bundleID = "com.peterkimpro.privlens"
let primaryCategory = "Productivity"
let secondaryCategory = "Business"
let contentRating = "4+" // No objectionable content

// MARK: - Version Info

let version = "1.0.0"
let buildNumber = 1 // Increment on each TestFlight upload
let minimumOS = "26.0" // Requires Apple Foundation Models (iOS 26+)

// MARK: - Description

let description = """
Privlens scans your documents and gives you plain-English insights — summaries, key terms, red flags, and action items — all powered by on-device AI. Your documents never leave your iPhone. Ever.

UNDERSTAND ANY DOCUMENT IN SECONDS
• Scan with your camera or import from Photos/Files
• Get a plain-English summary of complex legal and financial documents
• See key terms, dates, and amounts extracted automatically
• Spot red flags, hidden fees, and unusual clauses
• Get recommended action items based on your document

BUILT FOR PRIVACY
• 100% on-device AI processing — zero cloud, zero network calls
• Powered by Apple Foundation Models — your data stays on your iPhone
• No account required. No sign-up. No tracking.
• Check our Privacy Nutrition Label — we collect nothing.

DOCUMENT TYPES SUPPORTED
• Medical Bills & EOBs — finally understand what you owe and why
• Lease Agreements — catch hidden fees and penalty clauses before you sign
• Insurance Policies — know what's actually covered (and what isn't)
• Contracts & NDAs — plain-English breakdown of obligations and risks
• Tax Forms — key numbers and filing deadlines at a glance

SMART ANALYSIS
• Source attribution — tap any insight to see the original text
• Document classification — automatic type detection
• Multi-page support — handles long documents with smart chunking
• Confidence scores — know how certain the AI is about each finding

TRY IT FREE
• 7-day full Pro trial — no credit card required
• Free tier: unlimited scanning + OCR, 3 AI analyses per month
• Pro: unlimited analyses, all document types, full insights
"""

// MARK: - Keywords (100 character limit)

let keywords = "scanner,OCR,medical bill,lease,contract,summarize,analyze,private,offline,insurance"
// 87 chars — room for 13 more if needed
// Alternates to test: "document,AI,on-device,legal,tax,privacy,scan,extract,summary,bill"

// MARK: - What's New (for updates)

let whatsNew_1_0 = """
Welcome to Privlens! Scan any document, get plain-English insights — 100% on-device, 100% private.
"""

// MARK: - Promotional Text (can be updated without new build)

let promotionalText = """
Your documents, understood. Privately. Try 7 days of Pro free — no credit card needed.
"""

// MARK: - Support & Legal URLs

let supportURL = "https://github.com/peterkimpro/privlens/issues"
let privacyPolicyURL = "https://privlens.com/privacy" // TODO: Create before App Store submission
let termsOfServiceURL = "https://privlens.com/terms"   // TODO: Create before App Store submission
// Fallback if domain not ready: host on GitHub Pages at peterkimpro.github.io/privlens/privacy

// MARK: - Screenshots Required

/*
 App Store requires screenshots for each device size you support.
 Minimum: iPhone 6.7" (iPhone 15 Pro Max / 16 Pro Max)

 Required screenshots (3-10 per device size):

 1. Hero shot — "Your documents, understood. Privately." with scan preview
 2. Scanning — Camera scanning a document with edge detection
 3. Analysis Results — Summary tab showing plain-English breakdown
 4. Red Flags — Red flag detection on a lease agreement
 5. Key Terms — Extracted dates, amounts, parties from a medical bill
 6. Action Items — Recommended next steps
 7. Privacy — "100% On-Device" indicator / privacy badge
 8. Library — Document library with folders

 Device sizes needed:
 - iPhone 6.7" (1290 x 2796) — REQUIRED
 - iPhone 6.1" (1179 x 2556) — recommended
 - iPad 12.9" (2048 x 2732) — only if supporting iPad

 Generate on Mac: Simulator → File → Screenshot (⌘S)
 Or use Xcode Previews with .previewDevice("iPhone 16 Pro Max")
*/

// MARK: - App Review Notes

let reviewNotes = """
Privlens requires iOS 26+ and Apple Foundation Models.

To test AI analysis:
1. Launch the app — you'll get 7 days of Pro access automatically
2. Tap the Scan tab → use the camera to scan any document (a printed receipt or lease works well)
3. After scanning, select a document type (e.g., "Medical Bill")
4. Wait ~5-15 seconds for on-device AI analysis
5. View results: Summary, Key Terms, Red Flags, and Action Items tabs

Note: AI analysis requires Apple Foundation Models which runs on-device only.
The app makes zero network calls for document processing.
StoreKit 2 is used for in-app purchases (subscription + lifetime).

Demo account: Not applicable — no accounts or login required.
"""

// MARK: - Privacy Nutrition Label Answers

/*
 Data NOT Collected (select all these in App Store Connect → App Privacy):
 - Contact Info: ✗ Not collected
 - Health & Fitness: ✗ Not collected
 - Financial Info: ✗ Not collected
 - Location: ✗ Not collected
 - Sensitive Info: ✗ Not collected
 - Contacts: ✗ Not collected
 - User Content: ✗ Not collected
 - Browsing History: ✗ Not collected
 - Search History: ✗ Not collected
 - Identifiers: ✗ Not collected
 - Usage Data: ✗ Not collected
 - Diagnostics: ✗ Not collected (unless you add analytics later)

 Data Linked to You: NONE
 Data Used to Track You: NONE

 This is the strongest possible privacy label — a real competitive advantage.

 If you add RevenueCat later, update:
 - Identifiers: Device ID (linked to purchase)
 - Purchase History (linked to user)
*/

#endif
