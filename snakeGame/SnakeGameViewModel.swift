//
//  SnakeGameViewModel.swift
//  snakeGame
//
//  Created by Burak Aydın on 27.02.2025.
//

import SwiftUI
import Combine

class SnakeGameViewModel: ObservableObject {
    // Game configuration
    let gridSize = 20
    let cellSize: CGFloat = 18
    
    // Published properties for UI updates
    @Published var gameState = GameState.ready
    @Published var snake: [Position] = [Position(x: 10, y: 10)]
    @Published var direction = Direction.right
    @Published var food = Position(x: 5, y: 5)
    @Published var score = 0
    @Published var highScores: [HighScore] = []
    @Published var playerName = ""
    @Published var snakeAnimationProgress: Double = 0
    
    // Snake interpolated positions for smooth animation
    @Published var animatedSnakePositions: [CGPoint] = []
    @Published var turnPoints: [Int: Direction] = [:] // Pozisyonda yapılan dönüşleri izler
    
    // Game settings
    private var gameSpeed = 0.3  // Base speed for game logic
    private var displayRefreshRate = 1.0 / 60.0  // 60 FPS for smooth visuals
    private var timer: Timer?
    private var animationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: Date = Date()
    private var hasFirstUpdateOccurred = false
    
    // Direction queue to make controls more responsive
    private var directionQueue: [Direction] = []
    private var nextMoveTime: Date = Date()
    private var turnProgress: Double = 0.0
    private var isTurning = false
    private var currentTurnDirection: Direction?
    private var previousDirection: Direction?
    
    // Yön değişimine anında tepki vermek için
    private var immediateResponseThreshold = 0.3 // Yön değişiminin hangi noktada anında uygulanacağını belirler
    
    // High score key for UserDefaults
    private let highScoresKey = "HighScores"
    
    init() {
        loadHighScores()
        spawnFood()
        setupInitialAnimatedPositions()
        
        // Precompute next head position for smooth initial animation
        precomputeNextPositions()
    }
    
    private func setupInitialAnimatedPositions() {
        animatedSnakePositions = snake.map { position in
            CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
        }
    }
    
    // Precompute positions for smooth animation at game start
    private func precomputeNextPositions() {
        // Only needed for single segment snake at game start
        if snake.count == 1 {
            let head = snake[0]
            var nextHeadPos = Position(x: head.x, y: head.y)
            
            switch direction {
            case .up:
                nextHeadPos.y -= 1
            case .down:
                nextHeadPos.y += 1
            case .left:
                nextHeadPos.x -= 1
            case .right:
                nextHeadPos.x += 1
            }
            
            // Ani ışınlanmayı önlemek için yavaş bir geçiş kullan
            // Pre-add the target position to snake array temporarily
            // but don't change the visual position immediately
            animatedSnakePositions = [CGPoint(x: CGFloat(head.x), y: CGFloat(head.y))]
        }
    }
    
    // MARK: - Game Control Methods
    
