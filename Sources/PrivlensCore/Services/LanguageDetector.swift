import Foundation

// MARK: - LanguageDetectorProtocol

/// Protocol for language detection from OCR text.
public protocol LanguageDetectorProtocol: Sendable {
    /// Detects the language of the given text.
    func detectLanguage(from text: String) -> LanguageDetectionResult
}

// MARK: - LanguageDetector

/// Detects document language from OCR text using character analysis and keyword matching.
public final class LanguageDetector: LanguageDetectorProtocol, Sendable {

    public init() {}

    public func detectLanguage(from text: String) -> LanguageDetectionResult {
        guard !text.isEmpty else {
            return LanguageDetectionResult(
                primaryLanguage: .english,
                confidence: 0.0,
                detectedLanguages: [(.english, 0.0)]
            )
        }

        var scores: [(SupportedLanguage, Double)] = []

        for language in SupportedLanguage.allCases {
            let score = computeScore(for: language, in: text)
            scores.append((language, score))
        }

        scores.sort { $0.1 > $1.1 }

        let totalScore = scores.reduce(0.0) { $0 + $1.1 }
        let normalized: [(SupportedLanguage, Double)]
        if totalScore > 0 {
            normalized = scores.map { ($0.0, $0.1 / totalScore) }
        } else {
            normalized = [(.english, 1.0)]
        }

        let primary = normalized.first ?? (.english, 1.0)
        return LanguageDetectionResult(
            primaryLanguage: primary.0,
            confidence: primary.1,
            detectedLanguages: normalized
        )
    }

    // MARK: - Private

    private func computeScore(for language: SupportedLanguage, in text: String) -> Double {
        let lowercased = text.lowercased()

        switch language {
        case .english:
            return scoreEnglish(lowercased, original: text)
        case .spanish:
            return scoreSpanish(lowercased, original: text)
        case .french:
            return scoreFrench(lowercased, original: text)
        case .german:
            return scoreGerman(lowercased, original: text)
        case .chinese:
            return scoreChinese(text)
        case .japanese:
            return scoreJapanese(text)
        case .korean:
            return scoreKorean(text)
        }
    }

    private func scoreEnglish(_ text: String, original: String) -> Double {
        let keywords = [
            "the", "and", "is", "are", "was", "were", "have", "has",
            "this", "that", "with", "from", "your", "will", "would",
            "should", "could", "been", "their", "which", "about",
            "please", "thank", "agreement", "contract", "document",
        ]
        let matchCount = countWordMatches(in: text, keywords: keywords)
        return Double(matchCount)
    }

    private func scoreSpanish(_ text: String, original: String) -> Double {
        let keywords = [
            "el", "la", "los", "las", "de", "del", "en", "que",
            "por", "con", "para", "una", "uno", "est\u{00E1}", "son",
            "como", "pero", "m\u{00E1}s", "este", "esta", "estos",
            "ser\u{00E1}", "puede", "tiene", "hacer", "sobre",
            "contrato", "acuerdo", "documento", "formulario",
        ]
        let matchCount = countWordMatches(in: text, keywords: keywords)
        let accentChars = original.filter { "\u{00E1}\u{00E9}\u{00ED}\u{00F3}\u{00FA}\u{00F1}\u{00BF}\u{00A1}".contains($0) }
        return Double(matchCount) + Double(accentChars.count) * 0.5
    }

    private func scoreFrench(_ text: String, original: String) -> Double {
        let keywords = [
            "le", "la", "les", "des", "du", "de", "est", "sont",
            "dans", "pour", "avec", "une", "que", "qui", "sur",
            "nous", "vous", "leur", "cette", "ces", "aux",
            "avoir", "\u{00EA}tre", "fait", "peut",
            "contrat", "accord", "document", "formulaire",
        ]
        let matchCount = countWordMatches(in: text, keywords: keywords)
        let frenchChars = original.filter { "\u{00E0}\u{00E2}\u{00E7}\u{00E8}\u{00E9}\u{00EA}\u{00EB}\u{00EE}\u{00EF}\u{00F4}\u{00F9}\u{00FB}\u{00FC}\u{0153}".contains($0) }
        return Double(matchCount) + Double(frenchChars.count) * 0.5
    }

    private func scoreGerman(_ text: String, original: String) -> Double {
        let keywords = [
            "der", "die", "das", "ein", "eine", "ist", "sind",
            "und", "oder", "f\u{00FC}r", "mit", "von", "auf",
            "den", "dem", "des", "sich", "nicht", "auch",
            "wird", "haben", "kann", "werden", "nach",
            "vertrag", "vereinbarung", "dokument", "formular",
        ]
        let matchCount = countWordMatches(in: text, keywords: keywords)
        let germanChars = original.filter { "\u{00E4}\u{00F6}\u{00FC}\u{00C4}\u{00D6}\u{00DC}\u{00DF}".contains($0) }
        return Double(matchCount) + Double(germanChars.count) * 0.5
    }

    private func scoreChinese(_ text: String) -> Double {
        var count = 0
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // CJK Unified Ideographs: U+4E00..U+9FFF
            if value >= 0x4E00 && value <= 0x9FFF {
                count += 1
            }
        }
        // Chinese uses only CJK characters, no hiragana/katakana
        let japaneseCount = countJapaneseKana(text)
        let koreanCount = countKoreanJamo(text)
        if japaneseCount > 0 || koreanCount > 0 {
            // If there are kana or jamo, reduce Chinese score
            return Double(max(0, count - japaneseCount * 3 - koreanCount * 3)) * 0.3
        }
        return Double(count) * 0.3
    }

    private func scoreJapanese(_ text: String) -> Double {
        let kanaCount = countJapaneseKana(text)
        // CJK characters count as partial evidence for Japanese too
        var cjkCount = 0
        for scalar in text.unicodeScalars {
            let value = scalar.value
            if value >= 0x4E00 && value <= 0x9FFF {
                cjkCount += 1
            }
        }
        // Hiragana/Katakana are strong signals for Japanese
        return Double(kanaCount) * 2.0 + Double(cjkCount) * 0.1
    }

    private func scoreKorean(_ text: String) -> Double {
        let koreanCount = countKoreanJamo(text)
        return Double(koreanCount) * 2.0
    }

    private func countJapaneseKana(_ text: String) -> Int {
        var count = 0
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // Hiragana: U+3040..U+309F, Katakana: U+30A0..U+30FF
            if (value >= 0x3040 && value <= 0x309F) || (value >= 0x30A0 && value <= 0x30FF) {
                count += 1
            }
        }
        return count
    }

    private func countKoreanJamo(_ text: String) -> Int {
        var count = 0
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // Hangul Syllables: U+AC00..U+D7AF, Hangul Jamo: U+1100..U+11FF
            if (value >= 0xAC00 && value <= 0xD7AF) || (value >= 0x1100 && value <= 0x11FF) {
                count += 1
            }
        }
        return count
    }

    private func countWordMatches(in text: String, keywords: [String]) -> Int {
        let words = Set(text.components(separatedBy: .whitespacesAndNewlines))
        return keywords.reduce(0) { count, keyword in
            count + (words.contains(keyword) ? 1 : 0)
        }
    }
}
