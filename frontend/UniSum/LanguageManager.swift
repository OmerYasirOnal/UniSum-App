import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    // MARK: - Properties
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: UserDefaultsKeys.selectedLanguage)
            Bundle.setLanguage(selectedLanguage)
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    
    // MARK: - Constants
    private enum UserDefaultsKeys {
        static let selectedLanguage = "selectedLanguage"
    }
    
    private let supportedLanguages = ["en", "tr"]
    
    // MARK: - Computed Properties
    var displayText: String {
        switch selectedLanguage {
        case "tr": return "Dil"
        case "en": return "Language"
        default: return "Language"
        }
    }
    
    var currentLanguageDisplayName: String {
        switch selectedLanguage {
        case "tr": return "Türkçe"
        case "en": return "English"
        default: return "English"
        }
    }
    
    // MARK: - Initialization
    init() {
        let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        let supportedLanguage = supportedLanguages.contains(deviceLanguage) ? deviceLanguage : "en"
        self.selectedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage) ?? supportedLanguage
        Bundle.setLanguage(selectedLanguage)
    }
    
    // MARK: - Public Methods
    func toggleLanguage() {
        selectedLanguage = selectedLanguage == "en" ? "tr" : "en"
    }
    
    func updateLanguage(_ newLanguage: String) {
        guard supportedLanguages.contains(newLanguage) else { return }
        
        UserDefaults.standard.set(newLanguage, forKey: UserDefaultsKeys.selectedLanguage)
        self.selectedLanguage = newLanguage
        Bundle.setLanguage(newLanguage)
        reloadApp()
    }
    
    // MARK: - Static Methods
    static func getStoredLanguage() -> String {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage)
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
    }
    
    // MARK: - Private Methods
    private func reloadApp() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return
            }
            
            let rootView = ContentView()
                .environmentObject(self)
            
            window.rootViewController = UIHostingController(rootView: rootView)
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - Bundle Extension for Language Switching
private var bundleKey: UInt8 = 0

extension Bundle {
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("Warning: Could not find bundle for language: \(language)")
            return
        }
        
        objc_setAssociatedObject(
            Bundle.main,
            &bundleKey,
            bundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    private class PrivateBundle: Bundle {
        override func localizedString(forKey key: String,
                                   value: String?,
                                   table tableName: String?) -> String {
            guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
            
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}
