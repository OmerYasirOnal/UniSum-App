import SwiftUI

struct AddTermPanel: View {
    // MARK: - Properties
    @Binding var isVisible: Bool
    @ObservedObject var termViewModel: TermViewModel
    @State private var selectedClassLevel = 0
    @State private var selectedTermNumber = 0
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Constants
    let classLevels: [LocalizedStringKey] = [
        "class_level_pre",
        "class_level_1",
        "class_level_2",
        "class_level_3",
        "class_level_4"
    ]
    
    let classLevelKeys: [String] = ["pre", "1", "2", "3", "4"]
    let termNumbers: [LocalizedStringKey] = ["term_1", "term_2"]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            overlayBackground
            panelContent
        }
    }
    
    // MARK: - UI Components
    private var overlayBackground: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring()) {
                    isVisible = false
                }
            }
    }
    
    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
            Divider()
            classLevelPicker
            termNumberPicker
            saveButton
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.9)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    private var headerView: some View {
        HStack {
            Text(LocalizedStringKey("add_new_term"))
                .font(.title3)
                .bold()
            Spacer()
            closeButton
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                isVisible = false
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    private var classLevelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("class_level"))
                .font(.headline)
            Picker("", selection: $selectedClassLevel) {
                ForEach(0..<classLevels.count, id: \.self) { index in
                    Text(classLevels[index])
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var termNumberPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("term"))
                .font(.headline)
            Picker("", selection: $selectedTermNumber) {
                ForEach(0..<termNumbers.count, id: \.self) { index in
                    Text(termNumbers[index])
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveTerm) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(LocalizedStringKey("save"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Actions
    private func saveTerm() {
        let formattedClassLevel = classLevelKeys[selectedClassLevel]
        termViewModel.addTerm(
            classLevel: formattedClassLevel,
            termNumber: selectedTermNumber + 1
        )
        withAnimation(.spring()) {
            isVisible = false
        }
    }
}
