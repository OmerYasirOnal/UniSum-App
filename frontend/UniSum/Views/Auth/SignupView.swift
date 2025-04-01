import SwiftUI
import Foundation
import UIKit

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
    @State private var showVerificationAlert = false   // Doğrulama uyarısı
    @State private var registeredEmail = ""            // Kayıt olan e-posta
    @State private var showPassword = false           // Şifre görünürlüğü için
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, university, department
    }
    
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
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        formView
                        signupButton
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 25)
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
        .alert(isPresented: $showVerificationAlert) {
            Alert(
                title: Text(LocalizedStringKey("registration_successful")),
                message: Text(String(format: NSLocalizedString("verification_alert_message", comment: ""), registeredEmail)),
                dismissButton: .default(Text(LocalizedStringKey("ok"))) {
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        VStack {
            // App icon
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)
                
            Text(LocalizedStringKey("create_account"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
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
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .university
                            }
                    } else {
                        SecureField(LocalizedStringKey("password"), text: $password)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .university
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
            
            // Üniversite alanı
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey("university"))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 4)
                
                HStack {
                    Image(systemName: "building.columns")
                        .foregroundColor(.secondary)
                    
                    TextField(LocalizedStringKey("university"), text: $university)
                        .textContentType(.organizationName)
                        .focused($focusedField, equals: .university)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .department
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.systemBackground).cornerRadius(12))
                )
            }
            
            // Bölüm alanı
            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey("department"))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 4)
                
                HStack {
                    Image(systemName: "book")
                        .foregroundColor(.secondary)
                    
                    TextField(LocalizedStringKey("department"), text: $department)
                        .textContentType(.none)
                        .focused($focusedField, equals: .department)
                        .submitLabel(.done)
                        .onSubmit {
                            handleSignup()
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
        
        // İnternet bağlantısı kontrolü
        if !NetworkManager.shared.isConnected {
            // İnternet bağlantısı yoksa, ToastView gösterme (ConnectionAlert zaten gösterilecek)
            return
        }
        
        isLoading = true
        authViewModel.signup(
            email: email,
            password: password,
            university: university,
            department: department
        ) { success, messageKey in
            isLoading = false
            
            // Bağlantı hatası durumunda toast gösterme (NetworkManager.swift'te alert gösterilecek)
            if messageKey == "error_no_connection" {
                return
            }
            
            if success {
                registeredEmail = email
                toastMessage = "verification_email_sent"
                withAnimation { showToast = true }
                showVerificationAlert = true
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

