import SwiftUI
import Combine
import AudioToolbox

enum Difficulty {
    case easy, medium, hard
}

final class GameViewModel: ObservableObject {
    @Published var moves: [Int: Player] = [:]
    @Published var isGameOver = false
    @Published var statusText = "Tu turno (X)"
    @Published var winningLine: [Int]?
    
    private var currentPlayer: Player = .x
    private var isComputerEnabled = true
    private var difficulty: Difficulty = .medium
    
    enum Player {
        case x  // Humano
        case o  // Computadora
        
        var indicator: String {
            switch self {
            case .x: return "X"
            case .o: return "O"
            }
        }
    }
    
    private let winPatterns: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]
    
    func setDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        resetGame()
    }
    
    func processMove(for position: Int) {
        guard !isGameOver, moves[position] == nil, currentPlayer == .x else {
            SoundManager.playSound(.error)
            return
        }
        
        makeMove(at: position, for: .x)
        
        if !isGameOver && isComputerEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.makeComputerMove()
            }
        }
    }
    
    private func makeMove(at position: Int, for player: Player) {
        moves[position] = player
        SoundManager.playSound(.tap)
        
        if let winningPattern = checkWin(for: player) {
            statusText = player == .x ? "¡Has ganado!" : "¡La computadora ha ganado!"
            isGameOver = true
            winningLine = winningPattern
            SoundManager.playSound(.success)
        } else if checkDraw() {
            statusText = "¡Empate!"
            isGameOver = true
            SoundManager.playSound(.error)
        } else {
            currentPlayer = currentPlayer == .x ? .o : .x
            statusText = currentPlayer == .x ? "Tu turno (X)" : "Turno de la computadora (O)"
        }
    }
    
    private func makeComputerMove() {
        guard !isGameOver, currentPlayer == .o else { return }
        
        switch difficulty {
        case .easy:
            makeRandomMove()
        case .medium:
            if Bool.random() {
                makeSmartMove()
            } else {
                makeRandomMove()
            }
        case .hard:
            makeSmartMove()
        }
    }
    
    private func makeRandomMove() {
        if let emptyPosition = (0...8).filter({ moves[$0] == nil }).randomElement() {
            makeMove(at: emptyPosition, for: .o)
        }
    }
    
    private func makeSmartMove() {
        // 1. Buscar movimiento ganador
        if let winningMove = findBestMove(for: .o) {
            makeMove(at: winningMove, for: .o)
            return
        }
        
        // 2. Bloquear movimiento ganador del jugador
        if let blockingMove = findBestMove(for: .x) {
            makeMove(at: blockingMove, for: .o)
            return
        }
        
        // 3. Tomar el centro si está disponible
        if moves[4] == nil {
            makeMove(at: 4, for: .o)
            return
        }
        
        // 4. Tomar una esquina disponible
        let corners = [0, 2, 6, 8]
        if let corner = corners.first(where: { moves[$0] == nil }) {
            makeMove(at: corner, for: .o)
            return
        }
        
        // 5. Tomar cualquier casilla disponible
        makeRandomMove()
    }
    
    private func findBestMove(for player: Player) -> Int? {
        for pattern in winPatterns {
            let playerMoves = pattern.filter { moves[$0] == player }
            let emptySpot = pattern.first { moves[$0] == nil }
            
            if playerMoves.count == 2 && emptySpot != nil {
                return emptySpot
            }
        }
        return nil
    }
    
    func resetGame() {
        moves.removeAll()
        currentPlayer = .x
        isGameOver = false
        statusText = "Tu turno (X)"
        winningLine = nil
        SoundManager.playSound(.tap)
    }
    
    private func checkWin(for player: Player) -> [Int]? {
        let playerMoves = Set(moves.filter { $0.value == player }.map { $0.key })
        
        for pattern in winPatterns {
            if pattern.allSatisfy({ playerMoves.contains($0) }) {
                return pattern
            }
        }
        return nil
    }
    
    private func checkDraw() -> Bool {
        return moves.count == 9
    }
}
