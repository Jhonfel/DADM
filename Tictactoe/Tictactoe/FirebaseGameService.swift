import FirebaseFirestore
import Combine

class FirebaseGameService: ObservableObject {
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    init() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.isSSLEnabled = true
        settings.dispatchQueue = DispatchQueue.main
        // Forzar uso de IPv4
        settings.host = "firestore.googleapis.com"
        db.settings = settings
        
        print("Firestore inicializado con configuración:")
        print("Host: \(db.settings.host)")
        print("Persistencia: \(db.settings.isPersistenceEnabled)")
        
        testConnection()
    }
    
    private func testConnection() {
        print("Iniciando test de conexión a Firestore...")
        let testRef = db.collection("test").document("connection")
        testRef.getDocument { (document, error) in
            print("Test de conexión Firestore:")
            if let error = error {
                print("- Error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("- Código: \(nsError.code)")
                    print("- Dominio: \(nsError.domain)")
                    print("- Descripción: \(nsError.localizedDescription)")
                }
            } else {
                print("- Conexión exitosa")
            }
        }
    }
    
    // Crear un nuevo juego
    func createGame(player1Id: String, player1Name: String) async throws -> OnlineGame {
        print("Intentando crear juego...")
        print("Estado de la red: \(Firestore.firestore().app.isDataCollectionDefaultEnabled)")
        
        let gameRef = db.collection("games").document()
        
        let game = OnlineGame(
            id: gameRef.documentID,
            player1: OnlineGame.Player(id: player1Id, name: player1Name), // Usar el ID proporcionado
            player2: nil,
            status: .waiting,
            board: Array(repeating: nil, count: 9),
            currentPlayer: player1Id,
            timestamp: Date()
        )
        
        do {
            try gameRef.setData(from: game)
            print("Juego creado exitosamente con ID: \(game.id)")
            return game
        } catch {
            print("Error al crear juego: \(error.localizedDescription)")
            throw error
        }
    }

    // Obtener juegos disponibles
    func getAvailableGames() async throws -> [OnlineGame] {
        print("Buscando juegos disponibles...")
        do {
            // Modificado para usar una consulta más simple sin ordenamiento
            let snapshot = try await db.collection("games")
                .whereField("status", isEqualTo: GameStatus.waiting.rawValue)
                .getDocuments()
            
            let games = try snapshot.documents.compactMap { document in
                try document.data(as: OnlineGame.self)
            }
            // Ordenamos los juegos en memoria
            let sortedGames = games.sorted { $0.timestamp > $1.timestamp }
            
            print("Juegos encontrados: \(games.count)")
            return sortedGames
        } catch {
            print("Error al obtener juegos: \(error.localizedDescription)")
            throw error
        }
    }
    
    func joinGame(_ game: OnlineGame, player2Name: String, player2Id: String) async throws {
        print("Intentando unirse al juego: \(game.id)")
        print("Player2 ID: \(player2Id)")
        
        let player2 = OnlineGame.Player(id: player2Id, name: player2Name)
        
        do {
            try await db.collection("games").document(game.id).updateData([
                "player2": [
                    "id": player2Id,
                    "name": player2Name
                ],
                "status": GameStatus.inProgress.rawValue
            ])
            print("Unido exitosamente al juego")
        } catch {
            print("Error al unirse al juego: \(error.localizedDescription)")
            throw error
        }
    }
    
    func observeGame(_ gameId: String) -> AnyPublisher<OnlineGame, Error> {
        print("Iniciando observación del juego: \(gameId)")
        let subject = PassthroughSubject<OnlineGame, Error>()
        
        let listener = db.collection("games").document(gameId)
            .addSnapshotListener { [weak self] snapshot, error in
                print("Recibida actualización del juego")
                if let error = error {
                    print("Error en snapshot: \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let snapshot = snapshot,
                      let game = try? snapshot.data(as: OnlineGame.self) else {
                    print("Error: Datos del juego inválidos o no encontrados")
                    subject.send(completion: .failure(GameError.gameNotFound))
                    return
                }
                
                print("Nuevo estado del juego recibido:")
                print("- Board: \(game.board)")
                print("- Current Player: \(game.currentPlayer)")
                
                subject.send(game)
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    // Realizar un movimiento
    func makeMove(gameId: String, at position: Int, playerId: String) async throws {
        print("Intentando realizar movimiento:")
        print("- GameID: \(gameId)")
        print("- Posición: \(position)")
        print("- PlayerID: \(playerId)")
        
        let gameRef = db.collection("games").document(gameId)
        
        do {
            let game = try await gameRef.getDocument(as: OnlineGame.self)
            
            // Validaciones adicionales
            guard game.status == .inProgress else {
                throw GameError.gameFinished
            }
            
            guard game.currentPlayer == playerId else {
                print("Error de turno - Current Player: \(game.currentPlayer), Player ID: \(playerId)")
                throw GameError.notYourTurn
            }
            
            guard game.board[position] == nil else {
                throw GameError.invalidMove
            }
            
            var newBoard = game.board
            newBoard[position] = playerId
            
            // Verificar victoria
            if checkWin(newBoard, player: playerId) {
                try await gameRef.updateData([
                    "board": newBoard,
                    "status": GameStatus.finished.rawValue,
                    "winner": playerId,
                    "lastMoveTimestamp": FieldValue.serverTimestamp()
                ])
                print("¡Juego terminado! Ganador: \(playerId)")
                return
            }
            
            // Verificar empate
            if !newBoard.contains(nil) {
                try await gameRef.updateData([
                    "board": newBoard,
                    "status": GameStatus.finished.rawValue,
                    "lastMoveTimestamp": FieldValue.serverTimestamp()
                ])
                print("¡Juego terminado en empate!")
                return
            }
            
            // Si no hay victoria ni empate, continuar el juego
            let nextPlayer = (playerId == game.player1.id) ? game.player2?.id : game.player1.id
            guard let nextPlayer = nextPlayer else {
                throw GameError.gameNotFound
            }
            
            try await gameRef.updateData([
                "board": newBoard,
                "currentPlayer": nextPlayer,
                "lastMoveTimestamp": FieldValue.serverTimestamp()
            ])
            
            print("Movimiento realizado exitosamente")
            print("Nuevo estado del tablero: \(newBoard)")
            print("Siguiente jugador: \(nextPlayer)")
        } catch {
            print("Error al realizar movimiento: \(error.localizedDescription)")
            throw error
        }
    }

    private func checkWin(_ board: [String?], player: String) -> Bool {
        let winPatterns: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Horizontales
            [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Verticales
            [0, 4, 8], [2, 4, 6]              // Diagonales
        ]
        
        for pattern in winPatterns {
            if pattern.allSatisfy({ board[$0] == player }) {
                return true
            }
        }
        return false
    }
    
    // Realizar diagnóstico
    func diagnosticCheck() {
        print("Iniciando diagnóstico completo de Firestore...")
        let reference = db.collection("diagnostic").document("test")
        reference.setData(["timestamp": FieldValue.serverTimestamp()]) { error in
            if let error = error {
                print("Error de diagnóstico Firestore:")
                print("- Código de error: \(error._code)")
                print("- Dominio: \(error._domain)")
                print("- Descripción: \(error.localizedDescription)")
            } else {
                print("Diagnóstico completado exitosamente")
            }
        }
    }
    
    
    // Limpiar listeners
    func removeListener(for gameId: String) {
        print("Removiendo listener para el juego: \(gameId)")
        listeners[gameId]?.remove()
        listeners[gameId] = nil
    }
    
    deinit {
        print("Limpiando todos los listeners")
        listeners.values.forEach { $0.remove() }
    }
}
