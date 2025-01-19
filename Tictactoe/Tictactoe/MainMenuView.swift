import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Título
                Text("Triqui DADM")
                    .font(.largeTitle)
                    .bold()
                
                // Logo o imagen
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                // Botones de modo de juego
                VStack(spacing: 20) {
                    NavigationLink {
                        GameView()
                    } label: {
                        MenuButton(
                            title: "Modo Local",
                            subtitle: "Juega contra la computadora",
                            icon: "person.fill")
                    }
                    
                    NavigationLink {
                        LobbyView()
                    } label: {
                        MenuButton(
                            title: "Modo Online",
                            subtitle: "Juega contra otros jugadores",
                            icon: "network")
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    MainMenuView()
}
