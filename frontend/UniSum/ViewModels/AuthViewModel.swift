import SwiftUI
import Foundation
import os.log

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    private let networkManager = NetworkManager.shared
    @Published var errorMessageKey: LocalizedStringKey?
    
    init() {
        os_log("AuthViewModel initialized", log: OSLog.default, type: .info)
        checkAuthentication()
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        os_log("Attempting login for email: %{public}@", log: OSLog.default, type: .info, email)
        
        let parameters = ["email": email, "password": password]
        networkManager.post(endpoint: "/auth/login", parameters: parameters) { (result: Result<LoginResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.user = response.user
                    self.isAuthenticated = true
                    UserDefaults.standard.set(response.token, forKey: "authToken")
                    UserDefaults.standard.set(response.user.id, forKey: "userId")
                    
                    // Kullanıcıyı JSON'a çevirip saklayın
                    if let encodedUser = try? JSONEncoder().encode(response.user) {
                        UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                        os_log("User data encoded and saved for user id: %d",
                               log: OSLog.default,
                               type: .info,
                               response.user.id)
                    }
                    
                    os_log("Login successful for user id: %d",
                           log: OSLog.default,
                           type: .info,
                           response.user.id)
                    
                    completion(true, nil)
                    
                case .failure(let error):
                    let errorMessage = self.parseError(error)
                    self.errorMessageKey = LocalizedStringKey(errorMessage)
                    os_log("Login failed: %{public}@", log: OSLog.default, type: .error, errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    func handleTokenExpiration(_ error: Error) {
        if let networkError = error as? NetworkError, case .unauthorized = networkError {
            DispatchQueue.main.async {
                os_log("Token expired; performing logout", log: OSLog.default, type: .error)
                self.logout()
                self.errorMessageKey = "error_session_expired" // Localizable: "Your session has expired. Please log in again."
                NotificationCenter.default.post(name: Notification.Name("SessionExpired"), object: nil)
            }
        }
    }
    
    func signup(email: String, password: String, university: String, department: String, completion: @escaping (Bool, String?) -> Void) {
        os_log("Attempting signup for email: %{public}@", log: OSLog.default, type: .info, email)
        
        let parameters = [
            "email": email,
            "password": password,
            "university": university,
            "department": department
        ]
        
        networkManager.post(endpoint: "/auth/signup", parameters: parameters) { (result: Result<SignupResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        os_log("Signup successful for email: %{public}@", log: OSLog.default, type: .info, email)
                        completion(true, response.message)
                    } else {
                        os_log("Signup failed with message: %{public}@", log: OSLog.default, type: .error, response.message)
                        self.errorMessageKey = LocalizedStringKey(response.message)
                        completion(false, response.message)
                    }
                case .failure(let error):
                    let errorMessage = self.parseError(error)
                    os_log("Signup error: %{public}@", log: OSLog.default, type: .error, errorMessage)
                    self.errorMessageKey = LocalizedStringKey(errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    func requestPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
        os_log("Requesting password reset for email: %{public}@", log: OSLog.default, type: .info, email)
        
        let parameters = ["email": email]
        networkManager.post(endpoint: "/auth/password-reset", parameters: parameters) { (result: Result<[String: String], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    os_log("Password reset request successful for email: %{public}@", log: OSLog.default, type: .info, email)
                    completion(true, nil)
                case .failure(let error):
                    let errorMessage = self.parseError(error)
                    os_log("Password reset request failed: %{public}@", log: OSLog.default, type: .error, errorMessage)
                    self.errorMessageKey = LocalizedStringKey(errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    func resetPassword(token: String, newPassword: String, completion: @escaping (Bool, String?) -> Void) {
        os_log("Resetting password with token: %{public}@", log: OSLog.default, type: .info, token)
        
        let parameters = [
            "token": token,
            "newPassword": newPassword
        ]
        
        networkManager.post(endpoint: "/auth/reset-password", parameters: parameters) { (result: Result<[String: String], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseDict):
                    let message = responseDict["message"] ?? "password_updated_successfully"
                    os_log("Password reset successful: %{public}@", log: OSLog.default, type: .info, message)
                    completion(true, message)
                case .failure(let error):
                    let errorMessage = self.parseError(error)
                    os_log("Password reset failed: %{public}@", log: OSLog.default, type: .error, errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    func logout() {
        os_log("Logging out user", log: OSLog.default, type: .info)
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        self.user = nil
        self.isAuthenticated = false
    }
    
    func checkAuthentication() {
        os_log("Checking authentication status", log: OSLog.default, type: .info)
        
        guard let _ = UserDefaults.standard.string(forKey: "authToken"),
              let _ = UserDefaults.standard.string(forKey: "userId") else {
            os_log("Authentication tokens not found; user not authenticated", log: OSLog.default, type: .info)
            isAuthenticated = false
            return
        }
        
        // Kullanıcı bilgilerini UserDefaults'tan yükle
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = savedUser
        }
        
        isAuthenticated = true
        os_log("User is authenticated", log: OSLog.default, type: .info)
    }
    
    private func parseError(_ error: Error) -> String {
        os_log("Parsing error: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
        
        // İnternet bağlantısı yoksa (kod -1009)
        if let nsError = error as NSError? {
            if nsError.domain == NSURLErrorDomain && nsError.code == -1009 {
                return "error_no_connection" // "No network connection. Please check your internet settings."
            }
        }
        
        // NetworkError ise
        if let networkError = error as? NetworkError {
            switch networkError {
            case .badResponse(401):
                return "error_invalid_credentials"
            case .badResponse(403):
                return "error_email_not_verified"
            case .badResponse(409):
                return "error_email_exists"
            case .noResponse:
                return "error_no_connection"
            case .unauthorized:
                return "error_invalid_credentials"
            default:
                return "error_unknown"
            }
        }
        
        // Diğer durumlar
        return "error_unknown"
    }
    
    private func setError(_ key: String) {
        os_log("Setting error with key: %{public}@", log: OSLog.default, type: .error, key)
        errorMessageKey = LocalizedStringKey(key)
    }
}

// MARK: - LoginResponse
struct LoginResponse: Codable {
    let user: User
    let token: String
}
