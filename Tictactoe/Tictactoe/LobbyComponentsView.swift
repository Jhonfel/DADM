import SwiftUI


struct GameRowView: View {
    let game: OnlineGame
    let onJoin: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Creado por: \(game.player1.name)")
                    .font(.headline)
                
                Text("Hace \(timeAgo(game.timestamp))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onJoin) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text("Unirse")
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Vista previa para desarrollo
#Preview {
    GameRowView(
        game: OnlineGame(
            id: "1",
            player1: OnlineGame.Player(id: "1", name: "Jugador 1"),
            player2: nil,
            status: .waiting,
            board: Array(repeating: nil, count: 9),
            currentPlayer: "1",
            timestamp: Date()
        )
    ) {
        print("Unirse presionado")
    }
}

// Vista para los juegos del jugador actual
struct MyGameRowView: View {
    let game: OnlineGame
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("VS \(game.player2?.name ?? "Esperando oponente")")
                .font(.headline)
            
            HStack {
                Text(game.status.displayText)
                    .font(.subheadline)
                    .foregroundColor(game.status.displayColor)
                
                Spacer()
                
                Text("Hace \(timeAgo(game.timestamp))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Vista previa para desarrollo
#Preview {
    GameRowView(
        game: OnlineGame(
            id: "1",
            player1: OnlineGame.Player(id: "1", name: "Jugador 1"),
            player2: nil,
            status: .waiting,
            board: Array(repeating: nil, count: 9),
            currentPlayer: "1",
            timestamp: Date()
        )
    ) {
        print("Join tapped")
    }
}
