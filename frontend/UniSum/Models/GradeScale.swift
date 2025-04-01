struct GradeScale: Identifiable, Codable, Equatable {
    // MARK: - Properties
    let id: Int
    let course_id: Int
    let letter: String
    var min_score: Int
    var gpa: Double
    var is_custom: Bool
    
    // MARK: - Static Properties
    static let defaultGradeDefinitions: [(letter: String, minScore: Int, gpa: Double)] = [
        ("AA", 90, 4.00),
        ("BA", 85, 3.50),
        ("BB", 75, 3.00),
        ("CB", 65, 2.50),
        ("CC", 60, 2.00),
        ("DC", 50, 1.50),
        ("DD", 45, 1.00),
        ("FD", 40, 0.50),
        ("FF", 0, 0.00)
    ]
    
    
    
    // MARK: - Computed Properties
    var courseId: Int { course_id }
    var minScore: Int {
        get { min_score }
        set { min_score = newValue }
    }
    
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id
        case course_id
        case letter
        case min_score
        case gpa
        case is_custom
    }
    
    // MARK: - Initializers
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        course_id = try container.decode(Int.self, forKey: .course_id)
        letter = try container.decode(String.self, forKey: .letter)
        min_score = try container.decode(Int.self, forKey: .min_score)
        gpa = try container.decode(Double.self, forKey: .gpa)
        is_custom = try container.decodeIfPresent(Bool.self, forKey: .is_custom) ?? false
    }
    
    init(id: Int = 0, courseId: Int, letter: String, minScore: Int, gpa: Double, isCustom: Bool = false) {
        self.id = id
        self.course_id = courseId
        self.letter = letter
        self.min_score = minScore
        self.gpa = gpa
        self.is_custom = isCustom
    }
}

// MARK: - Static Methods
extension GradeScale {
    static func getDefaultScales(for courseId: Int) -> [GradeScale] {
        return defaultGradeDefinitions.enumerated().map { index, definition in
            GradeScale(
                id: -(index + 1), // Negatif ID'ler kullanarak benzersiz ID'ler oluştur
                courseId: courseId,
                letter: definition.letter,
                minScore: definition.minScore,
                gpa: definition.gpa,
                isCustom: false
            )
        }
    }
    
    static func calculateGrade(scales: [GradeScale], average: Double) -> GradeScale? {
        return scales
            .sorted { $0.minScore > $1.minScore }
            .first { Double($0.minScore) <= average }
    }
}

// MARK: - Instance Methods
extension GradeScale {
    func isDifferentFromDefault() -> Bool {
        guard let defaultDefinition = Self.defaultGradeDefinitions.first(where: { $0.letter == self.letter }) else {
            return true
        }
        
        let isMinScoreDifferent = self.minScore != defaultDefinition.minScore
        let isGpaDifferent = abs(self.gpa - defaultDefinition.gpa) > 0.001 // Double karşılaştırması için hassasiyet
        
        return isMinScoreDifferent || isGpaDifferent
    }
}

// MARK: - Array Extensions
extension Array where Element == GradeScale {
    func getModifiedScales() -> [GradeScale] {
        self.filter { $0.isDifferentFromDefault() }
    }
}
