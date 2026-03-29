import Foundation

// MARK: - Protocol

/// Protocol for smart document classification that can use AI or fall back to keyword matching.
public protocol SmartClassifierProtocol: Sendable {
    /// Classifies a document using AI-powered detection, falling back to keyword scoring.
    func classify(text: String) async -> DocumentType
}

// MARK: - Implementation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

public final class SmartClassifier: SmartClassifierProtocol, Sendable {

    private let fallbackClassifier: DocumentClassifier

    public init(fallbackClassifier: DocumentClassifier = DocumentClassifier()) {
        self.fallbackClassifier = fallbackClassifier
    }

    public func classify(text: String) async -> DocumentType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 20 else {
            return fallbackClassifier.classify(text: trimmed)
        }

        // Use first ~500 characters for fast classification
        let snippet = String(trimmed.prefix(500))

        do {
            let session = LanguageModelSession()
            let prompt = buildClassificationPrompt(snippet: snippet)
            let response = try await session.respond(to: prompt)
            let rawType = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if let detected = parseDocumentType(from: rawType) {
                return detected
            }
        } catch {
            // AI unavailable — fall through to keyword classifier
        }

        return fallbackClassifier.classify(text: trimmed)
    }

    // MARK: - Private

    private func buildClassificationPrompt(snippet: String) -> String {
        let validTypes = DocumentType.allCases
            .filter { $0 != .unknown }
            .map { "\($0.rawValue) (\($0.displayName))" }
            .joined(separator: ", ")

        return """
        Classify the following document excerpt into exactly one of these types: \(validTypes).

        If the document does not match any type, respond with "unknown".

        Respond with ONLY the type identifier (e.g. "medicalBill", "lease", "governmentForm"), nothing else.

        DOCUMENT EXCERPT:
        ---
        \(snippet)
        ---
        """
    }

    private func parseDocumentType(from raw: String) -> DocumentType? {
        // Direct rawValue match
        if let direct = DocumentType(rawValue: raw) {
            return direct == .unknown ? nil : direct
        }

        // Try matching against display names
        for docType in DocumentType.allCases where docType != .unknown {
            if raw.contains(docType.rawValue.lowercased()) ||
               raw.contains(docType.displayName.lowercased()) {
                return docType
            }
        }

        // Common aliases
        let aliases: [String: DocumentType] = [
            "medical": .medicalBill,
            "medical bill": .medicalBill,
            "eob": .medicalBill,
            "lease": .lease,
            "rental": .lease,
            "insurance": .insurance,
            "policy": .insurance,
            "tax": .taxForm,
            "w-2": .taxForm,
            "w2": .taxForm,
            "1099": .taxForm,
            "1040": .taxForm,
            "employment": .employmentContract,
            "job contract": .employmentContract,
            "offer letter": .employmentContract,
            "nda": .nda,
            "non-disclosure": .nda,
            "confidentiality": .nda,
            "government": .governmentForm,
            "dmv": .governmentForm,
            "immigration": .governmentForm,
            "social security": .governmentForm,
            "loan": .loanAgreement,
            "mortgage": .loanAgreement,
            "auto loan": .loanAgreement,
            "student loan": .loanAgreement,
            "home purchase": .homePurchase,
            "closing disclosure": .homePurchase,
            "title report": .homePurchase,
            "hoa": .homePurchase,
        ]

        for (alias, docType) in aliases {
            if raw.contains(alias) {
                return docType
            }
        }

        return nil
    }
}

#else

// MARK: - Linux / non-Apple platform stub

public final class SmartClassifier: SmartClassifierProtocol, Sendable {

    private let fallbackClassifier: DocumentClassifier

    public init(fallbackClassifier: DocumentClassifier = DocumentClassifier()) {
        self.fallbackClassifier = fallbackClassifier
    }

    public func classify(text: String) async -> DocumentType {
        // On non-Apple platforms, always use keyword-based classification
        return fallbackClassifier.classify(text: text)
    }
}

#endif
