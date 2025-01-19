import SwiftUI

class OnlineBoardViewModel: ObservableObject {
    @Published var moves: [Int: Player] = [:]
    @Published var isGameOver = false
    @Published var winningLine: [Int]?
    
    enum Player {
        case x
        case o
    }
    
    func processMove(for position: Int) {
        // Solo procesar el movimiento, sin lógica de IA
        guard moves[position] == nil else { return }
        moves[position] = .x
    }
    
    func resetBoard() {
        moves.removeAll()
        isGameOver = false
        winningLine = nil
    }
}
