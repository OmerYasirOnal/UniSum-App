import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var showToast: Bool = false        // Toast görünürlüğü
    @State private var toastMessage: String = ""      // Toast mesajı (localization key)
    @FocusState private var focusedField: Field?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                // Klavye açıldığında alanların gizlenmemesi için ScrollView kullanımı
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 80)
                        
                        welcomeView
                        formView
                        forgotPasswordButton
                        loginButton
                        signupPrompt
                        continueWithoutLoginButton
                            .padding(.top, 10)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal)
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
            TextField(LocalizedStringKey("email"), text: $email)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            
            SecureField(LocalizedStringKey("password"), text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    handleLogin()
                }
        }
    }
    
    private var forgotPasswordButton: some View {
        Button(action: { showForgotPassword = true }) {
            Text(LocalizedStringKey("forgot_password"))
                .font(.subheadline)
                .foregroundColor(.accentColor)
        }
        .accessibilityIdentifier("forgotPasswordButton")
    }
    
    private var loginButton: some View {
        Button(action: handleLogin) {
            Text(LocalizedStringKey("login"))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        }
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
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(15)
        }
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        guard validateForm() else { return }
        
        authViewModel.login(email: email, password: password) { success, errorMessage in
            if success {
                // On success, show success toast message.
                toastMessage = "login_successful"
            } else {
                // On failure, choose appropriate error key.
                switch errorMessage ?? "" {
                case "error_email_not_verified":
                    toastMessage = "error_email_not_verified"
                case "error_invalid_credentials":
                    toastMessage = "error_invalid_credentials"
                default:
                    toastMessage = "error_unknown"
                }
            }
            withAnimation {
                showToast = true
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
}

