// CreateGameView.swift

import SwiftUI

struct CreateGameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateGameViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Configuración del Juego") {
                    TextField("Nombre del juego (opcional)", text: $viewModel.gameName)
                }
                
                Section {
                    Button(action: viewModel.createGame) {
                        if viewModel.isCreating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Crear Juego")
                        }
                    }
                    .disabled(viewModel.isCreating)
                }
            }
            .navigationTitle("Nuevo Juego")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.gameCreated) { created in
                if created {
                    dismiss()
                }
            }
        }
    }
}
