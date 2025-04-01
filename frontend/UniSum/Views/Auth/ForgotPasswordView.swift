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
        ZStack {
            // Main content
            VStack(spacing: 16) {
                // Başlık: Şifre Sıfırlama
                Text("forgot_password_title")  // Localized key, e.g. "Forgot Password"
                    .font(.title)
                    .bold()
                    .padding(.bottom, 8)
                // Email giriş alanı
                TextField(LocalizedStringKey("forgot_password_email_placeholder"), text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .accessibilityLabel(Text("forgot_password_email_placeholder"))
                // Reset Password submission button
                Button(action: submitReset) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("forgot_password_submit_button")  // Localized key, e.g. "Reset Password"
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading)
                .buttonStyle(.borderedProminent)
                .cornerRadius(8)
            }
            .padding()
            .disabled(isLoading)

            // If needed, you can also overlay a custom loading indicator here
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
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    toastMessage = "forgot_password_network_error" // Localized key
                } else if let resetError = error as? ResetPasswordError, resetError == .emailNotFound {
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
