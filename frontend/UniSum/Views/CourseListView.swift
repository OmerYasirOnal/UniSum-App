import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel = CourseViewModel()
    let term: Term
    @State private var selectedCourse: Course? = nil
    @State private var isAddCourseViewVisible = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            mainContent
            
            if isAddCourseViewVisible {
                AddCourseView(
                    isPresented: $isAddCourseViewVisible,
                    selectedCourse: $selectedCourse,
                    courseViewModel: viewModel,
                    termId: term.id,
                    userId: term.userId
                )
                .transition(.scale)
            }
        }
        .navigationTitle(LocalizedStringKey("courses"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchCourses(for: term.id)
        }
        .onChange(of: selectedCourse) { course in
            if let course = course {
                let destination = CourseDetailView(course: course)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    if let navigationController = rootViewController.findNavigationController() {
                        DispatchQueue.main.async {
                            navigationController.pushViewController(UIHostingController(rootView: destination), animated: true)
                            selectedCourse = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.errorMessage.isEmpty {
                errorView
            } else if viewModel.courses.isEmpty {
                emptyStateView
            } else {
                courseList
            }
            
            Spacer()
            
            // Her durumda gösterilecek kısım
            VStack(spacing: 0) {
                termAverageSection
                addButton
                    .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Term GPA Section (Değişmedi)
    private var termAverageSection: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingGPA {
                ProgressView()
                    .padding()
            } else {
                HStack(spacing: 20) {
                    VStack(alignment: .center, spacing: 4) {
                        Text(LocalizedStringKey("term_average"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", viewModel.termGPA))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 3)
                    )
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(LocalizedStringKey("total_credits"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", viewModel.totalCredits))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 3)
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Ders Listesi
    private var courseList: some View {
        List {
            ForEach(viewModel.courses) { course in
                courseRow(course: course)
            }
            .onDelete { indexSet in
                handleDelete(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // ✅ Güncellenmiş Ders Satırı
    private func courseRow(course: Course) -> some View {
        NavigationLink(destination: CourseDetailView(course: course)) {
            HStack {
                // SOL KISIM (Ders Adı, Kredi)
                VStack(alignment: .leading, spacing: 4) {
                    // Ders adı
                    Text(course.name)
                        .font(.headline)
                    
                    // Kredi bilgisi
                    HStack {
                        Text(LocalizedStringKey("credit")) // "Kredi"
                        Text(String(format: "%.1f", course.credits))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // SAĞ KISIM (Ortalama + Harf Notu/GPA üst üste)
                VStack(alignment: .trailing, spacing: 4) {
                    
                    // 1) Ortalama (Average)
                    HStack {
                        Text(LocalizedStringKey("average")) // "Ortalama"
                        Text(String(format: "%.1f", course.average))
                            .bold()
                    }
                    .font(.subheadline)
                    
                    // 2) Harf Notu + GPA
                    //    - letterGrade ve gpa doluysa göster, aksi halde gizle
                    // 2) Harf Notu + GPA
                    if let letter = course.letterGrade {
                        let gpaValue = course.gpa ?? 0.0
                        HStack {
                            Text("\(letter)/\(String(format: "%.2f", gpaValue))")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 8)
            
        }
    }
    
    private var errorView: some View {
        VStack {
            Text("Error")
                .font(.headline)
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .foregroundColor(.red)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Henüz ders eklenmemiş")
                .font(.headline)
                .foregroundColor(.gray)
        }.padding(5)
    }
    
    private var addButton: some View {
        Button(action: { isAddCourseViewVisible = true }) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
        }
        .padding(.bottom, 30)
    }
    
    
    
    // MARK: - Ders Silme
    private func handleDelete(at indexSet: IndexSet) {
        for index in indexSet {
            let course = viewModel.courses[index]
            viewModel.deleteCourse(courseId: course.id) { success in
                if success {
                    viewModel.fetchTermGPA(for: term.id) // ✅ Ders silindiğinde term GPA'yı güncelle
                }
            }
        }
    }
}

extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        return nil
    }
}
