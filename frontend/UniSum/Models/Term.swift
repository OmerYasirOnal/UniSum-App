struct Term: Identifiable, Codable, Hashable {
    let id: Int
    let user_id: Int
    let class_level: String
    let term_number: Int
    let createdAt: String?
    let updatedAt: String?
    var courses: [Course]? // Terim içindeki dersler
    
    // Swift tarafında kullanım için computed property'ler
    var userId: Int { user_id }
    var classLevel: String { class_level }
    var termNumber: Int { term_number }
    
    // Toplam kredi miktarı
    var totalCredits: String {
        // Eğer courses varsa, toplam kredi miktarını hesapla
        if let courses = courses, !courses.isEmpty {
            let total = courses.reduce(0.0) { $0 + $1.credits }
            return String(format: "%.1f", total)
        }
        
        // Kurslar yoksa varsayılan değer
        return "0"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case class_level
        case term_number
        case createdAt
        case updatedAt
        case courses
    }
    
    // Hashable gereksinimleri için
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Term, rhs: Term) -> Bool {
        return lhs.id == rhs.id
    }
    
    // İçeriği yazdırarak debug etmek için
    func description() -> String {
        return "Term(id: \(id), userId: \(user_id), classLevel: \(class_level), termNumber: \(term_number))"
    }
}
