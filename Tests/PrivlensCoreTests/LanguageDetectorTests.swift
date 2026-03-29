import Testing
@testable import PrivlensCore

@Suite("LanguageDetector Tests")
struct LanguageDetectorTests {
    let detector = LanguageDetector()

    @Test("Detects English text")
    func detectEnglish() {
        let text = """
        This is an agreement between the parties. The contract should be reviewed \
        carefully before signing. Your rights and obligations are described within \
        this document. Please read the terms and conditions.
        """
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .english)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects Spanish text")
    func detectSpanish() {
        let text = """
        Este es un contrato entre las partes. El acuerdo debe ser revisado \
        cuidadosamente antes de firmar. Sus derechos y obligaciones est\u{00E1}n \
        descritos en este documento. Por favor lea los t\u{00E9}rminos y condiciones. \
        Esta informaci\u{00F3}n es confidencial para los involucrados.
        """
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .spanish)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects French text")
    func detectFrench() {
        let text = """
        Ceci est un contrat entre les parties. L'accord doit \u{00EA}tre examin\u{00E9} \
        attentivement avant de signer. Vos droits et obligations sont d\u{00E9}crits \
        dans ce document. Veuillez lire les termes et conditions. \
        Cette information est confidentielle pour les personnes concern\u{00E9}es.
        """
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .french)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects German text")
    func detectGerman() {
        let text = """
        Dies ist ein Vertrag zwischen den Parteien. Die Vereinbarung muss \
        sorgf\u{00E4}ltig gepr\u{00FC}ft werden. Ihre Rechte und Pflichten sind \
        in diesem Dokument beschrieben. F\u{00FC}r weitere Informationen wenden \
        Sie sich an die zust\u{00E4}ndige Stelle. Das Formular ist vollst\u{00E4}ndig auszuf\u{00FC}llen.
        """
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .german)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects Chinese text")
    func detectChinese() {
        let text = "\u{8FD9}\u{662F}\u{4E00}\u{4EFD}\u{5408}\u{540C}\u{6587}\u{4EF6}\u{3002}\u{8BF7}\u{4ED4}\u{7EC6}\u{9605}\u{8BFB}\u{6240}\u{6709}\u{6761}\u{6B3E}\u{548C}\u{6761}\u{4EF6}\u{3002}\u{60A8}\u{7684}\u{6743}\u{5229}\u{548C}\u{4E49}\u{52A1}\u{5728}\u{672C}\u{6587}\u{4EF6}\u{4E2D}\u{6709}\u{8BE6}\u{7EC6}\u{8BF4}\u{660E}\u{3002}"
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .chinese)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects Japanese text")
    func detectJapanese() {
        let text = "\u{3053}\u{308C}\u{306F}\u{5951}\u{7D04}\u{66F8}\u{3067}\u{3059}\u{3002}\u{3059}\u{3079}\u{3066}\u{306E}\u{6761}\u{4EF6}\u{3092}\u{6CE8}\u{610F}\u{6DF1}\u{304F}\u{304A}\u{8AAD}\u{307F}\u{304F}\u{3060}\u{3055}\u{3044}\u{3002}\u{3042}\u{306A}\u{305F}\u{306E}\u{6A29}\u{5229}\u{3068}\u{7FA9}\u{52D9}\u{306F}\u{3053}\u{306E}\u{6587}\u{66F8}\u{306B}\u{8A18}\u{8F09}\u{3055}\u{308C}\u{3066}\u{3044}\u{307E}\u{3059}\u{3002}"
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .japanese)
        #expect(result.confidence > 0.3)
    }

    @Test("Detects Korean text")
    func detectKorean() {
        let text = "\u{C774}\u{AC83}\u{C740} \u{ACC4}\u{C57D}\u{C11C}\u{C785}\u{B2C8}\u{B2E4}. \u{BAA8}\u{B4E0} \u{C870}\u{AC74}\u{C744} \u{C8FC}\u{C758} \u{AE4A}\u{AC8C} \u{C77D}\u{C5B4} \u{C8FC}\u{C2ED}\u{C2DC}\u{C624}. \u{ADE0}\u{C758} \u{AD8C}\u{B9AC}\u{C640} \u{C758}\u{BB34}\u{B294} \u{C774} \u{BB38}\u{C11C}\u{C5D0} \u{C124}\u{BA85}\u{B418}\u{C5B4} \u{C788}\u{C2B5}\u{B2C8}\u{B2E4}."
        let result = detector.detectLanguage(from: text)
        #expect(result.primaryLanguage == .korean)
        #expect(result.confidence > 0.3)
    }

    @Test("Returns English with low confidence for empty text")
    func detectEmptyText() {
        let result = detector.detectLanguage(from: "")
        #expect(result.primaryLanguage == .english)
        #expect(result.confidence == 0.0)
    }

    @Test("Detection result includes multiple languages")
    func detectionResultHasMultipleLanguages() {
        let text = "This is an English document with the agreement and contract terms."
        let result = detector.detectLanguage(from: text)
        #expect(!result.detectedLanguages.isEmpty)
    }

    @Test("LanguageSettings has sensible defaults")
    func languageSettingsDefaults() {
        let settings = LanguageSettings.default
        #expect(settings.preferredLanguage == .english)
        #expect(settings.autoDetectLanguage == true)
        #expect(settings.autoTranslateResults == false)
    }

    @Test("LanguageSettings is codable")
    func languageSettingsCodable() throws {
        let settings = LanguageSettings(
            preferredLanguage: .spanish,
            autoDetectLanguage: false,
            autoTranslateResults: true
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(LanguageSettings.self, from: data)
        #expect(decoded.preferredLanguage == .spanish)
        #expect(decoded.autoDetectLanguage == false)
        #expect(decoded.autoTranslateResults == true)
    }

    @Test("SupportedLanguage has all required properties")
    func supportedLanguageProperties() {
        for language in SupportedLanguage.allCases {
            #expect(!language.displayName.isEmpty)
            #expect(!language.nativeDisplayName.isEmpty)
            #expect(!language.languageTag.isEmpty)
            #expect(!language.rawValue.isEmpty)
        }
    }

    @Test("LanguageDetectionResult is codable")
    func detectionResultCodable() throws {
        let result = LanguageDetectionResult(
            primaryLanguage: .french,
            confidence: 0.85,
            detectedLanguages: [(.french, 0.85), (.english, 0.15)]
        )
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(LanguageDetectionResult.self, from: data)
        #expect(decoded.primaryLanguage == .french)
        #expect(decoded.confidence == 0.85)
    }

    @Test("TranslationService throws sameLanguage error")
    func translationSameLanguageError() async throws {
        let service = TranslationService()
        await #expect(throws: TranslationError.self) {
            try await service.translate(text: "Hello", from: .english, to: .english)
        }
    }
}
