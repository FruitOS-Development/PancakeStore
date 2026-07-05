import SwiftUI

struct DownloadOverlayView: View {
    @ObservedObject var manager = DownloadManager.shared
    
    @State private var snake = [CGPoint(x: 5, y: 10), CGPoint(x: 4, y: 10)]
    @State private var food = CGPoint(x: 15, y: 10)
    @State private var direction = CGPoint(x: 1, y: 0)
    @State private var gameOver = false
    
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    let gridSize: CGFloat = 15
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 12) {
                Text(manager.currentPhase.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                ProgressView(value: manager.progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .padding(.horizontal, 40)
                
                Text("\(Int(manager.progress * 100))% • \(manager.estimatedTimeRemaining)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Wartezeit überbrücken:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                GeometryReader { geo in
                    ZStack {
                        Color(white: 0.05).cornerRadius(12)
                            .border(Color.white.opacity(0.1), width: 1)
                        
                        Circle()
                            .fill(.red)
                            .frame(width: gridSize, height: gridSize)
                            .position(x: food.x * gridSize + gridSize/2, y: food.y * gridSize + gridSize/2)
                        
                        ForEach(0..<snake.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == 0 ? Color.green : Color.green.opacity(0.7))
                                .frame(width: gridSize, height: gridSize)
                                .position(x: snake[index].x * gridSize + gridSize/2, y: snake[index].y * gridSize + gridSize/2)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { gesture in
                                let h = gesture.translation.width
                                let v = gesture.translation.height
                                if abs(h) > abs(v) {
                                    if h > 0 && direction.x == 0 { direction = CGPoint(x: 1, y: 0) }
                                    else if h < 0 && direction.x == 0 { direction = CGPoint(x: -1, y: 0) }
                                } else {
                                    if v > 0 && direction.y == 0 { direction = CGPoint(x: 0, y: 1) }
                                    else if v < 0 && direction.y == 0 { direction = CGPoint(x: 0, y: -1) }
                                }
                            }
                    )
                }
                .frame(width: 300, height: 300)
                .onReceive(timer) { _ in
                    guard !gameOver else { return }
                    updateSnake()
                }
                
                if gameOver {
                    Button("Erneut versuchen") {
                        snake = [CGPoint(x: 5, y: 10), CGPoint(x: 4, y: 10)]
                        food = CGPoint(x: Int.random(in: 1...18), y: Int.random(in: 1...18))
                        direction = CGPoint(x: 1, y: 0)
                        gameOver = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .padding(.top, 5)
                }
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.95))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func updateSnake() {
        var newHead = CGPoint(x: snake[0].x + direction.x, y: snake[0].y + direction.y)
        
        if newHead.x < 0 { newHead.x = 19 }
        if newHead.x >= 20 { newHead.x = 0 }
        if newHead.y < 0 { newHead.y = 19 }
        if newHead.y >= 20 { newHead.y = 0 }
        
        if snake.contains(newHead) {
            gameOver = true
            return
        }
        
        snake.insert(newHead, at: 0)
        
        if newHead == food {
            food = CGPoint(x: Int.random(in: 1...18), y: Int.random(in: 1...18))
        } else {
            snake.removeLast()
        }
    }
}
