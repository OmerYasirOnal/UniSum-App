import SwiftUI
import Foundation

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var university = ""
    @State private var department = ""
    @State private var isLoading = false
    @State private var showToast: Bool = false         // Toast görünürlüğü
    @State private var toastMessage: String = ""       // Toast mesajı (localization key)
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, university, department
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        formView
                        signupButton
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(LocalizedStringKey("back"))
                        }
                    }
                }
            }
        }
        // Toast bildirimi, ekranın üst kısmından aşağı doğru kayarak görünecek.
        .toast(isShowing: $showToast, message: toastMessage, duration: 3.0)
        .animation(.easeInOut, value: showToast)
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        Text(LocalizedStringKey("create_account"))
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .padding(.top, 50)
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
                .textContentType(.newPassword)
                .focused($focusedField, equals: .password)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .university
                }
            
            TextField(LocalizedStringKey("university"), text: $university)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .textContentType(.organizationName)
                .focused($focusedField, equals: .university)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .department
                }
            
            TextField(LocalizedStringKey("department"), text: $department)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .textContentType(.none)
                .focused($focusedField, equals: .department)
                .submitLabel(.done)
                .onSubmit {
                    handleSignup()
                }
        }
        .padding(.top, 20)
    }
    
    private var signupButton: some View {
        Button(action: handleSignup) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .disabled(!isFormValid() || isLoading)
        .opacity(isFormValid() && !isLoading ? 1 : 0.6)
        .padding(.top, 20)
    }
    
    // MARK: - Validation and Signup Process
    
    private func isFormValid() -> Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !university.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleSignup() {
        guard validateForm() else { return }
        
        isLoading = true
        authViewModel.signup(
            email: email,
            password: password,
            university: university,
            department: department
        ) { success, messageKey in
            isLoading = false
            if success {
                toastMessage = messageKey ?? "verification_email_sent"
                withAnimation { showToast = true }
                // 2 saniye sonra Login ekranına yönlendirme
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } else {
                toastMessage = messageKey ?? "error_unknown"
                withAnimation { showToast = true }
            }
        }
    }
    
    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmed
        let trimmedPassword = password.trimmed
        
        if !trimmedEmail.isNotEmpty {
            toastMessage = "error_email_required"
            withAnimation { showToast = true }
            return false
        }
        
        if !trimmedEmail.isValidEmail {
            toastMessage = "error_invalid_email_format"
            withAnimation { showToast = true }
            return false
        }
        
        if !trimmedPassword.isNotEmpty {
            toastMessage = "error_password_required"
            withAnimation { showToast = true }
            return false
        }
        
        if !trimmedPassword.isValidPassword {
            toastMessage = "error_password_too_short"
            withAnimation { showToast = true }
            return false
        }
        
        if university.trimmed.isEmpty {
            toastMessage = "error_university_required"
            withAnimation { showToast = true }
            return false
        }
        
        if department.trimmed.isEmpty {
            toastMessage = "error_department_required"
            withAnimation { showToast = true }
            return false
        }
        
        return true
    }
}

// MARK: - Helpers

