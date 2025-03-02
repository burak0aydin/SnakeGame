//
//  GameViews.swift
//  snakeGame
//
//  Created by Burak Aydın on 27.02.2025.
//

import SwiftUI

// MARK: - Snake Segment Views

struct SnakeSegmentView: View {
    let index: Int
    let snake: [Position]
    let size: CGFloat
    let progress: Double
    let turnPoints: [Int: Direction]
    
    var body: some View {
        // İndeks için dönüş noktası kontrolü yap
        let isTurnPoint = turnPoints[index] != nil
        let segmentInfo = SnakeSegmentType.determineType(for: index, in: snake)
        
        return Group {
            switch segmentInfo.type {
            case .head:
                SnakeHeadView(direction: segmentInfo.direction, size: size)
            case .tail:
                SnakeTailView(direction: segmentInfo.direction, size: size)
            case .turn:
                // Dönüş noktalarında özel görünüm kullan
                if isTurnPoint {
                    SnakeTurnSegmentView(
                        direction: turnPoints[index],
                        prevDirection: segmentInfo.direction,
                        size: size,
                        progress: progress
                    )
                } else {
                    SnakeTurnView(position: snake[index], prev: index > 0 ? snake[index-1] : nil, next: index < snake.count - 1 ? snake[index+1] : nil, size: size)
                }
            case .body:
                SnakeBodyView(direction: segmentInfo.direction, size: size)
            }
        }
    }
}

struct SnakeHeadView: View {
    let direction: Direction?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Base head shape
            RoundedRectangle(cornerRadius: size / 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.6, blue: 0.1),
                            Color(red: 0.0, green: 0.4, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size / 3)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
            
            // Eyes
            HStack(spacing: size / 6) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size / 4, height: size / 4)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: size / 8)
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size / 4, height: size / 4)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: size / 8)
                    )
            }
            .offset(y: -size / 8)
            .rotationEffect(rotationAngle)
        }
        .frame(width: size - 2, height: size - 2)
        .rotationEffect(rotationAngle)
    }
    
    private var rotationAngle: Angle {
        switch direction {
        case .up: return .degrees(0)
        case .down: return .degrees(180)
        case .left: return .degrees(-90)
        case .right: return .degrees(90)
        case .none: return .degrees(0)
        }
    }
}

struct SnakeBodyView: View {
    let direction: Direction?
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: size / 5)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.0, green: 0.55, blue: 0.0),
                        Color(red: 0.0, green: 0.4, blue: 0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                ZStack {
                    // Scales pattern
                    RoundedRectangle(cornerRadius: size / 5)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                    
                    if isVertical {
                        // Vertical scale lines
                        VStack(spacing: size / 5) {
                            ForEach(0..<3) { _ in
                                Capsule()
                                    .fill(Color(red: 0.0, green: 0.3, blue: 0.0))
                                    .frame(width: size * 0.7, height: size / 10)
                            }
                        }
                    } else {
                        // Horizontal scale lines
                        HStack(spacing: size / 5) {
                            ForEach(0..<3) { _ in
                                Capsule()
                                    .fill(Color(red: 0.0, green: 0.3, blue: 0.0))
                                    .frame(width: size / 10, height: size * 0.7)
                            }
                        }
                    }
                }
            )
            .frame(width: size - 2, height: size - 2)
            .rotationEffect(rotationAngle)
    }
    
    private var isVertical: Bool {
        direction == .up || direction == .down
    }
    
    private var rotationAngle: Angle {
        switch direction {
        case .up, .down: return .degrees(0)
        case .left, .right: return .degrees(90)
        case .none: return .degrees(0)
        }
    }
}

struct SnakeTailView: View {
    let direction: Direction?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.5, blue: 0.0),
                            Color(red: 0.0, green: 0.3, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                )
                .frame(width: size * 0.7, height: size - 2)
        }
        .rotationEffect(rotationAngle)
    }
    
    private var rotationAngle: Angle {
        switch direction {
        case .up: return .degrees(180)
        case .down: return .degrees(0)
        case .left: return .degrees(90)
        case .right: return .degrees(-90)
        case .none: return .degrees(0)
        }
    }
}

// Özel dönüş segmenti görünümü
struct SnakeTurnSegmentView: View {
    let direction: Direction?
    let prevDirection: Direction?
    let size: CGFloat
    let progress: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size / 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.5, blue: 0.0),
                            Color(red: 0.0, green: 0.38, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size / 4)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.8)
                )
                .scaleEffect(getScaleEffect())
        }
        .frame(width: size - 2, height: size - 2)
        .rotationEffect(getRotationAngle())
    }
    
    private func getScaleEffect() -> CGSize {
        // Dönüş sırasında hafif bir "şişme" efekti ekle
        let scale = 1.0 + 0.1 * sin(Double.pi * progress)
        return CGSize(width: scale, height: scale)
    }
    
    private func getRotationAngle() -> Angle {
        // Dönüş yönüne dayalı rotasyon açısı hesapla
        guard let dir = direction, let prevDir = prevDirection else {
            return .degrees(0)
        }
        
        switch (prevDir, dir) {
        case (.up, .right): return .degrees(45)
        case (.up, .left): return .degrees(-45)
        case (.down, .right): return .degrees(135)
        case (.down, .left): return .degrees(-135)
        case (.left, .up): return .degrees(45)
        case (.left, .down): return .degrees(135)
        case (.right, .up): return .degrees(-45)
        case (.right, .down): return .degrees(-135)
        default: return .degrees(0)
        }
    }
}

