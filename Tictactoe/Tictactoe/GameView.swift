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
                
                if viewModel.isGameOver {
                    Button("Jugar de nuevo") {
                        withAnimation {
                            viewModel.resetGame()
                        }
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.scale)
                    .animation(.easeInOut, value: viewModel.isGameOver)
                }
                
                Spacer()
            }
        }
    }
}
