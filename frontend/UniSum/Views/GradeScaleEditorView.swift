//
//  GradeScaleEditorView.swift
//
//  Created by Yasir on 31.01.2025.
//
import SwiftUI

struct GradeScaleEditorView: View {
    @ObservedObject var viewModel: GradeScaleViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.gradeScales) { $scale in
                    GradeScaleRow(scale: scale) { updatedScale in
                        if let index = viewModel.gradeScales.firstIndex(where: { $0.letter == updatedScale.letter }) {
                            viewModel.gradeScales[index] = updatedScale
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("grade_scale", comment: "Grade Scale header title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("save")) {
                        viewModel.saveGradeScales { success in
                            if success {
                                dismiss()
                            } else {
                                // İsteğe bağlı: hata mesajı göster
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadInitialData()
            }
        }
    }
}


struct GradeScaleRow: View {
    let scale: GradeScale
    let onUpdate: (GradeScale) -> Void
    
    @State private var minScore: String
    @State private var gpa: String
    
    init(scale: GradeScale, onUpdate: @escaping (GradeScale) -> Void) {
        self.scale = scale
        self.onUpdate = onUpdate
        _minScore = State(initialValue: String(scale.minScore))
        _gpa = State(initialValue: String(format: "%.2f", scale.gpa))
    }
    
    var body: some View {
        HStack {
            Text(scale.letter)
                .bold()
                .frame(width: 40)
            
            TextField("Min Score", text: $minScore)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: minScore) { _ in updateScale() }
            
            TextField("GPA", text: $gpa)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: gpa) { _ in updateScale() }
        }
        .padding(.vertical, 4)
    }
    
    private func updateScale() {
        guard let newMinScore = Int(minScore),
              let newGPA = Double(gpa) else { return }
        
        var updatedScale = scale
        updatedScale.minScore = newMinScore
        updatedScale.gpa = newGPA
        updatedScale.is_custom = true
        onUpdate(updatedScale)
    }
}
