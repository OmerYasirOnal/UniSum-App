import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var showToast: Bool = false        // Toast görünürlüğü
    @State private var toastMessage: String = ""      // Toast mesajı (localization key)
    @State private var showVerificationAlert = false  // E-posta doğrulama uyarısı
    @State private var showPassword = false          // Şifre görünürlüğü için
    @FocusState private var focusedField: Field?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan rengi yerine gradient kullanma
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                // Klavye açıldığında alanların gizlenmemesi için ScrollView kullanımı
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 60)
                        
                        // Logo ve app icon
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 10)
                        
                        welcomeView
                        formView
                        forgotPasswordButton
                        loginButton
                        signupPrompt
                        continueWithoutLoginButton
                            .padding(.top, 10)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 25)
                }
                .animation(.easeInOut, value: email)
                .animation(.easeInOut, value: password)
            }
            .overlay(
                // Ekranın üst köşesinde sabit dil seçici
                HStack {
                    Spacer()
                    languageSelector
                }
                .padding(.top, 10)
                .padding(.trailing, 16)
                .ignoresSafeArea(.keyboard, edges: .top),
                alignment: .top
            )
        }
        // SignUp ve ForgotPassword ekranlarının modal sunumu
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        // Giriş başarılı olduğunda uygulamanın ana akışına geçiş
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            TermListView()
        }
        // Yeni toaste göre: Üstten bildirimi göster
        .toast(isShowing: $showToast, message: toastMessage, duration: 3.0)
        .animation(.easeInOut, value: showToast)
        .alert(isPresented: $showVerificationAlert) {
            Alert(
                title: Text(LocalizedStringKey("email_verification")),
                message: Text(NSLocalizedString("email_not_verified_message", comment: "")),
                primaryButton: .default(Text(LocalizedStringKey("resend_verification"))) {
                    resendVerificationEmail()
                },
                secondaryButton: .cancel(Text(LocalizedStringKey("cancel")))
            )
        }
    }
    
    // MARK: - UI Components
    
    private var welcomeView: some View {
        Text(LocalizedStringKey("welcome_back"))
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .padding(.bottom, 20)
    }
    
    private var formView: some View {
        VStack(spacing: 15) {
            // Email alanı
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey("email"))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 4)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                    
                    TextField(LocalizedStringKey("email"), text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.systemBackground).cornerRadius(12))
                )
            }
            
            // Şifre alanı
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey("password"))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 4)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                    
                    if showPassword {
                        TextField(LocalizedStringKey("password"), text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                handleLogin()
                            }
                    } else {
                        SecureField(LocalizedStringKey("password"), text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                handleLogin()
                            }
                    }
                    
                    // Şifre görünürlük butonu
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.systemBackground).cornerRadius(12))
                )
            }
        }
    }
    
    private var forgotPasswordButton: some View {
        Button(action: { showForgotPassword = true }) {
            Text(LocalizedStringKey("forgot_password"))
                .font(.subheadline)
                .foregroundColor(.accentColor)
        }
        .padding(.top, 5)
        .accessibilityIdentifier("forgotPasswordButton")
    }
    
    private var loginButton: some View {
        Button(action: handleLogin) {
            Text(LocalizedStringKey("login"))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.top, 10)
        .accessibilityIdentifier("loginButton")
    }
    
    private var signupPrompt: some View {
        HStack {
            Text(LocalizedStringKey("no_account"))
            Button(action: { showSignup = true }) {
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.top, 10)
        .accessibilityIdentifier("signupPrompt")
    }
    
    private var continueWithoutLoginButton: some View {
        NavigationLink(destination: OfflineGradeCalculatorView()) {
            HStack(spacing: 8) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.caption)
                Text(LocalizedStringKey("continue_without_login"))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .stroke(Color.accentColor, lineWidth: 1)
            )
        }
        .accessibilityIdentifier("continueWithoutLoginButton")
    }
    
    private var languageSelector: some View {
        Menu {
            Button(action: { languageManager.selectedLanguage = "tr" }) {
                Label("Türkçe", systemImage: languageManager.selectedLanguage == "tr" ? "checkmark" : "")
            }
            Button(action: { languageManager.selectedLanguage = "en" }) {
                Label("English", systemImage: languageManager.selectedLanguage == "en" ? "checkmark" : "")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                Text(LocalizedStringKey("language"))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.15))
            )
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        guard validateForm() else { return }
        
        // İnternet bağlantısı kontrolü
        if !NetworkManager.shared.isConnected {
            // İnternet bağlantısı yoksa, ToastView gösterme (ConnectionAlert zaten gösterilecek)
            return
        }
        
        authViewModel.login(email: email, password: password) { success, errorMessage in
            if success {
                // On success, show success toast message.
                toastMessage = "login_successful"
                withAnimation {
                    showToast = true
                }
            } else {
                // Bağlantı hatası durumunda toast gösterme (NetworkManager.swift'te alert gösterilecek)
                if errorMessage == "error_no_connection" {
                    return
                }
                
                // On failure, choose appropriate error key.
                switch errorMessage ?? "" {
                case "error_email_not_verified":
                    showVerificationAlert = true
                case "error_invalid_credentials":
                    toastMessage = "error_invalid_credentials"
                    withAnimation {
                        showToast = true
                    }
                default:
                    toastMessage = "error_unknown"
                    withAnimation {
                        showToast = true
                    }
                }
            }
        }
    }
    
    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            showErrorToast(message: "error_email_required")
            return false
        }
        
        guard trimmedEmail.isValidEmailLogin else {
            showErrorToast(message: "error_invalid_email_format")
            return false
        }
        
        guard !trimmedPassword.isEmpty else {
            showErrorToast(message: "error_password_required")
            return false
        }
        
        return true
    }
    
    private func showErrorToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
    
    private func resendVerificationEmail() {
        authViewModel.resendVerificationEmail(email: email) { success, message in
            if success {
                toastMessage = "verification_email_sent"
            } else {
                toastMessage = message ?? "error_unknown"
            }
            withAnimation {
                showToast = true
            }
        }
    }
}

