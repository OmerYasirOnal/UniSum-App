import SwiftUI

struct ForgotPasswordView: View {
    // Environment and state properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showToast: Bool = false      // Toast görünürlüğü
    @State private var toastMessage: String = ""    // Toast mesajı (localization key)
    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .onTapGesture {
                    emailFocused = false
                }
                
                // Main content
                VStack(spacing: 24) {
                    // App icon
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 5)
                    
                    // Başlık: Şifre Sıfırlama
                    Text(LocalizedStringKey("forgot_password_title"))
                        .font(.title)
                        .bold()
                        .padding(.bottom, 8)
                    
                    // Açıklama metni
                    Text(LocalizedStringKey("forgot_password_description"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                    
                    // Email giriş alanı
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LocalizedStringKey("email"))
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.leading, 4)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            
                            TextField(LocalizedStringKey("forgot_password_email_placeholder"), text: $email)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .disableAutocorrection(true)
                                .focused($emailFocused)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.systemBackground).cornerRadius(12))
                        )
                        .accessibilityLabel(Text("forgot_password_email_placeholder"))
                    }
                    
                    // Reset Password submission button
                    Button(action: submitReset) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text(LocalizedStringKey("forgot_password_submit_button"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
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
                    .opacity(isValidEmail(email.trimmed) ? 1 : 0.6)
                    .disabled(isLoading || !isValidEmail(email.trimmed))
                    
                    // Geri butonu
                    Button(action: { dismiss() }) {
                        Text(LocalizedStringKey("cancel"))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 40)
                .disabled(isLoading)
            }
            .navigationBarHidden(true)
        }
        // Attach toast using the modifier: toast appears from top
        .toast(isShowing: $showToast, message: toastMessage, duration: 3.0)
        .animation(.easeInOut, value: showToast)
    }

    /// Validates email and submits the password reset request.
    private func submitReset() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        // Validate email format
        guard !trimmedEmail.isEmpty, isValidEmail(trimmedEmail) else {
            toastMessage = "forgot_password_invalid_email_error" // Localized key
            withAnimation { showToast = true }
            return
        }
        
        // İnternet bağlantısı kontrolü
        if !NetworkManager.shared.isConnected {
            // İnternet bağlantısı yoksa, ToastView gösterme (ConnectionAlert zaten gösterilecek)
            return
        }
        
        // Input is valid, proceed with request
        isLoading = true

        // Simulate network request (replace with real API call in production)
        Task {
            do {
                try await simulateNetworkRequest(for: trimmedEmail)
                // On success: show confirmation message and dismiss view after delay
                isLoading = false
                toastMessage = "forgot_password_success_message" // Localized key
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            } catch {
                isLoading = false
                
                // Bağlantı hatası durumunda toast gösterme (ConnectionAlert zaten gösterilecek)
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    return
                }
                
                if let resetError = error as? ResetPasswordError, resetError == .emailNotFound {
                    toastMessage = "forgot_password_email_not_found_error" // Localized key
                } else {
                    toastMessage = "forgot_password_unknown_error" // Localized key
                }
                withAnimation { showToast = true }
            }
        }
    }

    /// Basic email format validation using regex.
    private func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailPattern).evaluate(with: email)
    }

    /// Dummy network call to simulate server responses.
    private func simulateNetworkRequest(for email: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)  // simulate 1-second delay
        if email.contains("notfound") {
            throw ResetPasswordError.emailNotFound
        } else if email.contains("serverfail") {
            throw URLError(.badServerResponse)
        }
        // Otherwise, simulate success
    }
}

// Custom error type for specific password reset errors
enum ResetPasswordError: Error {
    case emailNotFound
}

