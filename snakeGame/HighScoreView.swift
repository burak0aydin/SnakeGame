//
//  HighScoreView.swift
//  snakeGame
//
//  Created by Burak Aydın on 27.02.2025.
//

import SwiftUI

struct HighScoresView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    @State private var isShowingNewScoreSheet = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.85, green: 0.85, blue: 0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Top Scores")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                    .shadow(color: .white, radius: 1, x: 1, y: 1)
                    .padding(.top)
                
                // High scores list
                ScrollView {
                    VStack(spacing: 10) {
                        // Header row
                        HStack {
                            Text("Rank")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("Player")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Score")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        
                        // Score rows
                        ForEach(Array(viewModel.highScores.enumerated()), id: \.element.id) { index, score in
                            HStack {
                                // Rank with medal for top 3
                                ZStack {
                                    if index < 3 {
                                        Circle()
                                            .fill(medalColor(for: index))
                                            .frame(width: 30, height: 30)
                                        
                                        Text("\(index + 1)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 60, alignment: .leading)
                                
                                Text(score.playerName)
                                    .font(.body)
                                    .fontWeight(index < 3 ? .semibold : .regular)
                                    .foregroundColor(index < 3 ? .black : .gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(score.score)")
                                    .font(.system(size: 18, weight: index < 3 ? .bold : .semibold))
                                    .foregroundColor(index < 3 ? .purple : .gray)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(index % 2 == 0 ? Color.white.opacity(0.7) : Color.white.opacity(0.5))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .shadow(radius: 5)
                )
                .padding()
                
                // Back button
                Button(action: { viewModel.returnToMainMenu() }) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title2)
                        Text("Back to Menu")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(15)
                    .shadow(radius: 3)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingNewScoreSheet) {
            NewScoreView(viewModel: viewModel, isPresented: $isShowingNewScoreSheet)
        }
    }
    
    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.yellow // Gold
        case 1: return Color(red: 0.8, green: 0.8, blue: 0.85) // Silver
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color.gray
        }
    }
}

struct NewScoreView: View {
    @ObservedObject var viewModel: SnakeGameViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New High Score!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Score: \(viewModel.score)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            
            TextField("Enter Your Name", text: $viewModel.playerName)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            Button("Save Score") {
                viewModel.saveHighScore()
                isPresented = false
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.playerName.isEmpty)
            .opacity(viewModel.playerName.isEmpty ? 0.5 : 1.0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(15)
    }
}