struct SnakeTurnView: View {
    let position: Position
    let prev: Position?
    let next: Position?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size / 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.5, blue: 0.0),
                            Color(red: 0.0, green: 0.35, blue: 0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size / 4)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                )
        }
        .frame(width: size - 2, height: size - 2)
    }
}

// MARK: - Food View

struct FoodView: View {
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Apple body
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.red, .red.opacity(0.7)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
            
            // Apple shine
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size / 3)
                .offset(x: -size / 8, y: -size / 8)
            
            // Apple stem
            Rectangle()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.0))
                .frame(width: size / 8, height: size / 4)
                .offset(y: -size / 2.5)
            
            // Apple leaf
            Image(systemName: "leaf.fill")
                .foregroundColor(Color.green)
                .font(.system(size: size / 2.5))
                .offset(x: size / 8, y: -size / 2)
        }
        .frame(width: size - 3, height: size - 3)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(
            Animation.easeInOut(duration: 0.7)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Game Board View

struct GameBoardView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    
    var body: some View {
        ZStack {
            // Background grid
            VStack(spacing: 0) {
                ForEach(0..<viewModel.gridSize, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<viewModel.gridSize, id: \.self) { column in
                            Rectangle()
                                .fill((row + column).isMultiple(of: 2) 
                                      ? Color(red: 0.8, green: 0.9, blue: 0.8).opacity(0.3) 
                                      : Color(red: 0.7, green: 0.8, blue: 0.7).opacity(0.3))
                                .frame(width: viewModel.cellSize, height: viewModel.cellSize)
                        }
                    }
                }
            }
            .background(Color(red: 0.9, green: 1.0, blue: 0.9).opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.7), .green.opacity(0.3)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            
            // Snake body with smooth animation using interpolated positions
            ForEach(0..<viewModel.snake.count, id: \.self) { index in
                if index < viewModel.animatedSnakePositions.count {
                    SnakeSegmentView(
                        index: index,
                        snake: viewModel.snake,
                        size: viewModel.cellSize,
                        progress: viewModel.snakeAnimationProgress,
                        turnPoints: viewModel.turnPoints
                    )
                    .position(
                        x: viewModel.animatedSnakePositions[index].x * viewModel.cellSize - viewModel.cellSize / 2,
                        y: viewModel.animatedSnakePositions[index].y * viewModel.cellSize - viewModel.cellSize / 2
                    )
                    .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: viewModel.animatedSnakePositions)
                }
            }
            
            // Food with animation
            FoodView(size: viewModel.cellSize)
                .position(
                    x: CGFloat(viewModel.food.x) * viewModel.cellSize - viewModel.cellSize / 2,
                    y: CGFloat(viewModel.food.y) * viewModel.cellSize - viewModel.cellSize / 2
                )
                .animation(.spring(), value: viewModel.food)
        }
        .frame(
            width: CGFloat(viewModel.gridSize) * viewModel.cellSize,
            height: CGFloat(viewModel.gridSize) * viewModel.cellSize
        )
        .clipped()
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Control Views

struct DirectionControlView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    @State private var isPressingUp = false
    @State private var isPressingDown = false
    @State private var isPressingLeft = false
    @State private var isPressingRight = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { 
                viewModel.setDirection(.up)
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressingUp = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isPressingUp = false
                    }
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPressingUp ? 0.9 : 1.0)
                    .shadow(color: .blue.opacity(0.3), radius: isPressingUp ? 2 : 5, x: 0, y: isPressingUp ? 1 : 2)
            }
            
            HStack(spacing: 50) {
                Button(action: { 
                    viewModel.setDirection(.left)
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressingLeft = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            isPressingLeft = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressingLeft ? 0.9 : 1.0)
                        .shadow(color: .blue.opacity(0.3), radius: isPressingLeft ? 2 : 5, x: 0, y: isPressingLeft ? 1 : 2)
                }
                
                Button(action: { 
                    viewModel.setDirection(.right)
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressingRight = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            isPressingRight = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressingRight ? 0.9 : 1.0)
                        .shadow(color: .blue.opacity(0.3), radius: isPressingRight ? 2 : 5, x: 0, y: isPressingRight ? 1 : 2)
                }
            }
            
            Button(action: { 
                viewModel.setDirection(.down)
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressingDown = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isPressingDown = false
                    }
                }
            }) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPressingDown ? 0.9 : 1.0)
                    .shadow(color: .blue.opacity(0.3), radius: isPressingDown ? 2 : 5, x: 0, y: isPressingDown ? 1 : 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.5), .gray.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}