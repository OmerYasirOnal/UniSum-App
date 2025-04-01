import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if isActive {
            // Giriş yapmış kullanıcılar için ana sayfaya, diğerleri için giriş sayfasına yönlendir
            if authViewModel.isAuthenticated {
                TermListView()
            } else {
                LoginView()
            }
        } else {
            ZStack {
                // Gradient Arka Plan
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.accentColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    VStack(spacing: 20) {
                        // Logo
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        // Uygulama Adı
                        Text("UniSum")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Slogan veya Açıklama
                        Text(LocalizedStringKey("app_slogan"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        // Animasyon efekti
                        withAnimation(.easeIn(duration: 1.1)) {
                            self.size = 1.0
                            self.opacity = 1.0
                        }
                    }
                }
                .onAppear {
                    // Splash ekranı 2 saniye sonra kapanacak
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(AuthViewModel())
    }
} 