import SwiftUI
import Combine
import Foundation

class GradeViewModel: ObservableObject {
    // MARK: - Properties
    @Published var grades: [Grade] = []
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    func totalWeight(forCourse courseId: Int, excluding gradeId: Int? = nil) -> Double {
        grades
            .filter { grade in
                if let excludeId = gradeId {
                    return grade.courseId == courseId && grade.id != excludeId
                }
                return grade.courseId == courseId
            }
            .reduce(0.0) { $0 + $1.weight }
    }
    
    func remainingWeight(forCourse courseId: Int, excludingGradeId: Int? = nil) -> Double {
        let used = totalWeight(forCourse: courseId, excluding: excludingGradeId)
        return max(0, 100.0 - used)
    }
    
    func maxAllowedWeight(forCourse courseId: Int, currentGradeId: Int) -> Double {
        let currentGrade = grades.first { $0.id == currentGradeId }
        let currentWeight = currentGrade?.weight ?? 0.0
        let remaining = remainingWeight(forCourse: courseId, excludingGradeId: currentGradeId)
        let maxWeight = remaining + currentWeight
        
        return min(100, maxWeight)
    }
    
    func fetchGrades(forCourse courseId: Int) {
        networkManager.get(endpoint: "/grades/courses/\(courseId)", requiresAuth: true) { (result: Result<[Grade], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedGrades):
                    self.grades = fetchedGrades
                    self.objectWillChange.send()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addGrade(courseId: Int, gradeType: String, score: Double, weight: Double, completion: @escaping (Result<Grade, Error>) -> Void) {
        let parameters: [String: Any] = [
            "course_id": courseId,
            "grade_type": gradeType,
            "score": score,
            "weight": weight
        ]
        
        networkManager.post(endpoint: "/grades", parameters: parameters, requiresAuth: true) { (result: Result<Grade, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let newGrade):
                    self.grades.append(newGrade)
                    self.fetchGrades(forCourse: courseId)
                    completion(.success(newGrade))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func calculateAverage() -> Double {
        guard !grades.isEmpty else { return 0.0 }
        
        let totalWeightedScore = grades.reduce(0.0) { $0 + ($1.score * ($1.weight / 100.0)) }
        return totalWeightedScore
    }
    
    func updateCourseAverage(courseId: Int) {
        let average = calculateAverage()
        let parameters: [String: Any] = ["average": average]
        
        networkManager.put(
            endpoint: "/courses/\(courseId)/average",
            parameters: parameters,
            requiresAuth: true
        ) { (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    NotificationCenter.default.post(
                        name: Notification.Name("CourseAverageUpdated"),
                        object: nil,
                        userInfo: ["courseId": courseId, "average": average]
                    )
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteGrade(gradeId: Int, courseId: Int) {
        grades.removeAll { $0.id == gradeId }
        
        networkManager.delete(
            endpoint: "/grades/\(gradeId)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let average = self?.calculateAverage() {
                        self?.updateCourseAverage(courseId: courseId)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.fetchGrades(forCourse: courseId)
                }
            }
        }
    }
    
    func updateGrade(
        gradeId: Int,
        courseId: Int,
        gradeType: String,
        score: Double,
        weight: Double,
        completion: @escaping (Result<Grade, Error>) -> Void
    ) {
        let parameters: [String: Any] = [
            "grade_type": gradeType,
            "score": score,
            "weight": weight
        ]
        
        networkManager.put(
            endpoint: "/grades/\(gradeId)",
            parameters: parameters,
            requiresAuth: true
        ) { [weak self] (result: Result<Grade, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedGrade):
                    if let index = self?.grades.firstIndex(where: { $0.id == gradeId }) {
                        self?.grades[index] = updatedGrade
                    }
                    if let average = self?.calculateAverage() {
                        self?.updateCourseAverage(courseId: courseId)
                    }
                    completion(.success(updatedGrade))
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func validateWeight(forCourse courseId: Int, newWeight: Double, excludingGradeId: Int? = nil) -> Bool {
        let currentTotalWeight = grades
            .filter { $0.courseId == courseId && $0.id != excludingGradeId }
            .reduce(0.0) { $0 + $1.weight }
        
        return (currentTotalWeight + newWeight) <= 100.0
    }
    
    private func debouncedUpdateCourseAverage(courseId: Int) {
        Just(())
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCourseAverage(courseId: courseId)
            }
            .store(in: &cancellables)
    }
}
