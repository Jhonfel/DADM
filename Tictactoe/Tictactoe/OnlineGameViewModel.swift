import SwiftUI
import Combine
import FirebaseFirestore

class OnlineGameViewModel: ObservableObject {
    @Published var boardViewModel = OnlineBoardViewModel()
    @Published var statusMessage = "Esperando..."
    @Published var isMyTurn = false
    @Published var isGameOver = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var didWin = false
    @Published var gameOverMessage = ""
    @Published var isWaitingForPlayer = true
    @Published var currentGame: OnlineGame?
    @Published var opponentName: String = "Desconocido"
    @Published private(set) var amIPlayer1: Bool = false

    private let gameService = FirebaseGameService()
    private var cancellables = Set<AnyCancellable>()
    private let gameId: String
    private let playerId: String
    
    init(gameId: String, playerId: String) {
        self.gameId = gameId
        self.playerId = playerId
        setupGameObserver()
    }
    
    private func setupGameObserver() {
        gameService.observeGame(gameId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] game in
                self?.currentGame = game
                self?.updateGameState(game)
            }
            .store(in: &cancellables)
    }
    
    private func updateGameState(_ game: OnlineGame) {
        isWaitingForPlayer = game.status == .waiting
        
        // Determinar roles
        let amIPlayer1 = game.player1.id == playerId
        
        // Actualizar nombre del oponente correctamente
        if amIPlayer1 {
            // Si soy player1, mi oponente es player2
            opponentName = game.player2?.name ?? "Esperando oponente"
        } else {
            // Si soy player2, mi oponente es player1
            opponentName = game.player1.name
        }
        
        // Actualizar el tablero con la lógica corregida
        boardViewModel.moves.removeAll()
        for (index, value) in game.board.enumerated() {
            if let playerAtPosition = value {
                // Si soy Player1, mis movimientos son X
                // Si soy Player2, mis movimientos son O
                let mark = (playerAtPosition == game.player1.id)
                    ? OnlineBoardViewModel.Player.x  // Player1 siempre usa X
                    : OnlineBoardViewModel.Player.o  // Player2 siempre usa O
                boardViewModel.moves[index] = mark
            }
        }
        
        // Manejar diferentes estados del juego
        switch game.status {
        case .waiting:
            statusMessage = "Esperando oponente..."
            isMyTurn = false
            isGameOver = false
            
        case .inProgress:
            isMyTurn = game.currentPlayer == playerId
            statusMessage = isMyTurn ? "Tu turno" : "Turno de \(opponentName)"
            isGameOver = false
            
            // Debug logs para verificar la asignación de nombres
            print("Información de jugadores:")
            print("Player1 Name: \(game.player1.name)")
            print("Player2 Name: \(game.player2?.name ?? "No disponible")")
            print("Mi ID: \(playerId)")
            print("Soy Player1: \(amIPlayer1)")
            print("Nombre del oponente: \(opponentName)")
            
        case .finished:
            isGameOver = true
            isMyTurn = false
            
            if let winner = game.winner {
                if winner == playerId {
                    statusMessage = "¡Has ganado!"
                    gameOverMessage = "¡Felicitaciones! Has ganado la partida"
                    didWin = true
                } else {
                    statusMessage = "¡Ha ganado \(opponentName)!"
                    gameOverMessage = "Ha ganado \(opponentName)"
                    didWin = false
                }
            } else {
                statusMessage = "¡Empate!"
                gameOverMessage = "El juego ha terminado en empate"
                didWin = false
            }
        }
    }
    
    
    private func checkGameStatus(_ game: OnlineGame) {
        if game.status == .finished {
            isGameOver = true
            if game.winner == playerId {
                didWin = true
                gameOverMessage = "¡Has ganado!"
            } else {
                didWin = false
                gameOverMessage = "Has perdido"
            }
        }
    }
    
    // En el método makeMove de OnlineGameViewModel:

    func makeMove(at position: Int) {
        print("Intentando realizar movimiento:")
        print("Es mi turno: \(isMyTurn)")
        print("Player ID: \(playerId)")
        print("Current Player: \(currentGame?.currentPlayer ?? "unknown")")
        
        guard !isWaitingForPlayer && isMyTurn && !isGameOver else {
            print("Movimiento no permitido - Condiciones:")
            print("Esperando jugador: \(isWaitingForPlayer)")
            print("Es mi turno: \(isMyTurn)")
            print("Juego terminado: \(isGameOver)")
            return
        }
        
        // Verificar si la posición está vacía
        guard boardViewModel.moves[position] == nil else {
            print("Posición \(position) ya está ocupada")
            return
        }

        Task {
            do {
                try await gameService.makeMove(gameId: gameId, at: position, playerId: playerId)
                print("Movimiento realizado con éxito en posición \(position)")
            } catch {
                await MainActor.run {
                    handleError(error)
                    print("Error al realizar movimiento: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    func leaveGame() {
        gameService.removeListener(for: gameId)
    }
    
    deinit {
        leaveGame()
    }
}
