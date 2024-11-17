//
//  GameViewModel.swift
//  Tictactoe
//
//  Created by Jhon Felipe Delgado on 16/11/24.
//
// GameViewModel.swift
// GameViewModel.swift
import SwiftUI
import Combine
import AudioToolbox

final class GameViewModel: ObservableObject {
    @Published var moves: [Int: Player] = [:]
    @Published var isGameOver = false
    @Published var statusText = "Turno de X"
    @Published var winningLine: [Int]?
    
    private var currentPlayer: Player = .x
    
    enum Player {
        case x
        case o
        
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
    
    func processMove(for position: Int) {
        if moves[position] == nil {
            moves[position] = currentPlayer
            SoundManager.playSound(.tap)
            
            if let winningPattern = checkWin(for: currentPlayer) {
                statusText = "¡\(currentPlayer.indicator) ha ganado!"
                isGameOver = true
                winningLine = winningPattern
                SoundManager.playSound(.success)
            } else if checkDraw() {
                statusText = "¡Empate!"
                isGameOver = true
                SoundManager.playSound(.error)
            } else {
                currentPlayer = currentPlayer == .x ? .o : .x
                statusText = "Turno de \(currentPlayer.indicator)"
            }
        } else {
            // Sonido de movimiento inválido
            SoundManager.playSound(.error)
        }
    }
    
    func resetGame() {
        moves.removeAll()
        currentPlayer = .x
        isGameOver = false
        statusText = "Turno de X"
        winningLine = nil
        SoundManager.playSound(.tap) // Sonido al reiniciar
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

