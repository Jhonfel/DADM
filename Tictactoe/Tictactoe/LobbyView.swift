import SwiftUI

struct LobbyView: View {
    @StateObject private var viewModel = LobbyViewModel()
    @State private var showingCreateGame = false
    @State private var playerName = ""
    @State private var showingNameInput = true
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando juegos...")
                } else {
                    List {
                        Section(header: Text("Juegos Disponibles")) {
                            ForEach(viewModel.availableGames) { game in
                                GameRowView(game: game) {
                                    if !viewModel.isJoining {
                                        viewModel.joinGame(game)
                                    }
                                }
                            }
                            
                            if viewModel.availableGames.isEmpty {
                                Text("No hay juegos disponibles")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section(header: Text("Mis Juegos")) {
                            ForEach(viewModel.myGames) { game in
                                NavigationLink {
                                    OnlineGameView(
                                        game: game,
                                        gameId: game.id,
                                        playerId: viewModel.playerId
                                    )
                                } label: {
                                    MyGameRowView(game: game)
                                }
                            }
                            
                            if viewModel.myGames.isEmpty {
                                Text("No tienes juegos activos")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .refreshable {
                        // Permitir actualización manual con pull-to-refresh
                        await withCheckedContinuation { continuation in
                            Task {
                                await MainActor.run {
                                    viewModel.loadGames()
                                    continuation.resume()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Triqui Online")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(viewModel.playerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGame = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isJoining)
                }
            }
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView()
            }
            .sheet(isPresented: $showingNameInput) {
                PlayerNameInputView(playerName: $playerName) {
                    viewModel.setPlayerName(playerName)
                    showingNameInput = false
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isJoining {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Uniéndose al juego...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: viewModel.activeGame) { game in
            if let activeGame = game {
                let gameView = OnlineGameView(
                    game: activeGame,
                    gameId: activeGame.id,
                    playerId: viewModel.playerId
                )
                let hostingController = UIHostingController(rootView: gameView)
                UIApplication.shared.windows.first?.rootViewController?
                    .present(hostingController, animated: true)
            }
        }
    }
}
