# SnakeGame

## Overview
SnakeGame is a modern take on the classic snake game, built using SwiftUI. In this game, you control a snake on a grid, guiding it to eat food and grow longer while avoiding collisions with walls and itself. The app features smooth animations, dynamic difficulty adjustments, and high score tracking for an engaging retro gaming experience on iOS devices.

https://github.com/user-attachments/assets/91424468-8b22-4151-aaa9-d6bc6cec8463

## AI and Tools :
While making this application, I used the Vs Code insider program and combined the supported codes of the github Copilot agent with the artificial intelligence tool Claude 3.5 sonnet version.

## Features
- **Classic Snake Gameplay:**  
  Navigate the snake through a grid, eat food to grow, and avoid collisions.
- **Smooth Animations:**  
  Utilizes interpolated positions and custom easing functions for fluid snake movement.
- **Dynamic Difficulty:**  
  Game speed increases gradually as the snake grows longer.
- **High Score Tracking:**  
  Saves and displays top scores along with player names.
- **Multiple Game States:**  
  Supports different states such as ready, playing, game over, and high scores.
- **Custom UI Components:**  
  Includes custom views for the snake’s head, body, tail, food, and game board with responsive on-screen controls.

## Technologies (Architecture)
- **SwiftUI:** Used for building the declarative user interface.
- **Combine:** Manages reactive state updates.
- **MVVM Pattern:** Separates game logic (ViewModel) from UI views for a maintainable code structure.
- **UserDefaults & Codable:** Persists high scores locally.
- **Timers:** Drives game logic updates and smooth animations.

## Project Structure
- **SnakeGameViewModel.swift:**  
  Contains the core game logic including snake movement, collision detection, food spawning, score management, and timer-based game loop.
- **snakeGameApp.swift:**  
  The app’s entry point that initializes the main ContentView.
- **ContentView.swift:**  
  Switches between game states (Main Menu, Gameplay, Game Over, High Scores) and presents the appropriate view based on the current state.
- **GameViews.swift:**  
  Provides various custom SwiftUI views for rendering the game board, snake segments (head, body, tail, turns), food, and on-screen direction controls.
- **HighScoreView.swift:**  
  Displays the high score list and provides an interface for saving a new high score when achieved.
- **Models.swift:**  
  Defines the data models for the game, including Position, Direction, GameState, HighScore, and SnakeSegmentType.
- **snakeGameTests.swift:**  
  Contains unit tests for validating the game logic.
- **snakeGameUITests.swift & snakeGameUITestsLaunchTests.swift:**  
  UI tests to ensure the app launches correctly and interactions work as expected.

------------------------------------------------------------------------------------------------------------------------------------------

## Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/burak0aydin/SnakeGame

2. Open in Xcode:
- Open the .xcodeproj file in Xcode.

3. Build & Run:
- Build the project and run it on an iOS simulator or a physical device.
