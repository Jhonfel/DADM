// PlayerNameInputView.swift

import SwiftUI

struct PlayerNameInputView: View {
    @Binding var playerName: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tu Nombre") {
                    TextField("Ingresa tu nombre", text: $playerName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button("Comenzar") {
                        if !playerName.isEmpty {
                            onSubmit()
                        }
                    }
                    .disabled(playerName.isEmpty)
                }
            }
            .navigationTitle("Bienvenido")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}
