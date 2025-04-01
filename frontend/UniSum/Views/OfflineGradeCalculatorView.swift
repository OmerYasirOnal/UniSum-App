import SwiftUI

// Standart sayfa başlığı view'ı, info butonunu da içerir.
struct StandardPageHeader: View {
    var title: LocalizedStringKey
    var infoAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            if let infoAction = infoAction {
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

struct OfflineGradeCalculatorView: View {
    @State private var grades: [Grade] = []
    @State private var courseName: String = ""
    @State private var average: Double = 0.0
    @State private var letterGrade: String = "N/A"
    @State private var showingInfo: Bool = false
    @State private var showingGradeForm: Bool = false
    @State private var showUserNotification: Bool = true  // Offline mod bildirimi
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Üst başlık: Sabit, header içinde courseName alanı ve info butonu
                    StandardPageHeader(title: LocalizedStringKey("offline_grade_calculator"), infoAction: {
                        withAnimation { showingInfo = true }
                    })
                    
                    Divider()
                    
                    // İçerik: Scrollable alan
                    ScrollView {
                        VStack(spacing: 16) {
                            if showUserNotification {
                                userNotificationBanner
                            }
                            
                            if grades.isEmpty {
                                Text(LocalizedStringKey("no_grades_yet"))
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(grades) { grade in
                                        VStack {
                                            HStack {
                                                Text(LocalizedStringKey(grade.gradeType))
                                                Spacer()
                                                Text(String(format: NSLocalizedString("weight_format", comment: ""), grade.weight))
                                                Text(String(format: "%.1f", grade.score))
                                            }
                                            .padding(.horizontal)
                                            Divider()
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Text(LocalizedStringKey("average"))
                                Spacer()
                                Text(String(format: "%.2f", average))
                                    .fontWeight(.bold)
                                Text(LocalizedStringKey("letter_grade"))
                                Text(letterGrade)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    
                    // Sabit alt buton: "Not Ekle" butonu
                    VStack {
                        Button(LocalizedStringKey("add_grade")) {
                            showingGradeForm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .disabled(remainingWeight == 0)
                    }
                }
                
                // Bilgilendirici pop-up (varsa) overlay olarak ekleniyor
                if showingInfo {
                    infoPopupView
                        .transition(.opacity)
                        .zIndex(2)
                        .offset(y: -100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingGradeForm) {
            OfflineGradeFormView(remainingWeight: remainingWeight) { newGrade in
                grades.append(newGrade)
                calculateAverage()
            }
        }
    }
    
    // Kalan ağırlığı hesaplar
    private var remainingWeight: Double {
        let currentTotal = grades.reduce(0) { $0 + $1.weight }
        return max(0, 100 - currentTotal)
    }
    
    private func deleteGrade(at offsets: IndexSet) {
        grades.remove(atOffsets: offsets)
        calculateAverage()
    }
    
    private func calculateAverage() {
        guard !grades.isEmpty else {
            average = 0.0
            letterGrade = "N/A"
            return
        }
        let totalWeightedScore = grades.reduce(0.0) { $0 + ($1.score * ($1.weight / 100.0)) }
        average = totalWeightedScore
        letterGrade = determineLetterGrade(for: average)
    }
    
    private func determineLetterGrade(for score: Double) -> String {
        switch score {
        case 90...100: return "AA"
        case 85..<90: return "BA"
        case 75..<85: return "BB"
        case 65..<75: return "CB"
        case 60..<65: return "CC"
        case 50..<60: return "DC"
        case 45..<50: return "DD"
        case 40..<45: return "FD"
        default: return "FF"
        }
    }
    
    // Offline mod bildirimi
    private var userNotificationBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(LocalizedStringKey("offline_mode_notification"))
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                withAnimation { showUserNotification = false }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // Bilgilendirici pop-up
    private var infoPopupView: some View {
        VStack(spacing: 16) {
            Text(LocalizedStringKey("info_title"))
                .font(.headline)
            Text(LocalizedStringKey("info_message_offline"))
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(LocalizedStringKey("ok")) {
                withAnimation { showingInfo = false }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
}
struct OfflineGradeFormView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var gradeType: String = ""
    @State private var selectedGradeType: GradeType = .custom
    @State private var score: Double = 50.0
    @State private var weight: Double = 1.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let remainingWeight: Double
    let onSave: (Grade) -> Void
    
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
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section(header: Text(LocalizedStringKey("section_score_and_weight"))) {
                    VStack {
                        HStack {
                            Text(LocalizedStringKey("label_score"))
                            Spacer()
                            Text("\(Int(score))")
                                .foregroundColor(.blue)
                        }
                        Slider(value: $score, in: 0...100, step: 1)
                    }
                    
                    VStack {
                        HStack {
                            Text(LocalizedStringKey("label_weight"))
                            Spacer()
                            Text("\(Int(weight))%")
                                .foregroundColor(weight > remainingWeight ? .red : .blue)
                        }
                        if remainingWeight >= 1 {
                            Slider(value: $weight, in: 1...remainingWeight, step: 1)
                        } else {
                            Slider(value: .constant(0), in: 0...1, step: 1)
                                .disabled(true)
                                .opacity(0.5)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("add_grade"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("save")) { saveGrade() }
                        .disabled(gradeType.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert(LocalizedStringKey("alert_warning"), isPresented: $showAlert) {
                Button(LocalizedStringKey("alert_ok"), role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(alertMessage))
            }
        }
    }
    
    private func saveGrade() {
        if gradeType.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = NSLocalizedString("please_enter_grade_type", comment: "")
            showAlert = true
            return
        }
        // Geçici bir Grade nesnesi oluşturuyoruz. (Kalıcı veri saklanmaz.)
        let newGrade = Grade(
            id: Int(Date().timeIntervalSince1970),
            courseId: 0,
            gradeType: gradeType,
            score: score,
            weight: weight,
            createdAt: "",
            updatedAt: ""
        )
        onSave(newGrade)
        dismiss()
    }
}
