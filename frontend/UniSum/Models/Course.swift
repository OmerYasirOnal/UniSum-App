import Foundation

struct Course: Identifiable, Codable, Equatable {
    let id: Int
    let termId: Int
    let userId: Int
    let name: String
    let credits: Double
    var average: Double
    var letterGrade: String?
    var gpa: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case termId = "term_id"
        case userId = "user_id"
        case name
        case credits
        case average
        case letterGrade = "letter_grade"
        case gpa
    }
    
    // Sadece id'ye göre karşılaştırma
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id
    }
}
