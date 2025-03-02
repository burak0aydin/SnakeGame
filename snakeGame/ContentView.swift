//
//  ContentView.swift
//  snakeGame
//
//  Created by Burak Aydın on 27.02.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SnakeGameViewModel()
    @State private var showNewScoreEntry = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.85, green: 0.85, blue: 0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Content based on game state
            switch viewModel.gameState {
            case .ready:
                MainMenuView(viewModel: viewModel)
                
            case .playing:
                GamePlayView(viewModel: viewModel)
                
            case .gameOver:
                GameOverView(viewModel: viewModel, showNewScoreEntry: $showNewScoreEntry)
                    .onAppear {
                        // Check if the score is high enough for the high scores
                        if viewModel.highScores.count < 10 || viewModel.score > (viewModel.highScores.last?.score ?? 0) {
                            showNewScoreEntry = true
                        }
                    }
                    .sheet(isPresented: $showNewScoreEntry) {
                        NewScoreView(viewModel: viewModel, isPresented: $showNewScoreEntry)
                    }
                
            case .highScores:
                HighScoresView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Game View Components

struct MainMenuView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    @State private var isAnimatingTitle = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Game title
            VStack(spacing: 10) {
                Text("Snake Game")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.6, blue: 0.1),
                                Color(red: 0.0, green: 0.4, blue: 0.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white, radius: 2, x: 1, y: 1)
                    .scaleEffect(isAnimatingTitle ? 1.0 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimatingTitle
                    )
                    .onAppear {
                        isAnimatingTitle = true
                    }
                
                Text("🐍")
                    .font(.system(size: 70))
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Menu buttons
            VStack(spacing: 20) {
                MenuButton(title: "Start Game", color: .green) {
                    viewModel.startGame()
                }
                
                MenuButton(title: "High Scores", color: .blue) {
                    viewModel.showHighScores()
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct GamePlayView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Game header
            VStack(spacing: 0) {
                Text("Snake Game")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.2))
                    .shadow(color: .white, radius: 1, x: 1, y: 1)
                
                Text("Score: \(viewModel.score)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    )
            }
            .padding(.top)
            
            // Game board
            GameBoardView(viewModel: viewModel)
                .padding()
            
            // Direction controls
            DirectionControlView(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
    }
}

struct GameOverView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    @Binding var showNewScoreEntry: Bool
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Game Over!")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundColor(.red)
                .shadow(radius: 2)
                .rotation3DEffect(.degrees(animationAmount), axis: (x: 0, y: 1, z: 0))
                .onAppear {
                    withAnimation(.interpolatingSpring(stiffness: 50, damping: 8)) {
                        animationAmount = 360
                    }
                }
            
            Text("Final Score: \(viewModel.score)")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.primary)
            
            // Statistics card
            VStack(spacing: 10) {
                StatisticRow(label: "Snake Length", value: "\(viewModel.snake.count) segments")
                StatisticRow(label: "Apples Eaten", value: "\(viewModel.score / 10)")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.7))
                    .shadow(radius: 5)
            )
            .padding(.horizontal)
            
            // Action buttons
            VStack(spacing: 15) {
                if !showNewScoreEntry && (viewModel.highScores.count < 10 || viewModel.score > (viewModel.highScores.last?.score ?? 0)) {
                    Button(action: {
                        showNewScoreEntry = true
                    }) {
                        HStack {
                            Image(systemName: "trophy.fill")
                            Text("Save High Score")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.yellow)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                    }
                }
                
                Button(action: { viewModel.startGame() }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Play Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                }
                
                Button(action: { viewModel.returnToMainMenu() }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Main Menu")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                }
                
                Button(action: { viewModel.showHighScores() }) {
                    HStack {
                        Image(systemName: "list.number")
                        Text("High Scores")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250)
                    .background(Color.purple)
                    .cornerRadius(15)
                    .shadow(radius: 3)
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .frame(width: 250)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .shadow(radius: 5)
        }
    }
}

struct StatisticRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
