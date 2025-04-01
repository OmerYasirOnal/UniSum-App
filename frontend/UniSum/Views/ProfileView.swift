import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showConfirmationDialog = false  // Hesap silme onayı
    @State private var isAccountDeleted = false          // Hesap silindi mi?
    @State private var showToast: Bool = false           // Toast görünürlüğü
    @State private var toastMessage: String = "account_deleted"  // Localizable key
    @State private var toastType: Toast.ToastType = .success
    @State private var navigateToLogin = false           // Login ekranına yönlendirme

    var body: some View {
        NavigationView {
            Form {
                // Hesap Bilgileri Bölümü
                Section(header: Text(LocalizedStringKey("account_information"))) {
                    HStack {
                        Text(LocalizedStringKey("email"))
                        Spacer()
                        Text(authViewModel.user?.email ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(LocalizedStringKey("university"))
                        Spacer()
                        Text(authViewModel.user?.university ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(LocalizedStringKey("department"))
                        Spacer()
                        Text(authViewModel.user?.department ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Dil Seçimi Bölümü
                Section(header: Text(LocalizedStringKey("language"))) {
                    Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                        Text("🇺🇸 " + LocalizedStringKey("english").stringValue)
                            .tag("en")
                        Text("🇹🇷 " + LocalizedStringKey("turkish").stringValue)
                            .tag("tr")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Hesap Silme Bölümü
                Section {
                    Button(action: {
                        showConfirmationDialog.toggle()
                    }) {
                        Text(LocalizedStringKey("delete_account"))
                            .foregroundColor(.red)
                    }
                    .confirmationDialog(
                        LocalizedStringKey("are_you_sure_delete"),
                        isPresented: $showConfirmationDialog,
                        titleVisibility: .visible
                    ) {
                        Button(LocalizedStringKey("yes_delete"), role: .destructive) {
                            deleteAccount()
                        }
                        Button(LocalizedStringKey("cancel"), role: .cancel) {}
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("profile"))
            // Yönlendirme: Login ekranına geçiş
            .background(
                NavigationLink(
                    destination: LoginView(),
                    isActive: $navigateToLogin,
                    label: { EmptyView() }
                )
            )
        }
        // Toast bildirimi: Ekranın üst kısmından aşağı kayarak görünür
        .toast(isShowing: $showToast, message: toastMessage, duration: 3.0)
        .animation(.easeInOut, value: showToast)
    }
    
    private func deleteAccount() {
        NetworkManager.shared.delete(endpoint: "/auth/delete-account", requiresAuth: true) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isAccountDeleted = true
                    toastMessage = "account_deleted"  // Localizable key
                    toastType = .success
                    showToast = true
                    
                    // 2 saniye sonra login ekranına yönlendir
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        authViewModel.logout()
                        navigateToLogin = true
                    }
                    
                case .failure(let error):
                    toastMessage = "error_deleting_account"  // Localizable key
                    toastType = .error
                    showToast = true
                    print(error.localizedDescription)
                }
            }
        }
    }
}

// LocalizedStringKey'den string değer çekmek için yardımcı genişletme
extension LocalizedStringKey {
    var stringValue: String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "key", let value = child.value as? String {
                return value
            }
        }
        return ""
    }
}
