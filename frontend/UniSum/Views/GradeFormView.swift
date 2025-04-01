import SwiftUI

struct GradeFormView: View {
    // MARK: - Properties
    let title: String
    let courseId: Int
    let grade: Grade?
    @ObservedObject var viewModel: GradeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var gradeType: String
    @State private var selectedGradeType: GradeType = .custom
    @State private var score: Double
    @State private var weight: Double
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isScorePickerVisible = false
    @State private var isWeightPickerVisible = false

    // MARK: - Grade Types
    private enum GradeType: String, CaseIterable {
        case midterm = "grade_type_midterm"
        case final = "grade_type_final"
        case quiz1 = "grade_type_quiz1"
        case quiz2 = "grade_type_quiz2"
        case project = "grade_type_project"
        case homework = "grade_type_homework"
        case presentation = "grade_type_presentation"
        case custom = "grade_type_custom"

        var localizedName: LocalizedStringKey {
            LocalizedStringKey(self.rawValue)
        }
    }

    // MARK: - Initialization
    init(title: String, courseId: Int, grade: Grade? = nil, viewModel: GradeViewModel) {
        self.title = title
        self.courseId = courseId
        self.grade = grade
        self.viewModel = viewModel

        let initialGradeType = grade?.gradeType ?? ""
        _gradeType = State(initialValue: initialGradeType)
        _selectedGradeType = State(initialValue: GradeType.allCases.first { $0.rawValue == initialGradeType } ?? .custom)
        _score = State(initialValue: grade?.score ?? 50.0)
        _weight = State(initialValue: grade?.weight ?? 1.0)
    }
    
    // MARK: - Computed Properties
    private var remainingWeight: Double {
        if let grade = grade {
            let currentTotal = viewModel.totalWeight(forCourse: courseId, excluding: grade.id)
            return 100 - currentTotal
        } else {
            let currentTotal = viewModel.totalWeight(forCourse: courseId)
            return 100 - currentTotal
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                gradeTypeSection
                scoreAndWeightSection
            }
            .navigationTitle(LocalizedStringKey(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(LocalizedStringKey("alert_warning"), isPresented: $showAlert) {
                Button(LocalizedStringKey("alert_ok"), role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(alertMessage))
            }
            .sheet(isPresented: $isScorePickerVisible) {
                ScorePickerView(score: $score)
            }
            .sheet(isPresented: $isWeightPickerVisible) {
                WeightPickerView(
                    weight: $weight,
                    remainingWeight: remainingWeight,
                    currentGradeWeight: grade?.weight ?? 0
                )
            }
        }
    }
    
    // MARK: - Section Views
    private var gradeTypeSection: some View {
        Section(header: Text(LocalizedStringKey("section_grade_type"))) {
            Picker(LocalizedStringKey("picker_select_type"), selection: $selectedGradeType) {
                ForEach(GradeType.allCases, id: \.self) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .onChange(of: selectedGradeType) { newValue in
                if newValue != .custom {
                    gradeType = newValue.rawValue
                }
            }
            
            if selectedGradeType == .custom {
                TextField(LocalizedStringKey("textfield_enter_custom_type"), text: $gradeType)
                    .textInputAutocapitalization(.words)
            }
        }
    }
    
    private var scoreAndWeightSection: some View {
        Section(header: Text(LocalizedStringKey("section_score_and_weight"))) {
            VStack(alignment: .leading, spacing: 8) {
                // Score Slider
                HStack {
                    Text("\(NSLocalizedString("label_score", comment: "")): \(Int(score))")
                    Spacer()
                }
                Slider(value: $score, in: 0...100, step: 1)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                // Weight Slider: kullanıcı 0 seçemeyecek, aralık 1'den başlayacak.
                HStack {
                    Text("\(NSLocalizedString("label_weight", comment: "")): \(Int(weight))% / \(NSLocalizedString("label_available", comment: "")): \(Int(remainingWeight))%")
                    Spacer()
                }
                if remainingWeight >= 1 {
                    Slider(value: $weight, in: 1...remainingWeight, step: 1)
                } else {
                    Slider(value: .constant(0), in: 0...1, step: 1)
                        .disabled(true)
                        .opacity(0.5)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("cancel")) { dismiss() }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("save")) { validateAndSave() }
                    .disabled(!isFormValid())
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isFormValid() -> Bool {
        !gradeType.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func validateAndSave() {
        let totalAfterChange = viewModel.totalWeight(forCourse: courseId, excluding: grade?.id) + weight
        
        if totalAfterChange > 100 {
            alertMessage = "alert_total_weight_exceeded \(Int(remainingWeight))"
            showAlert = true
            return
        }
        
        if let existingGrade = grade {
            updateExistingGrade(existingGrade)
        } else {
            addNewGrade()
        }
    }
    
    private func updateExistingGrade(_ existingGrade: Grade) {
        viewModel.updateGrade(
            gradeId: existingGrade.id,
            courseId: courseId,
            gradeType: gradeType,
            score: score,
            weight: weight
        ) { result in
            handleResult(result)
        }
    }
    
    private func addNewGrade() {
        viewModel.addGrade(
            courseId: courseId,
            gradeType: gradeType,
            score: score,
            weight: weight
        ) { result in
            handleResult(result)
        }
    }
    
    private func handleResult(_ result: Result<Grade, Error>) {
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Supporting Views
struct ScorePickerView: View {
    @Binding var score: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker(LocalizedStringKey("picker_score"), selection: $score) {
                        ForEach(0...100, id: \.self) { value in
                            Text("\(value)").tag(Double(value))
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle(LocalizedStringKey("nav_select_score"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("done")) { dismiss() }
                }
            }
        }
    }
}

struct WeightPickerView: View {
    @Binding var weight: Double
    let remainingWeight: Double
    let currentGradeWeight: Double
    @Environment(\.dismiss) var dismiss
    
    private var maxAllowedWeight: Double {
        remainingWeight + currentGradeWeight
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker(LocalizedStringKey("picker_weight"), selection: $weight) {
                        ForEach(0...Int(min(100, maxAllowedWeight)), id: \.self) { value in
                            Text("\(value)%").tag(Double(value))
                        }
                    }
                    .pickerStyle(.wheel)
                } footer: {
                    Text("\(NSLocalizedString("label_available_weight", comment: "")): \(Int(remainingWeight))%")
                }
            }
            .navigationTitle(LocalizedStringKey("nav_select_weight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("done")) { dismiss() }
                }
            }
        }
    }
}