    func setDirection(_ newDirection: Direction) {
        // Prevent 180-degree turns which would cause immediate game over
        if newDirection == direction.opposite {
            return
        }
        
        // If the same direction is already queued or set, don't add it
        if (!directionQueue.isEmpty && directionQueue.last == newDirection) || newDirection == direction {
            return
        }
        
        // Hızlı tepki için: Eğer hareket ilerlemesi değiştirilebilir bir noktadaysa, yönü hemen değiştir
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        let progressToNextUpdate = min(1.0, timeSinceLastUpdate / gameSpeed)
        
        // Hareketi uygulamak için:
        // 1. Eğer yılan hareket başlangıcındaysa (ilerlemedeki ilk %30 içinde)
        // 2. ya da hareketin sonuna doğru yaklaşıyorsak (son %30'da)
        // hemen yön değiştir
        if progressToNextUpdate < immediateResponseThreshold || progressToNextUpdate > (1.0 - immediateResponseThreshold) {
            // Daha önce bir yön değişimi kuyruktaysa, onu temizle
            directionQueue.removeAll()
            
            // Önceki durumu kaydet ve hemen değiştir
            previousDirection = direction
            direction = newDirection
            
            // Başlangıç animasyonunu hızlandır
            isTurning = true
            turnProgress = progressToNextUpdate < 0.5 ? 0.0 : 0.7
            currentTurnDirection = newDirection
            
            // Turn point ekle - baş için
            if let headIndex = snake.firstIndex(where: { $0 == snake[0] }) {
                turnPoints[headIndex] = newDirection
            }
            return
        }
        
        // Standart yön değiştirme mantığı
        let queueSize = directionQueue.count
        
        // Yeni bir dönüş başlatın
        if !isTurning && queueSize == 0 {
            previousDirection = direction
            currentTurnDirection = newDirection
            isTurning = true
            turnProgress = 0.0
        }
        
        // Hızlı tepki için: En fazla 1 yön değişimini kuyruğa ekle, 
        // ve hemen uygula
        directionQueue = [newDirection]
        
        // Turn point ekle - baş için
        if let headIndex = snake.firstIndex(where: { $0 == snake[0] }) {
            turnPoints[headIndex] = newDirection
        }
    }
    
