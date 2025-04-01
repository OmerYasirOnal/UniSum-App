import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var languageChanged = false
    
    var body: some View {
        ZStack {
            Group {
                if authViewModel.isAuthenticated {
                    TermListView()
                } else {
                    LoginView()
                }
            }
            .environment(\.locale, .init(identifier: languageManager.selectedLanguage))
            .id(languageManager.selectedLanguage)
            
            // Bağlantı hatası iletişim kutusu
            if networkManager.showConnectionAlert {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Dışarı tıklandığında kapatma işlemi
                        networkManager.dismissConnectionAlert()
                    }
                
                ConnectionAlertView(networkManager: networkManager)
                    .padding()
                    .transition(.scale)
            }
        }
        .onAppear {
            authViewModel.checkAuthentication()
            
            // Token expire notification'ını dinle
            NotificationCenter.default.addObserver(
                forName: Notification.Name("TokenExpired"),
                object: nil,
                queue: .main
            ) { _ in
                authViewModel.logout()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .animation(.easeInOut, value: networkManager.showConnectionAlert)
    }
}
