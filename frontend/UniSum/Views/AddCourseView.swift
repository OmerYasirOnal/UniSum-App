import SwiftUI

struct AddCourseView: View {
    @Binding var isPresented: Bool
        @Binding var selectedCourse: Course?  // Yeni sıralama
        @ObservedObject var courseViewModel: CourseViewModel
        let termId: Int
        let userId: Int
    // MARK: - Properties
  
    @State private var courseName: String = ""
    @State private var credits: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: Field?

    private let keyboardPadding: CGFloat = 100
    
    enum Field {
        case courseName, credits
    }
    

    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                headerView
                Divider()
                formView
                saveButton
            }
            .padding(20)
            .frame(width: 320)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.bottom, max(keyboardHeight/2 - keyboardPadding, 0))
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: setupKeyboardNotifications)
        .onDisappear(perform: removeKeyboardNotifications)
    }
    
    // MARK: - UI Components
    private var headerView: some View {
        HStack {
            Text(LocalizedStringKey("add_course"))
                .font(.title2)
                .bold()
                .padding(.bottom, 8)
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var formView: some View {
        VStack(spacing: 16) {
            // Ders Adı
            OptimizedTextField(
                title: LocalizedStringKey("course_name"),
                placeholder: LocalizedStringKey("course_name_placeholder"),
                text: $courseName,
                keyboardType: .default,
                submitLabel: .next,
                onSubmit: { focusedField = .credits },
                isFocused: focusedField == .courseName,
                onFocusChange: { isFocused in
                    if isFocused {
                        focusedField = .courseName
                    }
                }
            )
            .onChange(of: courseName) { _ in
                errorMessage = nil
            }
            
            // Kredi
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("credits"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("0.0", text: $credits)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .focused($focusedField, equals: .credits)
                    .onChange(of: credits) { newValue in
                        validateCredits(newValue)
                    }
            }
            
            if let errorMessage = errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .foregroundColor(.red)
                    .font(.caption)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal)
    }
    
    private var saveButton: some View {
        Button(action: saveCourse) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text(LocalizedStringKey("save"))
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .shadow(radius: 2)
            )
            .opacity(isFormValid() ? 1 : 0.6)
        }
        .disabled(!isFormValid() || isLoading)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    // MARK: - Helper Functions
    private func validateCredits(_ newValue: String) {
        // Sadece sayı ve nokta girişine izin ver
        let filtered = newValue.filter { "0123456789.".contains($0) }
        if filtered != newValue {
            credits = filtered
        }
        
        // En fazla bir nokta olabilir
        if filtered.filter({ $0 == "." }).count > 1 {
            credits = String(filtered.prefix(while: { $0 != "." })) + "."
        }
        
        // Maksimum 2 ondalık basamak
        if let dotIndex = filtered.firstIndex(of: ".") {
            let decimals = filtered[filtered.index(after: dotIndex)...]
            if decimals.count > 2 {
                credits = String(filtered[..<filtered.index(dotIndex, offsetBy: 3)])
            }
        }
        
        errorMessage = nil
    }
    
    private func isFormValid() -> Bool {
        guard !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let creditsValue = Double(credits),
              creditsValue > 0,
              creditsValue <= 30 else {
            return false
        }
        return true
    }
    
    private func saveCourse() {
            guard let creditsValue = Double(credits) else {
                errorMessage = "invalid_credits"
                return
            }
            
            guard creditsValue <= 30 else {
                errorMessage = "credits_too_high"
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            courseViewModel.addCourse(
                termId: termId,
                userId: userId,
                name: courseName.trimmingCharacters(in: .whitespacesAndNewlines),
                credits: creditsValue
            ) { [self] success in
                isLoading = false
                if success {
                    if let newCourse = courseViewModel.courses.last {
                        selectedCourse = newCourse  // Set the selected course
                    }
                    courseViewModel.fetchCourses(for: termId)
                    isPresented = false
                } else {
                    errorMessage = "course_add_error"
                }
            }
        }
    
    // MARK: - Keyboard Management
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - OptimizedTextField
struct OptimizedTextField: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    var isFocused: Bool
    var onFocusChange: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                )
                .autocapitalization(keyboardType == .default ? .words : .none)
                .disableAutocorrection(true)
                .onChange(of: isFocused) { focused in
                    onFocusChange(focused)
                }
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit?()
                }
        }
    }
}
