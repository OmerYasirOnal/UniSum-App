import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let university: String
    let department: String
}
