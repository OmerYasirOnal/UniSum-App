import Foundation
import Combine

// MARK: - Response Models
struct TermGPAResponse: Codable {
    let gpa: Double
    let totalCredits: Double
    let courseDetails: [CourseGPADetail]? // ✅ Opsiyonel hale getirdik
}

struct CourseGPADetail: Codable {
    let courseId: Int
    let credits: Double
    let average: Double
    let gpa: Double
}
struct CourseGPAResponse: Codable {
    let courseId: Int
    let gpa: Double
    let letterGrade: String
}


class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    // Term GPA hesaplamaları artık backendden gelecek
    @Published var termGPA: Double = 0.0
    @Published var totalCredits: Double = 0.0
    @Published var isLoadingGPA = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Fetch Courses
    func fetchCourses(for termId: Int) {
        isLoading = true
        
        networkManager.get(
            endpoint: "/terms/\(termId)/courses",
            requiresAuth: true
        ) { [weak self] (result: Result<[Course], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let courses):
                    self?.courses = courses
                    self?.fetchTermGPA(for: termId)

                    // ✅ Dersler geldikten sonra tek tek GPA güncelle
                    for course in courses {
                        self?.updateGPA(for: course.id)
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateGPA(for courseId: Int) {
        networkManager.put(
            endpoint: "/courses/\(courseId)/updateGPA",
            parameters: [:],
            requiresAuth: true
        ) { [weak self] (result: Result<CourseGPAResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedCourse):
                    if let index = self?.courses.firstIndex(where: { $0.id == updatedCourse.courseId }) {
                        self?.courses[index].gpa = updatedCourse.gpa
                        self?.courses[index].letterGrade = updatedCourse.letterGrade
                    }
                case .failure(let error):
                    print("❌ GPA güncellenirken hata oluştu: \(error.localizedDescription)")
                }
            }
        }
    }

    
    
    // ✅ Term GPA artık backendden çekilecek
    func fetchTermGPA(for termId: Int) {
        isLoadingGPA = true
        
        networkManager.put(
            endpoint: "/terms/\(termId)/updateGPA",  parameters: [:], // ✅ Boş parametre gönderildi
            requiresAuth: true
        ) { [weak self] (result: Result<TermGPAResponse, Error>) in
            DispatchQueue.main.async {
                self?.isLoadingGPA = false
                
                switch result {
                case .success(let response):
                    self?.termGPA = response.gpa
                    self?.totalCredits = response.totalCredits
                    let courseDetails = response.courseDetails ?? []
                        print("📊 Ders detayları: \(courseDetails)")
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // ✅ Ders eklendiğinde hem ders listesini hem de dönem GPA'yı güncelle
    func addCourse(termId: Int, userId: Int, name: String, credits: Double, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "term_id": termId,
            "user_id": userId,
            "name": name,
            "credits": credits
        ]
        
        networkManager.post(
            endpoint: "/terms/\(termId)/courses",
            parameters: parameters,
            requiresAuth: true
        ) { [weak self] (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let newCourse):
                    self?.courses.append(newCourse)
                    self?.fetchTermGPA(for: termId) // ✅ Yeni ders eklendiği için dönem GPA'yı güncelle
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    func deleteCourse(courseId: Int, completion: @escaping (Bool) -> Void) {
            networkManager.delete(
                endpoint: "/courses/\(courseId)",
                requiresAuth: true
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.courses.removeAll { $0.id == courseId }
                        // Fetch updated GPA after deleting a course
                        if let termId = self?.courses.first?.termId {
                            self?.fetchTermGPA(for: termId)
                        }
                        self?.errorMessage = ""
                        completion(true)
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            }
        }
}
