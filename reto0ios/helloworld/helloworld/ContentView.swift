
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var mostrarSaludo = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(mostrarSaludo ? "¡Hola Mundo!" : "Bienvenido")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
                .animation(.spring(), value: mostrarSaludo)
            
            Button(action: {
                withAnimation {
                    mostrarSaludo.toggle()
                }
            }) {
                Text(mostrarSaludo ? "Ocultar Saludo" : "Mostrar Saludo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
