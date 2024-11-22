//
//  GameView.swift
//  Tictactoe
//
//  Created by Jhon Felipe Delgado on 16/11/24.
//
// GameView.swift
// GameView.swift
import SwiftUI
struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingDifficultyPicker = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Text("TicTacToe swift DADM 2024-2")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Text(viewModel.statusText)
                    .font(.title2)
                    .bold()
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                    ForEach(0..<9) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.blue.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                            
                            if let player = viewModel.moves[index] {
                                Text(player.indicator)
                                    .font(.system(size: 50))
                                    .bold()
                                    .foregroundColor(player == .x ? .red : .blue)
                                    .transition(.scale.combined(with: .opacity))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.moves[index])
                                    .rotationEffect(.degrees(viewModel.moves[index] != nil ? 360 : 0))
                            }
                        }
                        .onTapGesture {
                            withAnimation {
                                viewModel.processMove(for: index)
                            }
                        }
                    }
                }
                .padding()
                .disabled(viewModel.isGameOver)
                
                Spacer()
                
                HStack(spacing: 20) {
                    // Botón Nuevo Juego
                    Button(action: {
                        withAnimation {
                            viewModel.resetGame()
                        }
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 30))
                            Text("Nuevo")
                                .font(.system(size: 11))
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                    
                    // Botón Dificultad
                    Button(action: {
                        showingDifficultyPicker = true
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 30))
                            Text("Nivel")
                                .font(.system(size: 11))
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    
                    // Botón Salir
                    Button(action: {
                        exit(0)
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 30))
                            Text("Salir")
                                .font(.system(size: 11))
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .confirmationDialog("Seleccionar Dificultad",
                          isPresented: $showingDifficultyPicker,
                          titleVisibility: .visible) {
            Button("Fácil") { viewModel.setDifficulty(.easy) }
            Button("Medio") { viewModel.setDifficulty(.medium) }
            Button("Difícil") { viewModel.setDifficulty(.hard) }
        }
    }
}