    func startGame() {
        // Önce oyun durumunu sıfırla ve gerekli ayarlamaları yap
        resetGame(keepHighScores: false)
        
        // Ardından oyun durumunu güncelle (önemli: bu sıra kritik)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.gameState = .playing
            
            // Force initial animation state for smooth starting movement
            self.hasFirstUpdateOccurred = false
            self.lastUpdateTime = Date()
            self.snakeAnimationProgress = 0
            
            // Start both the game logic and animation loops
            self.startGameLoop()
            
            // Force initial animation update for immediate smooth movement
            self.updateAnimation()
            
            // Oyun başlangıcında yumuşak geçiş için hazırlık
            self.smoothInitialAnimation()
            
            print("Oyun başlatıldı! Game State: \(self.gameState)")
        }
    }

    // Yumuşak başlangıç animasyonu için metot
    private func smoothInitialAnimation() {
        if snake.count == 1 {
            // Yılanın başlangıç konumunu ayarla
            let headPos = snake[0]
            
            // Ani ışınlanma sorununu çözmek için kademeli geçiş ayarla
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self, self.gameState == .playing else { return }
                self.snakeAnimationProgress = 0.01 // Çok küçük bir değerle başlat
                self.updateAnimation()
            }
        }
    }

    func resetGame(keepHighScores: Bool = false) {
        // Yılanın başlangıç konumunu güvenli bir şekilde grid ortasına ayarla
        // 10 değeri sınır kontrolleri için güvenli bir başlangıç pozisyonu
        snake = [Position(x: 10, y: 10)]
        
        setupInitialAnimatedPositions()
        direction = .right
        directionQueue.removeAll()
        hasFirstUpdateOccurred = false
        isTurning = false
        turnProgress = 0.0
        currentTurnDirection = nil
        previousDirection = nil
        turnPoints.removeAll()
        
        // Skoru sıfırla, yeni oyunda eski skor devam etmemesi için
        score = 0
        
        gameSpeed = 0.3
        timer?.invalidate()
        animationTimer?.invalidate()
        
        // Yiyeceği yılanla çakışmayacak şekilde yeniden yerleştir
        spawnFood()
        
        if !keepHighScores {
            // Burada gameState'i direkt değiştirmiyoruz, startGame fonksiyonu içinde değiştiriyoruz
        }
        
        lastUpdateTime = Date()
        // İlk hareketin gecikmesini artır - oyuncuya hazırlanma süresi ver
        nextMoveTime = Date().addingTimeInterval(gameSpeed * 1.5)
        
        // Precompute next positions for smooth animation
        precomputeNextPositions()
    }

    // İlk hareket için özel bir başlangıç kontrolü ekle
    private func startGameLoop() {
        // Cancel any existing timers
        timer?.invalidate()
        animationTimer?.invalidate()
        
        // Set initial game timing
        lastUpdateTime = Date()
        nextMoveTime = Date().addingTimeInterval(gameSpeed)
        
        // Create a more frequent animation timer for smooth rendering
        animationTimer = Timer.scheduledTimer(withTimeInterval: displayRefreshRate, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
        RunLoop.current.add(animationTimer!, forMode: .common)
        
        // Game logic timer'ı hemen başlat, UI'da gecikme yaratmadan
        timer = Timer.scheduledTimer(withTimeInterval: displayRefreshRate, repeats: true) { [weak self] _ in
            self?.checkGameLogic()
        }
        RunLoop.current.add(timer!, forMode: .common)
            
        print("Game loop started! Current game state: \(gameState)")
    }
    
    func showHighScores() {
        gameState = .highScores
    }
    
    func returnToMainMenu() {
        gameState = .ready
    }
    
    func saveHighScore() {
        let name = playerName.isEmpty ? "Anonymous" : playerName
        let newScore = HighScore(playerName: name, score: score, date: Date())
        
        highScores.append(newScore)
        highScores.sort { $0.score > $1.score }
        
        // Keep only top 10 scores
        if highScores.count > 10 {
            highScores = Array(highScores.prefix(10))
        }
        
        saveHighScores()
        playerName = ""
    }
    
    // MARK: - Game Logic
    
    private func checkGameLogic() {
        let now = Date()
        
        // Dönüş yapmak için mantık kontrol et
        if isTurning {
            // Dönüş ilerleme durumunu güncelle - daha hızlı tepki için dönüşü hızlandır
            turnProgress += displayRefreshRate / (gameSpeed * 0.4) // Daha hızlı dönüş için 0.7 yerine 0.4
            
            // Dönüş tamamlandı mı?
            if turnProgress >= 1.0 {
                if let newDir = currentTurnDirection {
                    direction = newDir
                }
                isTurning = false
                turnProgress = 0.0
                
                // Artık ilk yön değişimini kuyruktan kaldır
                if !directionQueue.isEmpty {
                    directionQueue.removeFirst()
                }
            }
        }
        // Normal yön değişimi kontrolü - daha erken başla
        // gameSpeed * 0.5 yerine gameSpeed * 0.7 kullanarak daha erken tepki vermeyi sağla
        else if !directionQueue.isEmpty && now >= nextMoveTime.addingTimeInterval(-gameSpeed * 0.7) {
            previousDirection = direction
            currentTurnDirection = directionQueue.first
            direction = currentTurnDirection! // Hemen yönü değiştir
            isTurning = true
            turnProgress = 0.3 // İlerlemeyi başlat
        }
        
        // Check if it's time for the next game logic update
        if now >= nextMoveTime {
            updateGame()
            nextMoveTime = now.addingTimeInterval(gameSpeed)
        }
    }
    
    private func updateAnimation() {
        // Calculate how far between game logic steps we are (0.0 to 1.0)
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        let progressToNextUpdate = min(1.0, timeSinceLastUpdate / gameSpeed)
        
        // For the first frame after game start, ensure we have a proper animation
        if !hasFirstUpdateOccurred && gameState == .playing {
            snakeAnimationProgress = 0.01 // Start with a small value to trigger interpolation
        } else {
            snakeAnimationProgress = progressToNextUpdate
        }
        
        // Update animated positions based on progress
        updateAnimatedPositions(progress: snakeAnimationProgress)
    }
    
    private func updateAnimatedPositions(progress: Double) {
        // Ensure we have enough animated positions
        if animatedSnakePositions.count != snake.count {
            animatedSnakePositions = snake.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        }
        
        // Special case for single segment snake at game start - smooth initial animation
        if snake.count == 1 && !hasFirstUpdateOccurred && gameState == .playing {
            // For the head, interpolate towards the next position based on current direction
            let head = snake[0]
            var nextHeadPos = CGPoint(x: CGFloat(head.x), y: CGFloat(head.y))
            
            // Daha yumuşak bir başlangıç hareketi için çok küçük ilerleme
            let startProgress = min(0.1, progress)
            
            switch direction {
            case .up:
                nextHeadPos.y -= startProgress * 0.3 // Kademeli hareket için azaltılmış değerler
            case .down:
                nextHeadPos.y += startProgress * 0.3
            case .left:
                nextHeadPos.x -= startProgress * 0.3
            case .right:
                nextHeadPos.x += startProgress * 0.3
            }
            
            // Linear interpolation for smooth movement
            animatedSnakePositions[0] = nextHeadPos
            return
        }
        
        // If we're still animating between steps
        if progress < 1.0 && snake.count > 0 {
            for i in 0..<snake.count {
                if i == 0 {
                    // For the head, handle smooth turning
                    let head = snake[0]
                    var nextHeadPos = CGPoint(x: CGFloat(head.x), y: CGFloat(head.y))
                    
                    // Dönüş yapılıyorsa, dönüş yayını hesapla
                    if isTurning && currentTurnDirection != nil && previousDirection != nil {
                        // İki yönün de birleşik etkisini hesapla
                        var prevOffset = CGPoint.zero
                        var newOffset = CGPoint.zero
                        
                        switch previousDirection! {
                        case .up:    prevOffset.y = -1.0
                        case .down:  prevOffset.y = 1.0
                        case .left:  prevOffset.x = -1.0
                        case .right: prevOffset.x = 1.0
                        }
                        
                        switch currentTurnDirection! {
                        case .up:    newOffset.y = -1.0
                        case .down:  newOffset.y = 1.0
                        case .left:  newOffset.x = -1.0
                        case .right: newOffset.x = 1.0
                        }
                        
                        // İki yönün ağırlıklı ortalamasını kullan
                        let weight = easeInOutCubic(turnProgress)
                        nextHeadPos.x += prevOffset.x * CGFloat(1.0 - weight) + newOffset.x * CGFloat(weight)
                        nextHeadPos.y += prevOffset.y * CGFloat(1.0 - weight) + newOffset.y * CGFloat(weight)
                    } else {
                        // Normal hareket
                        switch direction {
                        case .up:    nextHeadPos.y -= 1.0
                        case .down:  nextHeadPos.y += 1.0
                        case .left:  nextHeadPos.x -= 1.0
                        case .right: nextHeadPos.x += 1.0
                        }
                    }
                    
                    // Linear interpolation for smooth movement
                    animatedSnakePositions[0] = interpolate(
                        from: CGPoint(x: CGFloat(head.x), y: CGFloat(head.y)),
                        to: nextHeadPos,
                        progress: progress
                    )
                } else if snake.count > 1 {
                    // Yılan gövdesi için daha akıcı hareket
                    let currentPos = CGPoint(x: CGFloat(snake[i].x), y: CGFloat(snake[i].y))
                    let targetPos = CGPoint(x: CGFloat(snake[i-1].x), y: CGFloat(snake[i-1].y))
                    
                    // Eğer bu segment bir dönüş noktası ise, dönüş animasyonu ekle
                    if let turnDir = turnPoints[i] {
                        var turnOffset = CGPoint.zero
                        switch turnDir {
                        case .up:    turnOffset.y = -0.2
                        case .down:  turnOffset.y = 0.2
                        case .left:  turnOffset.x = -0.2
                        case .right: turnOffset.x = 0.2
                        }
                        
                        // Eğrilik eklemek için interpolasyon hesapla
                        let curveFactor = sin(CGFloat.pi * CGFloat(progress))
                        var curvedPos = interpolate(
                            from: currentPos,
                            to: targetPos,
                            progress: progress
                        )
                        
                        curvedPos.x += turnOffset.x * CGFloat(curveFactor)
                        curvedPos.y += turnOffset.y * CGFloat(curveFactor)
                        
                        animatedSnakePositions[i] = curvedPos
                    } else {
                        // Normal interpolasyon
                        animatedSnakePositions[i] = interpolate(
                            from: currentPos,
                            to: targetPos,
                            progress: progress
                        )
                    }
                }
            }
        } else {
            // If we're at the exact step position, just use actual positions
            for i in 0..<snake.count {
                animatedSnakePositions[i] = CGPoint(x: CGFloat(snake[i].x), y: CGFloat(snake[i].y))
            }
        }
    }
    
    // Smooth easing function for turns
    private func easeInOutCubic(_ x: Double) -> Double {
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
    
    private func interpolate(from: CGPoint, to: CGPoint, progress: Double) -> CGPoint {
        return CGPoint(
            x: from.x + (to.x - from.x) * CGFloat(progress),
            y: from.y + (to.y - from.y) * CGFloat(progress)
        )
    }
    
    private func spawnFood() {
        var newFood: Position
        
        // Yiyeceği grid sınırları içinde oluştur (1...gridSize)
        repeat {
            newFood = Position(
                x: Int.random(in: 1...gridSize),
                y: Int.random(in: 1...gridSize)
            )
        } while snake.contains(newFood)
        
        food = newFood
    }
    
    private func updateGame() {
        // Save the last update time
        lastUpdateTime = Date()
        hasFirstUpdateOccurred = true
        
        // Calculate new head position based on current direction
        let head = snake[0]
        var newHead = Position(x: head.x, y: head.y)
        
        switch direction {
        case .up:
            newHead.y -= 1
        case .down:
            newHead.y += 1
        case .left:
            newHead.x -= 1
        case .right:
            newHead.x += 1
        }
        
        // Debug bilgisi
        print("Current head: \(head), New head: \(newHead), Direction: \(direction)")
        
        // Check for collisions with walls - sınırları düzgün kontrol et
        // gridSize = 20 ise, geçerli aralık 1...20
        if newHead.x < 1 || newHead.x > gridSize || newHead.y < 1 || newHead.y > gridSize {
            print("Wall collision detected at \(newHead)")
            endGame()
            return
        }
        
        // Check for collisions with self
        if snake.dropFirst().contains(newHead) {
            print("Self collision detected")
            endGame()
            return
        }
        
        // Add new head
        snake.insert(newHead, at: 0)
        
        // Dönüş noktaları indekslerini güncelle
        var updatedTurnPoints: [Int: Direction] = [:]
        for (index, direction) in turnPoints {
            // Her indeksi bir artır (çünkü yeni baş eklendi)
            if index + 1 < snake.count {
                updatedTurnPoints[index + 1] = direction
            }
        }
        turnPoints = updatedTurnPoints
        
        // Check if snake ate food
        if newHead == food {
            score += 10
            spawnFood()
            
            // Speed up the game slightly, but keep it slower overall
            if gameSpeed > 0.15 {
                gameSpeed -= 0.002  // Very gradual speed increase for longer gameplay
            }
        } else {
            // Remove tail if no food eaten
            snake.removeLast()
            
            // Son segment için dönüş noktasını kaldır
            if let lastIndex = turnPoints.keys.max(), lastIndex >= snake.count {
                turnPoints.removeValue(forKey: lastIndex)
            }
        }
        
        // Update animated positions immediately after updating snake positions
        setupInitialAnimatedPositions()
    }
    
    private func endGame() {
        timer?.invalidate()
        animationTimer?.invalidate()
        gameState = .gameOver
        
        // Skoru sıfırlama görevini startGame'e bırak
        // High score kayıt işlemi için mevcut skoru koru
    }
    
    // MARK: - High Score Persistence
    
    private func loadHighScores() {
        if let data = UserDefaults.standard.data(forKey: highScoresKey) {
            do {
                highScores = try JSONDecoder().decode([HighScore].self, from: data)
            } catch {
                highScores = HighScore.sample
                print("Failed to load high scores: \(error)")
            }
        } else {
            // Use sample data for first launch
            highScores = HighScore.sample
        }
    }
    
    private func saveHighScores() {
        do {
            let data = try JSONEncoder().encode(highScores)
            UserDefaults.standard.set(data, forKey: highScoresKey)
        } catch {
            print("Failed to save high scores: \(error)")
        }
    }
    
    deinit {
        timer?.invalidate()
        animationTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }
}