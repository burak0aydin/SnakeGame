//
//  Models.swift
//  snakeGame
//
//  Created by Burak Aydın on 27.02.2025.
//

import Foundation

// Basic position on the game grid
struct Position: Equatable, Hashable {
    var x: Int
    var y: Int
}

// Direction of movement
enum Direction {
    case up, down, left, right
    
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

// Game states
enum GameState {
    case ready, playing, gameOver, highScores
}

// High Score record
struct HighScore: Identifiable, Codable {
    var id = UUID()
    let playerName: String
    let score: Int
    let date: Date
    
    static var sample: [HighScore] = [
        HighScore(playerName: "Player 1", score: 120, date: Date()),
        HighScore(playerName: "Player 2", score: 85, date: Date().addingTimeInterval(-86400)),
        HighScore(playerName: "Player 3", score: 70, date: Date().addingTimeInterval(-172800))
    ]
}

// Snake segment appearance types
enum SnakeSegmentType {
    case head
    case body
    case turn
    case tail
    
    // Used for determining appropriate snake segment appearance
    static func determineType(for index: Int, in snake: [Position]) -> (type: SnakeSegmentType, direction: Direction?) {
        if snake.count <= 1 {
            return (type: .head, direction: nil)
        }
        
        if index == 0 {
            // Head segment
            return (type: .head, direction: directionBetween(snake[0], snake[1]))
        } else if index == snake.count - 1 {
            // Tail segment
            return (type: .tail, direction: directionBetween(snake[index], snake[index - 1]))
        } else {
            // Body segment - determine if it's a turn
            let prevDirection = directionBetween(snake[index], snake[index - 1])
            let nextDirection = directionBetween(snake[index], snake[index + 1])
            
            if prevDirection != nextDirection?.opposite {
                return (type: .turn, direction: nil) // Turn segments have special appearance
            } else {
                return (type: .body, direction: prevDirection)
            }
        }
    }
    
    // Helper to determine direction between two positions
    private static func directionBetween(_ from: Position, _ to: Position) -> Direction? {
        if from.x < to.x { return .left }
        if from.x > to.x { return .right }
        if from.y < to.y { return .up }
        if from.y > to.y { return .down }
        return nil
    }
}