struct Grade: Identifiable, Codable, Equatable { // ✅ Equatable eklendi
    let id: Int
    let courseId: Int
    let gradeType: String
    let score: Double
    let weight: Double
    let createdAt: String
    let updatedAt: String
    
    // Equatable protokolü için gerekli static func
    static func == (lhs: Grade, rhs: Grade) -> Bool {
        return lhs.id == rhs.id &&
        lhs.courseId == rhs.courseId &&
        lhs.gradeType == rhs.gradeType &&
        lhs.score == rhs.score &&
        lhs.weight == rhs.weight &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case gradeType = "grade_type"
        case score
        case weight
        case createdAt
        case updatedAt
    }
}
