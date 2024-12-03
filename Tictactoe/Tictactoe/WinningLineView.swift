import SwiftUI

struct WinningLineView: Shape {
    let line: [Int]
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard line.count >= 2 else { return path }
        
        let cellWidth = rect.width / 3
        let cellHeight = rect.height / 3
        
        // Calcular puntos inicial y final
        let startIndex = line.first!
        let endIndex = line.last!
        
        let startX = (CGFloat(startIndex % 3) * cellWidth) + (cellWidth / 2)
        let startY = (CGFloat(startIndex / 3) * cellHeight) + (cellHeight / 2)
        let endX = (CGFloat(endIndex % 3) * cellWidth) + (cellWidth / 2)
        let endY = (CGFloat(endIndex / 3) * cellHeight) + (cellHeight / 2)
        
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: endX, y: endY))
        
        return path
    }
}
