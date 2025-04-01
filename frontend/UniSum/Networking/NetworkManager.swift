import Foundation
import Network

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    let baseURL: String
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var isApiAccessible = true
    @Published var showConnectionAlert = false
    @Published var connectionErrorType: ConnectionErrorType = .noConnection
    
    // Zaman aşımı süresi
    private let requestTimeout: TimeInterval = 15.0
    
    private init() {
        guard let secretsURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: secretsURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let secretsDict = plist as? [String: Any],
              let url = secretsDict["BaseURL"] as? String else {
            fatalError("BaseURL Secrets.plist içinde bulunamadı veya format yanlış!")
        }
        self.baseURL = url
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.status != .satisfied {
                    self?.isApiAccessible = false
                    self?.connectionErrorType = .noConnection
                    self?.showConnectionAlert = true
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func checkApiAccessibility() {
        // Bu metodu kullanmayı bırakıyoruz çünkü yanlış alarmlar veriyor
        // İlerde gerçekten sunucu durumunu kontrol etmemiz gerekirse
        // daha güvenilir bir yöntem kullanacağız
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
           // Zaman aşımı süresini ayarla
           request.timeoutInterval = requestTimeout
           
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
               if let nsError = error as NSError? {
                   if nsError.domain == NSURLErrorDomain {
                       switch nsError.code {
                       case -1009: // No internet connection
                           DispatchQueue.main.async {
                               self.isApiAccessible = false
                               self.connectionErrorType = .noConnection
                               self.showConnectionAlert = true
                           }
                           completion(.failure(NetworkError.noConnection))
                           return
                           
                       case -1001: // Request timeout
                           DispatchQueue.main.async {
                               self.isApiAccessible = false
                               self.connectionErrorType = .timeout
                               self.showConnectionAlert = true
                           }
                           completion(.failure(NetworkError.timeout))
                           return
                           
                       default:
                           break
                       }
                   }
                   
                   completion(.failure(nsError))
                   return
               }
               
               guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                   completion(.failure(NetworkError.noResponse))
                   return
               }
               
               if httpResponse.statusCode == 401 {
                   DispatchQueue.main.async {
                       NotificationCenter.default.post(name: Notification.Name("TokenExpired"), object: nil)
                   }
                   completion(.failure(NetworkError.unauthorized))
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
    
    // Bu metodu public yaparak hatayı manuel olarak kapatabilmemizi sağlar
    func dismissConnectionAlert() {
        DispatchQueue.main.async {
            self.showConnectionAlert = false
        }
    }
}

// MARK: - Connection Error Types
enum ConnectionErrorType {
    case noConnection   // İnternet bağlantısı yok
    case filtered       // Bağlantı engellenmiş (FortiGuard vb.)
    case serverError    // Sunucu hatası 
    case other          // Diğer hatalar
    case timeout        // Zaman aşımı
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
    case noConnection
    case invalidResponse
    case serverError(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return NSLocalizedString("error_invalid_url", comment: "")
        case .noResponse: return NSLocalizedString("error_no_response", comment: "")
        case .noData: return NSLocalizedString("error_no_data", comment: "")
        case .invalidParameters: return NSLocalizedString("error_invalid_parameters", comment: "")
        case .decodingError: return NSLocalizedString("error_decoding_error", comment: "")
        case .badResponse(let code): return String(format: NSLocalizedString("error_bad_response", comment: ""), code)
        case .unauthorized: return NSLocalizedString("error_unauthorized", comment: "")
        case .noConnection: return NSLocalizedString("error_no_connection", comment: "")
        case .invalidResponse: return NSLocalizedString("error_invalid_response", comment: "")
        case .serverError(let message): return String(format: NSLocalizedString("error_server_error", comment: ""), message)
        case .timeout: return NSLocalizedString("error_timeout", comment: "")
        }
    }
}

struct ErrorResponse: Codable {
    let message: String
}
