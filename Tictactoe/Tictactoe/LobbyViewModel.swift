import SwiftUI
import Combine
import FirebaseFirestore

class LobbyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var availableGames: [OnlineGame] = []
    @Published var myGames: [OnlineGame] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var playerName: String
    @Published var activeGame: OnlineGame?
    @Published var isJoining = false
    
    // MARK: - Private Properties
    let playerId: String
    private let gameService = FirebaseGameService()
    private var cancellables = Set<AnyCancellable>()
    private var isFirstLoad = true
    
    // MARK: - Initialization
    init() {
        // Cargar nombre del jugador guardado
        
        if let savedPlayerId = UserDefaults.standard.string(forKey: "playerId") {
            self.playerId = savedPlayerId
        } else {
            let newPlayerId = UUID().uuidString
            UserDefaults.standard.set(newPlayerId, forKey: "playerId")
            self.playerId = newPlayerId
        }
        
        self.playerName = UserDefaults.standard.string(forKey: "playerName") ?? "Jugador"
        
        // Cargar juegos inicialmente
        loadGames()
        
        // Configurar timer para actualizaciones periódicas
        Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshGames()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func setPlayerName(_ name: String) {
        playerName = name
        UserDefaults.standard.set(name, forKey: "playerName")
    }
    
    func joinGame(_ game: OnlineGame) {
        guard !isJoining else { return }
        isJoining = true
        
        Task {
            do {
                try await gameService.joinGame(
                    game,
                    player2Name: playerName,
                    player2Id: playerId  // Usar el ID existente del jugador
                )
                await MainActor.run {
                    self.activeGame = game
                    self.isJoining = false
                    self.loadGames()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error al unirse al juego: \(error.localizedDescription)"
                    self.showError = true
                    self.isJoining = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    public func loadGames() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let games = try await gameService.getAvailableGames()
                await MainActor.run {
                    self.updateGames(games)
                    self.isLoading = false
                    self.isFirstLoad = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error al cargar juegos: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func refreshGames() {
        // Solo actualizar si no es la primera carga y no está ya cargando
        guard !isFirstLoad, !isLoading else { return }
        
        Task {
            do {
                let games = try await gameService.getAvailableGames()
                await MainActor.run {
                    self.updateGames(games)
                }
            } catch {
                print("Error en actualización silenciosa: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateGames(_ games: [OnlineGame]) {
        // Filtrar juegos disponibles (excluyendo los propios)
        self.availableGames = games.filter { game in
            game.status == .waiting &&
            game.player1.id != self.playerId &&
            game.player2 == nil
        }
        
        // Filtrar mis juegos
        self.myGames = games.filter { game in
            game.player1.id == self.playerId ||
            game.player2?.id == self.playerId
        }
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
