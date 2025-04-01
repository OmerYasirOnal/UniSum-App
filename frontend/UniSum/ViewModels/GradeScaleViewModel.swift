import SwiftUI

class GradeScaleViewModel: ObservableObject {
    @Published var course: Course
    @Published var gradeScales: [GradeScale] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentGrade: String = "N/A"
    @Published var currentGPA: Double = 0.0
    
    private let networkManager = NetworkManager.shared
    
    init(course: Course) {
        self.course = course
        loadInitialData()
    }
    
    // 1) Default + Custom
    func loadInitialData() {
        self.gradeScales = GradeScale.getDefaultScales(for: course.id)
        fetchCustomScales()
    }
    
    private func fetchCustomScales() {
        isLoading = true
        networkManager.get(
            endpoint: "/grade-scales/courses/\(course.id)",
            requiresAuth: true
        ) { [weak self] (result: Result<[GradeScale], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let customScales):
                    self?.updateWithCustomScales(customScales)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateWithCustomScales(_ customScales: [GradeScale]) {
        let defaults = GradeScale.getDefaultScales(for: course.id)
        var merged: [GradeScale] = []
        
        for def in defaults {
            if let override = customScales.first(where: { $0.letter == def.letter }) {
                merged.append(override)
            } else {
                merged.append(def)
            }
        }
        self.gradeScales = merged
    }
    
    // 2) Kaydetme + GPA güncellemede completion
    func saveGradeScales(completion: @escaping (Bool)->Void = { _ in }) {
        let modifiedScales = gradeScales.filter { $0.isDifferentFromDefault() }
        let scalesToSave = modifiedScales.map { scale -> [String: Any] in
            [
                "letter": scale.letter,
                "min_score": scale.minScore,
                "gpa": scale.gpa,
                "is_custom": true
            ]
        }
        
        networkManager.post(
            endpoint: "/grade-scales/courses/\(course.id)",
            parameters: ["gradeScales": scalesToSave],
            requiresAuth: true
        ) { [weak self] (result: Result<[GradeScale], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 2a) yeniden load
                    self?.loadInitialData()
                    // 2b) sonra GPA hesapla
                    self?.updateCourseGPA { success in
                        completion(success)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // 3) updateCourseGPA de completion
    private func updateCourseGPA(completion: @escaping (Bool) -> Void) {
            networkManager.put(
                endpoint: "/courses/\(course.id)/updateGPA",
                parameters: [:],
                requiresAuth: true
            ) { [weak self] (result: Result<CourseGPAResponse, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self?.course.gpa = response.gpa
                        self?.course.letterGrade = response.letterGrade

                        // ✅ Burada local currentGrade / currentGPA de güncelleniyor:
                        self?.currentGrade = response.letterGrade
                        self?.currentGPA = response.gpa

                        completion(true)

                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            }
        }
    
    // Eski “calculateCurrentGrade” fonksiyonu
    func calculateCurrentGrade(average: Double?) {
        guard let avg = average else {
            currentGrade = "N/A"
            currentGPA = 0.0
            return
        }
        let sortedScales = gradeScales.sorted { $0.minScore > $1.minScore }
        
        if let gradeScale = sortedScales.first(where: { Double($0.minScore) <= avg }) {
            currentGrade = gradeScale.letter
            currentGPA = gradeScale.gpa
        } else if let lowestGrade = sortedScales.last {
            currentGrade = lowestGrade.letter
            currentGPA = lowestGrade.gpa
        } else {
            currentGrade = "N/A"
            currentGPA = 0.0
        }
    }
}

