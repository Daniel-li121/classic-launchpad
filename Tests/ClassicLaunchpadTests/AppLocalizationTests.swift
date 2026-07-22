import Testing
@testable import ClassicLaunchpad

@Suite("Application localization")
struct AppLocalizationTests {
    @Test("Preferred system language selects Chinese, English, or Japanese", arguments: [
        (["zh-Hans-CN"], AppLanguage.simplifiedChinese),
        (["zh_Hant_TW"], AppLanguage.simplifiedChinese),
        (["ja-JP"], AppLanguage.japanese),
        (["en-US"], AppLanguage.english),
        (["fr-FR"], AppLanguage.english),
        ([], AppLanguage.english)
    ])
    func resolvesLanguage(input: ([String], AppLanguage)) {
        #expect(AppLanguage.resolve(preferredLanguages: input.0) == input.1)
    }

    @Test("Every interface string exists in all supported languages")
    func completeTranslations() {
        for language in AppLanguage.allCases {
            for key in AppText.allCases {
                #expect(!L10n.text(key, language: language).isEmpty)
            }
        }
    }

    @Test("Formatted accessibility strings are localized")
    func formattedStrings() {
        #expect(L10n.text(.openApplicationFormat, language: .english) == "Open %@")
        #expect(L10n.text(.openApplicationFormat, language: .simplifiedChinese) == "打开 %@")
        #expect(L10n.text(.openApplicationFormat, language: .japanese) == "%@を開く")
    }
}
