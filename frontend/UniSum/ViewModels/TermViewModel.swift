import Foundation

class TermViewModel: ObservableObject {
    // MARK: - Properties
    @Published var terms: [Term] = []
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Term Operations
    func fetchTerms() {
        isLoading = true
        
        networkManager.get(endpoint: "/terms/my-terms", requiresAuth: true) { [weak self] (result: Result<[Term], Error>) in
            DispatchQueue.main.async {
                self?.handleFetchTermsResponse(result)
            }
        }
    }
    
    // Her bir dönem için derslerini getir
    private func fetchCoursesForTerms() {
        for (index, term) in terms.enumerated() {
            fetchCoursesForTerm(at: index, termId: term.id)
        }
    }
    
    // Belirli bir dönem için derslerini getir
    private func fetchCoursesForTerm(at index: Int, termId: Int) {
        networkManager.get(endpoint: "/terms/\(termId)/courses", requiresAuth: true) { [weak self] (result: Result<[Course], Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let courses):
                    // Mevcut termin kopyasını al
                    var updatedTerm = self.terms[index]
                    // Dersleri ekle
                    updatedTerm.courses = courses
                    // Güncellenen terimi yerleştir
                    self.terms[index] = updatedTerm
                    
                case .failure(let error):
                    print("Dönem \(termId) için dersler getirilirken hata oluştu: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addTerm(classLevel: String, termNumber: Int) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.errorMessage = "Kullanıcı kimliği bulunamadı"
            return
        }
        
        let parameters: [String: Any] = [
            "user_id": userId,
            "class_level": classLevel,
            "term_number": termNumber
        ]
        
        networkManager.post(endpoint: "/terms", parameters: parameters, requiresAuth: true) { [weak self] (result: Result<Term, Error>) in
            DispatchQueue.main.async {
                self?.handleAddTermResponse(result)
            }
        }
    }
    
    func deleteTerm(termId: Int, completion: @escaping (Bool) -> Void) {
        networkManager.delete(endpoint: "/terms/\(termId)", requiresAuth: true) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDeleteTermResponse(result, termId: termId, completion: completion)
            }
        }
    }
    
    // MARK: - Response Handlers
    private func handleFetchTermsResponse(_ result: Result<[Term], Error>) {
        isLoading = false
        
        switch result {
        case .success(let terms):
            self.terms = terms
            self.errorMessage = ""
            
            // Dönemler yüklendikten sonra her bir dönem için dersleri yükle
            fetchCoursesForTerms()
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleAddTermResponse(_ result: Result<Term, Error>) {
        switch result {
        case .success:
            fetchTerms()
            errorMessage = ""
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleDeleteTermResponse(_ result: Result<Void, Error>, termId: Int, completion: @escaping (Bool) -> Void) {
        switch result {
        case .success:
            terms.removeAll { $0.id == termId }
            errorMessage = ""
            completion(true)
            
        case .failure(let error):
            handleError(error)
            fetchTerms()
            completion(false)
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                NotificationCenter.default.post(
                    name: Notification.Name("TokenExpired"),
                    object: nil
                )
                errorMessage = "Oturum süresi doldu. Lütfen tekrar giriş yapın."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
