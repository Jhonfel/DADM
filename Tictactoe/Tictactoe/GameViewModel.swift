import SwiftUI
import Combine
import AudioToolbox

// Enumeración para las claves de UserDefaults
private enum UserDefaultsKeys {
    static let humanWins = "humanWins"
    static let computerWins = "computerWins"
    static let ties = "ties"
    static let difficulty = "difficulty"
}

enum Difficulty: Int {
    case easy = 0
    case medium = 1
    case hard = 2
    
    var displayName: String {
        switch self {
        case .easy: return "Fácil"
        case .medium: return "Medio"
        case .hard: return "Difícil"
        }
    }
}

final class GameViewModel: ObservableObject {
    @Published var moves: [Int: Player] = [:]
    @Published var isGameOver = false
    @Published var statusText = "Tu turno (X)"
    @Published var winningLine: [Int]?
    @Published var mHumanWins: Int = 0
    @Published var mComputerWins: Int = 0
    @Published var mTies: Int = 0
    
    private var currentPlayer: Player = .x
    private var isComputerEnabled = true
    private var isComputerThinking = false
    
    @Published private(set) var difficulty: Difficulty {
        didSet {
            UserDefaults.standard.set(difficulty.rawValue, forKey: UserDefaultsKeys.difficulty)
        }
    }
    
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
        [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Horizontales
        [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Verticales
        [0, 4, 8], [2, 4, 6]              // Diagonales
    ]
    
    init() {
        // Cargar dificultad guardada
        let savedDifficulty = UserDefaults.standard.integer(forKey: UserDefaultsKeys.difficulty)
        self.difficulty = Difficulty(rawValue: savedDifficulty) ?? .medium
        
        // Cargar puntuaciones guardadas
        let defaults = UserDefaults.standard
        self.mHumanWins = defaults.integer(forKey: UserDefaultsKeys.humanWins)
        self.mComputerWins = defaults.integer(forKey: UserDefaultsKeys.computerWins)
        self.mTies = defaults.integer(forKey: UserDefaultsKeys.ties)
    }
    
    func setDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        UserDefaults.standard.set(newDifficulty.rawValue, forKey: UserDefaultsKeys.difficulty)
        resetGame()
    }
    
    private func saveScores() {
        let defaults = UserDefaults.standard
        defaults.set(mHumanWins, forKey: UserDefaultsKeys.humanWins)
        defaults.set(mComputerWins, forKey: UserDefaultsKeys.computerWins)
        defaults.set(mTies, forKey: UserDefaultsKeys.ties)
    }
    
    func resetScores() {
        mHumanWins = 0
        mComputerWins = 0
        mTies = 0
        saveScores()
        statusText = "Puntuaciones reiniciadas"
    }
    
    func processMove(for position: Int) {
        guard !isGameOver, moves[position] == nil, currentPlayer == .x else {
            SoundManager.playSound(.error)
            return
        }
        
        makeMove(at: position, for: .x, playSound: true)
        
        if !isGameOver && isComputerEnabled {
            isComputerThinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self, self.isComputerThinking else { return }
                self.makeComputerMove()
                self.isComputerThinking = false
            }
        }
    }
    
    private func makeMove(at position: Int, for player: Player, playSound: Bool = false) {
        moves[position] = player
        if playSound {
            SoundManager.playSound(.tap)
        }
        
        if let winningPattern = checkWin(for: player) {
            if player == .x {
                mHumanWins += 1
            } else {
                mComputerWins += 1
            }
            statusText = player == .x ? "¡Has ganado!" : "¡La computadora ha ganado!"
            isGameOver = true
            winningLine = winningPattern
            SoundManager.playSound(.success)
            saveScores()
        } else if checkDraw() {
            mTies += 1
            statusText = "¡Empate!"
            isGameOver = true
            SoundManager.playSound(.error)
            saveScores()
        } else {
            currentPlayer = currentPlayer == .x ? .o : .x
            statusText = currentPlayer == .x ? "Tu turno (X)" : "Turno de la computadora (O)"
        }
    }
    
    func cancelComputerMove() {
        isComputerThinking = false
    }
    
    func checkAndMakeComputerMoveIfNeeded() {
        if currentPlayer == .o && !isGameOver {
            makeComputerMove()
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
    
    deinit {
        cancelComputerMove()
    }
}
