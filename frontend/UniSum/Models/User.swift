import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let university: String
    let department: String
    let verified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, university, department, verified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        university = try container.decode(String.self, forKey: .university)
        department = try container.decode(String.self, forKey: .department)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? true
    }
}
