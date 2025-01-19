import Combine
import FirebaseFirestore

class CreateGameViewModel: ObservableObject {
    @Published var gameName = ""
    @Published var isCreating = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var gameCreated = false
    
    private let gameService = FirebaseGameService()
    
    func createGame() {
        guard !isCreating else { return }
        
        isCreating = true
        
        let playerName = UserDefaults.standard.string(forKey: "playerName") ?? "Jugador"
        let playerId = UserDefaults.standard.string(forKey: "playerId") ?? UUID().uuidString
        
        Task {
            do {
                let _ = try await gameService.createGame(player1Id: playerId, player1Name: playerName)
                await MainActor.run {
                    isCreating = false
                    gameCreated = true
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

}
