import SwiftUI

struct OnlineGameView: View {
    @State private var currentGame: OnlineGame
    let gameId: String
    let playerId: String
    @StateObject private var viewModel: OnlineGameViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(game: OnlineGame, gameId: String, playerId: String) {
        _currentGame = State(initialValue: game)
        self.gameId = gameId
        self.playerId = playerId
        _viewModel = StateObject(wrappedValue: OnlineGameViewModel(gameId: gameId, playerId: playerId))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header con información del juego
            VStack {
                if viewModel.isWaitingForPlayer {
                    Text("Esperando a que se una otro jugador...")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Text("Jugando contra: \(viewModel.opponentName)")
                        .font(.headline)
                    
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(viewModel.isMyTurn ? .blue : .secondary)
                }
            }
            .padding()
            
            // Tablero de juego
            CustomBoardView(viewModel: viewModel.boardViewModel) { position in
                if viewModel.isMyTurn && !viewModel.isGameOver {
                    viewModel.makeMove(at: position)
                }
            }
            .disabled(viewModel.isWaitingForPlayer || !viewModel.isMyTurn || viewModel.isGameOver)
            .padding()
            
            // Panel de estado y controles
            VStack(spacing: 15) {
                if viewModel.isGameOver {
                    VStack(spacing: 10) {
                        Text(viewModel.gameOverMessage)
                            .font(.title3)
                            .bold()
                            .foregroundColor(viewModel.didWin ? .green :
                                viewModel.gameOverMessage.contains("Empate") ? .orange : .red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Mostrar resultado final
                        HStack(spacing: 20) {
                            VStack {
                                Text(viewModel.amIPlayer1 ? "Tú" : viewModel.opponentName)
                                    .font(.subheadline)
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            
                            Text("vs")
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Text(viewModel.amIPlayer1 ? viewModel.opponentName : "Tú")
                                    .font(.subheadline)
                                Image(systemName: "circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Panel de control
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.leaveGame()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                            Text("Salir")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Triqui Online")
        .interactiveDismissDisabled()
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onReceive(viewModel.$currentGame) { game in
            if let game = game {
                self.currentGame = game
            }
        }
    }
}
