import SwiftUI

@main
struct UniSumApp: App {
    @StateObject private var languageManager = LanguageManager()
    @State private var languageChanged = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environment(\.locale, .init(identifier: languageManager.selectedLanguage))
                .id(languageManager.selectedLanguage) // Force view refresh on language change
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                    languageChanged.toggle()
                }
        }
    }
}
