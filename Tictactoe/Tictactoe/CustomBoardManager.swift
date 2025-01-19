import SwiftUI

struct CellContent<T: ObservableObject>: View {
    let index: Int
    @ObservedObject var viewModel: T
    
    init(for index: Int, in viewModel: T) {
        self.index = index
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
            
            if let player = (viewModel as? GameViewModel)?.moves[index] {
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
            } else if let player = (viewModel as? OnlineBoardViewModel)?.moves[index] {
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

struct BoardGridView<T: ObservableObject>: View {
    let geometry: GeometryProxy
    @ObservedObject var viewModel: T
    let onPositionTapped: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        Button(action: {
                            onPositionTapped?(index)
                        }) {
                            CellContent(for: index, in: viewModel)
                        }
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

struct CustomBoardView<T: ObservableObject>: View {
    @ObservedObject var viewModel: T
    var onPositionTapped: ((Int) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GridBackground()
                BoardGridView(
                    geometry: geometry,
                    viewModel: viewModel,
                    onPositionTapped: { position in
                        if let gameVM = viewModel as? GameViewModel {
                            gameVM.processMove(for: position)
                        } else {
                            onPositionTapped?(position)
                        }
                    }
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
