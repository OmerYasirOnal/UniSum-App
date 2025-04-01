import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL: String
    
    private init() {
            guard let secretsURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: secretsURL),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                  let secretsDict = plist as? [String: Any],
                  let url = secretsDict["BaseURL"] as? String else {
                fatalError("BaseURL Secrets.plist içinde bulunamadı veya format yanlış!")
            }
            self.baseURL = url
        }
    // MARK: - Core Network Request Method
    private func makeRequest<T: Decodable>(
           endpoint: String,
           method: String,
           parameters: [String: Any]? = nil,
           requiresAuth: Bool = false,
           completion: @escaping (Result<T, Error>) -> Void
       ) {
           guard let url = URL(string: "\(baseURL)\(endpoint)") else {
               completion(.failure(NetworkError.invalidURL))
               return
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = method
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           if requiresAuth {
               guard let token = UserDefaults.standard.string(forKey: "authToken") else {
                   completion(.failure(NetworkError.unauthorized))
                   return
               }
               request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           }
           
           if let parameters = parameters {
               do {
                   request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
               } catch {
                   completion(.failure(NetworkError.invalidParameters))
                   return
               }
           }
           
           URLSession.shared.dataTask(with: request) { data, response, error in
               if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                   DispatchQueue.main.async {
                       NotificationCenter.default.post(name: Notification.Name("TokenExpired"), object: nil)
                   }
                   completion(.failure(NetworkError.unauthorized))
                   return
               }
               if let error = error {
                   completion(.failure(error))
                   return
               }
               guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                   completion(.failure(NetworkError.noResponse))
                   return
               }
               
               guard (200...299).contains(httpResponse.statusCode) else {
                   completion(.failure(NetworkError.badResponse(httpResponse.statusCode)))
                   return
               }
               
               do {
                   let decodedData = try JSONDecoder().decode(T.self, from: data)
                   completion(.success(decodedData))
               } catch {
                   completion(.failure(NetworkError.decodingError))
               }
           }.resume()
       }
    
    // MARK: - Public Methods
    func get<T: Decodable>(
        endpoint: String,
        requiresAuth: Bool = false,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        makeRequest(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: requiresAuth,
            completion: completion
        )
    }
    
    func post<T: Decodable>(endpoint: String, parameters: [String: Any], requiresAuth: Bool = false, completion: @escaping (Result<T, Error>) -> Void) {
            makeRequest(endpoint: endpoint, method: "POST", parameters: parameters, requiresAuth: requiresAuth, completion: completion)
        }
    
    func put<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        requiresAuth: Bool = false,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        makeRequest(
            endpoint: endpoint,
            method: "PUT",
            parameters: parameters,
            requiresAuth: requiresAuth,
            completion: completion
        )
    }
    
    func delete(
        endpoint: String,
        requiresAuth: Bool = false,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        makeRequest(
            endpoint: endpoint,
            method: "DELETE",
            requiresAuth: requiresAuth
        ) { (_: Result<EmptyResponse, Error>) in
            completion(.success(()))
        }
    }
    
    // MARK: - Helper Types
    private struct EmptyResponse: Decodable {}
}

// MARK: - API Response Structure
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

// MARK: - Network Error Types
enum NetworkError: LocalizedError {
    case invalidURL
    case noResponse
    case noData
    case invalidParameters
    case decodingError
    case badResponse(Int)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .noResponse: return "Sunucudan yanıt alınamadı"
        case .noData: return "Veri alınamadı"
        case .invalidParameters: return "Geçersiz parametreler"
        case .decodingError: return "Veri çözümlenemedi"
        case .badResponse(let code): return "Sunucu hatası (Kod: \(code))"
        case .unauthorized: return "Oturum süresi doldu. Lütfen tekrar giriş yapın"
        }
    }
}
