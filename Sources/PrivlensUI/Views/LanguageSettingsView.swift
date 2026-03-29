#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct LanguageSettingsView: View {
    @State private var settings: LanguageSettings

    private let onSave: (LanguageSettings) -> Void

    public init(
        settings: LanguageSettings = .default,
        onSave: @escaping (LanguageSettings) -> Void = { _ in }
    ) {
        self._settings = State(initialValue: settings)
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            // Preferred Language
            Section {
                Picker("Preferred Language", selection: $settings.preferredLanguage) {
                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                            Text("(\(language.nativeDisplayName))")
                                .foregroundStyle(.secondary)
                        }
                        .tag(language)
                        .accessibilityLabel("\(language.displayName), \(language.nativeDisplayName)")
                    }
                }
                .accessibilityIdentifier("languageSettingsPreferredLanguage")
            } header: {
                Text("Preferred Language")
            } footer: {
                Text("Analysis results will be displayed in this language when translation is enabled.")
            }

            // Detection Settings
            Section {
                Toggle("Auto-Detect Language", isOn: $settings.autoDetectLanguage)
                    .accessibilityIdentifier("languageSettingsAutoDetect")
                    .accessibilityHint("When enabled, Privlens will automatically detect the language of scanned documents")

                Toggle("Auto-Translate Results", isOn: $settings.autoTranslateResults)
                    .accessibilityIdentifier("languageSettingsAutoTranslate")
                    .accessibilityHint("When enabled, analysis results will be automatically translated to your preferred language")
            } header: {
                Text("Language Detection")
            } footer: {
                Text("Auto-detect identifies the document language from OCR text. Auto-translate converts analysis results to your preferred language using on-device AI.")
            }

            // Supported Languages Info
            Section {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        Text(language.nativeDisplayName)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(language.displayName), \(language.nativeDisplayName)")
                }
            } header: {
                Text("Supported Languages")
            } footer: {
                Text("All language processing happens on-device. No document data is ever sent to external servers.")
            }
        }
        .navigationTitle("Language")
        .onChange(of: settings) { _, newSettings in
            onSave(newSettings)
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
#endif
