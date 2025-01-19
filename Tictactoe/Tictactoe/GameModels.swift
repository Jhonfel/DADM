// GameModels.swift

import Foundation

struct OnlineGame: Identifiable, Codable, Equatable {
    let id: String
    var player1: Player
    var player2: Player?
    var status: GameStatus
    var board: [String?]
    var currentPlayer: String
    var timestamp: Date
    var winner: String?
    
    struct Player: Codable, Equatable {
        let id: String
        let name: String
    }
    
    // Implementación personalizada de Equatable si es necesaria
    static func == (lhs: OnlineGame, rhs: OnlineGame) -> Bool {
        return lhs.id == rhs.id &&
               lhs.player1 == rhs.player1 &&
               lhs.player2 == rhs.player2 &&
               lhs.status == rhs.status &&
               lhs.board == rhs.board &&
               lhs.currentPlayer == rhs.currentPlayer &&
               lhs.timestamp == rhs.timestamp &&
               lhs.winner == rhs.winner
    }
}

enum GameStatus: String, Codable, Equatable {
    case waiting = "waiting"
    case inProgress = "inProgress"
    case finished = "finished"
}

enum GameError: Error {
    case gameNotFound
    case invalidMove
    case notYourTurn
    case gameFull
    case gameFinished
}
