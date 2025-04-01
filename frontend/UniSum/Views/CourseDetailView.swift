import SwiftUI

struct CourseDetailView: View {
    // MARK: - Properties
    let course: Course
    @StateObject var gradeViewModel = GradeViewModel()
    @StateObject private var gradeScaleViewModel: GradeScaleViewModel
    @State private var currentAverage: Double
    @State private var activeSheet: ActiveSheet?
    @State private var showingDeleteConfirmation = false
    @State private var gradeToDelete: Grade?
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Sheet Type Enum
    private enum ActiveSheet: Identifiable {
        case addGrade
        case editGrade(Grade)
        case gradeScaleEditor
        
        var id: Int {
            switch self {
            case .addGrade: return 0
            case .editGrade: return 1
            case .gradeScaleEditor: return 2
            }
        }
    }
    
    init(course: Course) {
        self.course = course
        self._currentAverage = State(initialValue: course.average)
        _gradeScaleViewModel = StateObject(wrappedValue: GradeScaleViewModel(course: course))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            if gradeScaleViewModel.isLoading {
                loadingView
            } else {
                courseDetailsSection
                gradesSection
                gradeScaleSummaryView
            }
        }
        .navigationTitle(course.name)
        .onAppear { setupView() }
        .onChange(of: gradeViewModel.grades) { _ in updateAverageAndGrade() }
        .alert(LocalizedStringKey("delete_grade"), isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStringKey("delete"), role: .destructive) {
                if let grade = gradeToDelete {
                    deleteGrade(grade)
                }
            }
            Button(LocalizedStringKey("cancel"), role: .cancel) {
                gradeToDelete = nil
            }
        } message: {
            Text(LocalizedStringKey("delete_confirmation"))
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addGrade:
                GradeFormView(
                    title: NSLocalizedString("add_grade", comment: ""),
                    courseId: course.id,
                    viewModel: gradeViewModel
                )
            case .editGrade(let grade):
                GradeFormView(
                    title: NSLocalizedString("edit_grade", comment: ""),
                    courseId: course.id,
                    grade: grade,
                    viewModel: gradeViewModel
                )
            case .gradeScaleEditor:
                GradeScaleEditorView(viewModel: gradeScaleViewModel)
            }
        }
    }
    
    // MARK: - Content Views
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView(LocalizedStringKey("loading"))
                .progressViewStyle(.circular)
                .padding()
            Spacer()
        }
    }
    
    private var courseDetailsSection: some View {
        Section(LocalizedStringKey("course_details")) {
            DetailRow(title: LocalizedStringKey("course_name"), value: course.name)
            DetailRow(title: LocalizedStringKey("credits"), value: String(format: "%.2f", course.credits))
            DetailRow(title: LocalizedStringKey("average"), value: String(format: "%.2f", currentAverage))
        }
    }
    
    private var gradesSection: some View {
        Section {
            if gradeViewModel.grades.isEmpty {
                emptyGradesView
            } else {
                gradesListView
            }
        } header: {
            HStack {
                Text(LocalizedStringKey("grades"))
                Spacer()
                Text(String(
                    format: NSLocalizedString("remaining_weight", comment: ""),
                    Int(gradeViewModel.remainingWeight(forCourse: course.id))
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
                Button {
                    activeSheet = .addGrade
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(gradeViewModel.remainingWeight(forCourse: course.id) == 0)
            }
        }
    }
    
    private var emptyGradesView: some View {
        Text(LocalizedStringKey("no_grades_yet"))
            .foregroundColor(.secondary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
    }
    
    private var gradesListView: some View {
        ForEach(gradeViewModel.grades) { grade in
            gradeRowView(grade: grade)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        gradeToDelete = grade
                        showingDeleteConfirmation = true
                    } label: {
                        Label(LocalizedStringKey("delete"), systemImage: "trash")
                    }
                    
                    Button {
                        activeSheet = .editGrade(grade)
                    } label: {
                        Label(LocalizedStringKey("edit"), systemImage: "pencil")
                    }
                    .tint(.blue)
                }
        }
    }
    
    private var gradeScaleSummaryView: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("current_grade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        // ✅ Doğrudan GradeScaleViewModel’dan gelen currentGrade
                        Text(gradeScaleViewModel.currentGrade)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("semester_gpa")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", gradeScaleViewModel.currentGPA))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                Button {
                    activeSheet = .gradeScaleEditor
                } label: {
                    HStack {
                        Image(systemName: "ruler")
                        Text("view_grade_scale")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func gradeRowView(grade: Grade) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(grade.gradeType))
                    .font(.headline)

                HStack {
                    Text("\(grade.score, specifier: "%.1f")")
                        .foregroundColor(.primary)
                    Text("(\(grade.weight, specifier: "%.1f")%)")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Helper Methods
    private func setupView() {
        gradeViewModel.fetchGrades(forCourse: course.id)
        gradeScaleViewModel.loadInitialData()
    }
    
    private func updateAverageAndGrade() {
        let newAverage = gradeViewModel.calculateAverage()
        currentAverage = newAverage
        gradeViewModel.updateCourseAverage(courseId: course.id)
        gradeScaleViewModel.calculateCurrentGrade(average: newAverage)
    }
    
    private func deleteGrade(_ grade: Grade) {
        withAnimation {
            gradeViewModel.deleteGrade(gradeId: grade.id, courseId: course.id)
        }
        gradeToDelete = nil
    }
}

// MARK: - Helper Views
struct DetailRow: View {
    let title: LocalizedStringKey
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
