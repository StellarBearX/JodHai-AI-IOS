import SwiftUI

enum AppLanguage: String, CaseIterable {
    case thai = "th"
    case english = "en"

    var displayName: String {
        switch self {
        case .thai:    return "ภาษาไทย"
        case .english: return "English"
        }
    }
    var flag: String {
        switch self {
        case .thai:    return "🇹🇭"
        case .english: return "🇬🇧"
        }
    }
}

@Observable
final class LanguageManager {
    @ObservationIgnored
    @AppStorage("app_language") private var storedLanguage: String = AppLanguage.thai.rawValue

    var language: AppLanguage {
        get { AppLanguage(rawValue: storedLanguage) ?? .thai }
        set { storedLanguage = newValue.rawValue }
    }

    // t() = translate: first arg = Thai, second = English
    func t(_ thai: String, _ english: String) -> String {
        language == .thai ? thai : english
    }

    // Category display names
    func categoryName(_ raw: String) -> String {
        if language == .thai {
            switch raw {
            case "Food":          return "อาหาร"
            case "Transport":     return "เดินทาง"
            case "Shopping":      return "ช็อปปิ้ง"
            case "Health":        return "สุขภาพ"
            case "Entertainment": return "บันเทิง"
            case "Bills":         return "ค่าใช้จ่าย"
            case "Other":         return "อื่นๆ"
            default:              return raw
            }
        }
        return raw
    }
}
