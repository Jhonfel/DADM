import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingDifficultyPicker = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if UIDevice.current.orientation.isLandscape {
                    // Vista horizontal
                    HStack(spacing: 0) {
                        // Panel izquierdo con el tablero
                        VStack {
                            Spacer()
                            CustomBoardView(viewModel: viewModel)
                                .frame(
                                    width: min(geometry.size.height - 60, 300),
                                    height: min(geometry.size.height - 60, 300)
                                )
                                .padding()
                                .disabled(viewModel.isGameOver)
                            Spacer()
                        }
                        .frame(width: geometry.size.width * 0.6)
                        
                        // Panel lateral derecho
                        VStack(spacing: 10) {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 15) {
                                    Text("TicTacToe")
                                        .font(.title3)
                                        .bold()
                                    
                                    Text("DADM 2024-2")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    // Panel de Puntuaciones con dificultad
                                    VStack(spacing: 8) {
                                        Text("Puntuaciones")
                                            .font(.headline)
                                        
                                        // Mostrar dificultad actual
                                        Text("Dificultad: \(viewModel.difficulty.displayName)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 4)
                                        
                                        HStack(spacing: 15) {
                                            ScoreColumn(title: "Tú (X)", score: viewModel.mHumanWins)
                                            ScoreColumn(title: "Empates", score: viewModel.mTies)
                                            ScoreColumn(title: "CPU (O)", score: viewModel.mComputerWins)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    
                                    // Estado del juego
                                    Text(viewModel.statusText)
                                        .font(.callout)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.top)
                            }
                            
                            Spacer()
                            
                            // Panel de control
                            controlPanel
                        }
                        .frame(width: geometry.size.width * 0.4)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                    }
                } else {
                    // Vista vertical
                    VStack {
                        Text("TicTacToe swift DADM 2024-2")
                            .font(.title2)
                            .bold()
                            .padding(.top)
                        
                        // Panel de Puntuaciones con dificultad
                        VStack(spacing: 10) {
                            // Mostrar dificultad actual
                            Text("Dificultad: \(viewModel.difficulty.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.bottom, 4)
                            
                            HStack(spacing: 20) {
                                ScoreColumn(title: "Tú (X)", score: viewModel.mHumanWins)
                                ScoreColumn(title: "Empates", score: viewModel.mTies)
                                ScoreColumn(title: "CPU (O)", score: viewModel.mComputerWins)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                        
                        Text(viewModel.statusText)
                            .font(.title3)
                            .bold()
                            .padding()
                        
                        CustomBoardView(viewModel: viewModel)
                            .frame(
                                width: min(geometry.size.width - 40, 300),
                                height: min(geometry.size.width - 40, 300)
                            )
                            .padding()
                            .disabled(viewModel.isGameOver)
                        
                        Spacer()
                        
                        controlPanel
                    }
                }
            }
        }
        .confirmationDialog("Seleccionar Dificultad",
                          isPresented: $showingDifficultyPicker,
                          titleVisibility: .visible) {
            Button("Fácil") { viewModel.setDifficulty(.easy) }
            Button("Medio") { viewModel.setDifficulty(.medium) }
            Button("Difícil") { viewModel.setDifficulty(.hard) }
        }
        .onChange(of: UIDevice.current.orientation) { _ in
            // Dar tiempo para que la vista se actualice
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.checkAndMakeComputerMoveIfNeeded()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.checkAndMakeComputerMoveIfNeeded()
            case .inactive:
                viewModel.cancelComputerMove()
            case .background:
                viewModel.cancelComputerMove()
            @unknown default:
                break
            }
        }
    }
    
    struct ScoreColumn: View {
        let title: String
        let score: Int
        
        var body: some View {
            VStack(spacing: 5) {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(score)")
                    .font(.title3)
                    .bold()
            }
            .frame(minWidth: 60)
        }
    }
    
    private var controlPanel: some View {
        HStack(spacing: 15) {
            // Botón Nuevo Juego
            ControlButton(
                action: { viewModel.resetGame() },
                imageName: "arrow.clockwise",
                text: "Nuevo",
                color: .green
            )
            
            // Botón Dificultad
            ControlButton(
                action: { showingDifficultyPicker = true },
                imageName: "slider.horizontal.3",
                text: "Nivel",
                color: .blue
            )
            
            // Botón Reiniciar Puntuaciones
            ControlButton(
                action: { viewModel.resetScores() },
                imageName: "trophy",
                text: "Resetear",
                color: .orange
            )
            
            // Botón Salir
            ControlButton(
                action: { exit(0) },
                imageName: "xmark.circle",
                text: "Salir",
                color: .red
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct ControlButton: View {
    let action: () -> Void
    let imageName: String
    let text: String
    let color: Color
    
    var body: some View {
        Button(action: {
            withAnimation {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: imageName)
                    .font(.system(size: 24))
                Text(text)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .frame(width: 50, height: 50)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 2)
            )
        }
    }
}
