import SwiftUI

@main
struct UniSumApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkManager = NetworkManager.shared
    @State private var languageChanged = false
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(languageManager)
                .environmentObject(authViewModel)
                .environmentObject(networkManager)
                .environment(\.locale, .init(identifier: languageManager.selectedLanguage))
                .id(languageManager.selectedLanguage) // Force view refresh on language change
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                    languageChanged.toggle()
                }
        }
    }
}
