import SwiftUI

struct EditGradeScaleView: View {
    @Binding var gradeScales: [GradeScale]
    @Environment(\.dismiss) var dismiss
    @State private var showingPicker = false
    @State private var selectedScale: GradeScale?
    
    var body: some View {
        NavigationView {
            List {
                ForEach($gradeScales) { $scale in
                    HStack {
                        Text(scale.letter)
                            .bold()
                            .frame(width: 40, alignment: .leading)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("≥ \(scale.minScore)")
                                .font(.subheadline)
                            Text("GPA: \(scale.gpa, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedScale = scale
                        showingPicker = true
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("edit_grade_scale"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                if let scale = selectedScale {
                    GradeScalePickerView(
                        scale: binding(for: scale),
                        isPresented: $showingPicker
                    )
                }
            }
        }
    }
    
    private func binding(for scale: GradeScale) -> Binding<GradeScale> {
        guard let index = gradeScales.firstIndex(where: { $0.letter == scale.letter }) else {
            fatalError("Scale not found")
        }
        return $gradeScales[index]
    }
}

struct GradeScalePickerView: View {
    @Binding var scale: GradeScale
    @Binding var isPresented: Bool
    
    private let minScoreRange = Array(0...100)
    private let gpaRange = stride(from: 0.0, through: 4.0, by: 0.1).map { $0 }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStringKey("minimum_score"))) {
                    Picker("", selection: $scale.minScore) {
                        ForEach(minScoreRange, id: \.self) { score in
                            Text("\(score)").tag(score)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text(LocalizedStringKey("gpa_value"))) {
                    Picker("", selection: $scale.gpa) {
                        ForEach(gpaRange, id: \.self) { gpa in
                            Text(String(format: "%.1f", gpa)).tag(gpa)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle(scale.letter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("done")) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
