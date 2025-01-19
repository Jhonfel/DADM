// GameModels+Extensions.swift

import SwiftUI

extension GameStatus {
    var displayText: String {
        switch self {
        case .waiting:
            return "Esperando oponente"
        case .inProgress:
            return "En progreso"
        case .finished:
            return "Finalizado"
        }
    }
    
    var displayColor: Color {
        switch self {
        case .waiting:
            return .orange
        case .inProgress:
            return .blue
        case .finished:
            return .gray
        }
    }
}
