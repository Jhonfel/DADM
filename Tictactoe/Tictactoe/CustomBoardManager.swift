import SwiftUI

struct CustomBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                GridBackground()
                
                // Celdas del juego
                VStack(spacing: 0) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<3) { column in
                                let index = row * 3 + column
                                CellView(index: index, viewModel: viewModel)
                                    .frame(
                                        width: geometry.size.width/3,
                                        height: geometry.size.height/3
                                    )
                            }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Línea vertical 1
                path.move(to: CGPoint(x: geometry.size.width/3, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width/3, y: geometry.size.height))
                
                // Línea vertical 2
                path.move(to: CGPoint(x: 2 * geometry.size.width/3, y: 0))
                path.addLine(to: CGPoint(x: 2 * geometry.size.width/3, y: geometry.size.height))
                
                // Línea horizontal 1
                path.move(to: CGPoint(x: 0, y: geometry.size.height/3))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height/3))
                
                // Línea horizontal 2
                path.move(to: CGPoint(x: 0, y: 2 * geometry.size.height/3))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 2 * geometry.size.height/3))
            }
            .stroke(Color.gray, lineWidth: 2)
        }
    }
}

struct CellView: View {
    let index: Int
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                viewModel.processMove(for: index)
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.white)
                
                if let player = viewModel.moves[index] {
                    Group {
                        if player == .x {
                            Image(systemName: "xmark")
                                .resizable()
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "circle")
                                .resizable()
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}
