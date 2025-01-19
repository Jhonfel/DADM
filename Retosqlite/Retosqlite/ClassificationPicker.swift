// ClassificationPicker.swift
import SwiftUI

struct ClassificationPicker: View {
    @Binding var selection: CompanyClassification?
    
    var body: some View {
        Picker("Clasificación", selection: $selection) {
            Text("Todas").tag(nil as CompanyClassification?)
            ForEach(CompanyClassification.allCases, id: \.self) { classification in
                Text(classification.rawValue).tag(classification as CompanyClassification?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
    }
}
