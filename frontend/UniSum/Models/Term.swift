struct Term: Identifiable, Codable {
    let id: Int
    let user_id: Int
    let class_level: String
    let term_number: Int
    
    // Swift tarafında kullanım için computed property'ler
    var userId: Int { user_id }
    var classLevel: String { class_level }
    var termNumber: Int { term_number }
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case class_level
        case term_number
    }
}
