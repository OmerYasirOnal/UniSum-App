import SwiftUI

struct SidebarView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Profil Header
            profileHeader
            
            Divider()
            
            // Menu Items
            menuItems
            
            Spacer()
            
            // Footer & Version
            footerView
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                            isVisible = false
                        }
                    }
                }
        )
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(.systemGray6) : .white,
                    colorScheme == .dark ? Color(.systemGray5) : Color.white.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profil resmi
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.accentColor.opacity(0.8), .accentColor.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.white)
            }
            .padding(.top, 30)
            
            // Kullanıcı bilgisi
            VStack(spacing: 5) {
                Text(authViewModel.user?.email ?? "No Email")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                
                Text(LocalizedStringKey("student"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            colorScheme == .dark ? 
                Color(.systemGray6).opacity(0.8) : 
                Color.white.opacity(0.95)
        )
    }
    
    // MARK: - Menu Items
    private var menuItems: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Profil menü öğesi
                NavigationLink(destination: ProfileView()) {
                    MenuItemView(icon: "person.fill", title: "profile")
                }
                
                // Dil seçimi
                languageSelector
                
                // Çevrimdışı mod
                NavigationLink(destination: OfflineGradeCalculatorView()) {
                    MenuItemView(icon: "wifi.slash", title: "offline_calculator")
                }
                
                Divider()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                
                // Çıkış yap butonu
                Button(action: {
                    withAnimation {
                        isVisible = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            authViewModel.logout()
                        }
                    }
                }) {
                    MenuItemView(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "logout",
                        iconColor: .red,
                        textColor: .red
                    )
                }
            }
            .padding(.vertical, 15)
        }
    }
    
    // MARK: - Language Selector
    private var languageSelector: some View {
        MenuItemView(
            icon: "globe",
            title: "language",
            additionalContent: {
                AnyView(
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: { languageManager.selectedLanguage = "tr" }) {
                                HStack {
                                    Text("Türkçe")
                                    if languageManager.selectedLanguage == "tr" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button(action: { languageManager.selectedLanguage = "en" }) {
                                HStack {
                                    Text("English")
                                    if languageManager.selectedLanguage == "en" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Text(languageManager.currentLanguageDisplayName)
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(8)
                                )
                        }
                    }
                )
            }
        )
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        VStack(spacing: 5) {
            Divider()
            
            HStack {
                Text("UniSum")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.vertical, 10)
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: LocalizedStringKey
    var iconColor: Color = .primary
    var textColor: Color = .primary
    var additionalContent: (() -> AnyView)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // İkon arka planı
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                )
            
            Text(title)
                .foregroundColor(textColor)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let content = additionalContent {
                content()
            } else {
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.clear)
    }
}
