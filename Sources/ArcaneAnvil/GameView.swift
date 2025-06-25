import SwiftUI

/// A struct to manage the data for a single particle in an explosion effect.
struct RuneParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    let destination: CGPoint
    let duration: Double
}

/// A struct to manage the data for a floating score text animation.
struct FloatingScoreText: Identifiable {
    let id = UUID()
    let score: Int
    let coordinate: Coordinate
    var isVisible: Bool = true
}

struct GameView: View {
    
    @StateObject private var gameBoard = GameBoard(width: 8, height: 8)
    @StateObject private var gameManager = GameManager()
    @State private var selectedCoordinate: Coordinate?
    @State private var lightningAnimation: (row: Int, isVisible: Bool)? = nil
    @State private var comboDisplay: (multiplier: Double, isVisible: Bool) = (1.0, false)
    @State private var floatingScores: [FloatingScoreText] = []
    @State private var particles: [RuneParticle] = []
    
    private let runeFrameSize: CGFloat = 40
    private let gridSpacing: CGFloat = 4
    
    var body: some View {
        VStack {
            gameHeader
            
            Spacer()
            
            gameGridView
                .overlay(lightningOverlay)
                .overlay(comboOverlay)
                .overlay(shopOverlay)
                .overlay(floatingScoreOverlay)
                .overlay(gameOverOverlay)
                .overlay(particleOverlay)
            
            Spacer()
            
            Text("Active Enchantments: \(gameManager.activeEnchantments.map { $0.name }.joined(separator: ", "))")
                .font(.caption)
                .padding()
        }
        .padding()
    }
    
    private var gameHeader: some View {
        VStack {
            Text("Arcane Anvil")
                .font(.largeTitle)
                .padding(.bottom, 2)
            
            Text("High Score: \(gameManager.highScore)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            gameStats
        }
    }
    
    private var gameStats: some View {
        HStack {
            Text("Level: \(gameManager.currentLevel)")
            Spacer()
            scoreView
            Spacer()
            Text("Target: \(gameManager.scoreTarget)")
            Spacer()
            Text("Moves: \(gameManager.movesRemaining)")
        }
        .font(.headline)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var scoreView: some View {
        VStack {
            Text("Score")
            Text("\(gameManager.score)")
        }
    }
    
    private var gameGridView: some View {
        GeometryReader { geometry in
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<gameBoard.width, id: \.self) { x in
                    GridRow {
                        ForEach(0..<gameBoard.height, id: \.self) { y in
                            let coord = Coordinate(x: x, y: y)
                            if let rune = gameBoard.grid[x][y] {
                                RuneView(rune: rune, size: runeFrameSize)
                                    .border(Color.yellow, width: selectedCoordinate == coord ? 3 : 0)
                                    .transition(.scale.animation(.spring(response: 0.3, dampingFraction: 0.6)))
                                    .onTapGesture {
                                        HapticManager.shared.trigger(.selection)
                                        runeTapped(at: coord)
                                    }
                                    .disabled(gameManager.gameState != .playing)
                            } else {
                                // Placeholder for an empty space
                                Color.clear.frame(width: 40, height: 40)
                            }
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var comboOverlay: some View {
        if comboDisplay.isVisible {
            Text("\(String(format: "%.1f", comboDisplay.multiplier))x Combo!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
                .transition(.asymmetric(insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.5)), removal: .opacity))
        }
    }
    
    @ViewBuilder
    private var shopOverlay: some View {
        if gameManager.gameState == .shop {
            VStack(spacing: 15) {
                Text("Shop")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                
                Text("Gold: \(gameManager.gold)")
                    .font(.title)
                
                Spacer()
                
                ForEach(gameManager.shopSelection) { card in
                    VStack(alignment: .leading) {
                        Text(card.name)
                            .font(.title2).bold()
                        Text(card.description)
                            .font(.body)
                        
                        let cost = 10 // This should be a property on the card model later
                        Button(action: {
                            SoundManager.shared.playSound(.buyCard)
                            HapticManager.shared.trigger(.success)
                            gameManager.buyCard(card)
                        }) {
                            Text("Buy (\(cost) Gold)")
                        }
                        .font(.title2)
                        .padding(10)
                        .background(gameManager.gold >= cost ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .disabled(gameManager.gold < cost)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(15)
                }
                
                Spacer()
                
                Button("Next Level") {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    prepareNextLevel()
                }
                .font(.title)
                
                Button("Continue") {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    prepareNextLevel()
                }
                .font(.largeTitle)
                .padding()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var lightningOverlay: some View {
        if let animation = lightningAnimation, animation.isVisible {
            LightningShape()
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .offset(y: CGFloat(animation.row - gameBoard.height / 2) * 44 + 22)
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
        }
    }
    
    @ViewBuilder
    private var floatingScoreOverlay: some View {
        ZStack {
            ForEach(floatingScores) { textData in
                if textData.isVisible {
                    Text("+\(textData.score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .position(x: coordinateToPoint(textData.coordinate).x, y: coordinateToPoint(textData.coordinate).y)
                        .offset(y: -30) // Float up
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity.animation(.easeIn(duration: 0.5))))
                }
            }
        }
    }
    
    @ViewBuilder
    private var gameOverOverlay: some View {
        if gameManager.gameState == .gameOver {
            VStack {
                Text("Game Over")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                
                Text("Final Score: \(gameManager.score)")
                    .font(.title)
                
                if gameManager.score > gameManager.highScore {
                    Text("New High Score!")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .padding(.bottom)
                } else {
                    Text("High Score: \(gameManager.highScore)")
                        .font(.title2)
                        .padding(.bottom)
                }
                
                Button("New Run") {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    startNewRun()
                }
                .font(.largeTitle)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var particleOverlay: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .position(particle.position)
                    .blur(radius: 3.0)
                    .opacity(0.8)
                    .transition(.opacity)
            }
        }
    }
    
    private func runeTapped(at coord: Coordinate) {
        if let selected = selectedCoordinate {
            if areCoordinatesAdjacent(selected, coord) {
                Task {
                    await processMove(from: selected, to: coord)
                }
                selectedCoordinate = nil
            } else {
                selectedCoordinate = coord
            }
        } else {
            selectedCoordinate = coord
        }
    }
    
    /// Processes a player's move, including swapping, checking for matches, and handling the game loop.
    private func processMove(from: Coordinate, to: Coordinate) async {
        gameManager.useMove()
        SoundManager.shared.playSound(.swap)
        HapticManager.shared.trigger(.light)
        
        gameBoard.swapRunes(at: from, and: to)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        var matches = gameBoard.findMatches()
        
        if matches.isEmpty {
            // Invalid move, swap back.
            try? await Task.sleep(nanoseconds: 100_000_000)
            SoundManager.shared.playSound(.swap) // Play the reverse swap sound
            HapticManager.shared.trigger(.error)
            gameBoard.swapRunes(at: from, and: to)
            return
        }
        
        var comboCounter = 0
        var turnMultiplierBonus: Double = 0.0
        
        while !matches.isEmpty {
            // Play a sound for the match, with a higher pitch for higher combos
            SoundManager.shared.playSound(.match(comboCount: comboCounter))
            HapticManager.shared.trigger(.medium)
            
            // Trigger particle explosions for the matched runes before they are removed
            for matchCoord in matches {
                if let rune = gameBoard.grid[matchCoord.x][matchCoord.y] {
                    triggerParticleExplosion(at: matchCoord, color: color(for: rune.type))
                }
            }
            
            comboCounter += 1
            let comboMultiplier = 1.0 + (Double(comboCounter - 1) * 0.5)
            
            if comboCounter > 1 {
                withAnimation {
                    // Update the display to show the total multiplier
                    comboDisplay = (multiplier: comboMultiplier + turnMultiplierBonus, isVisible: true)
                }
            }
            
            let turnResult = gameManager.processMatches(matches: matches, on: gameBoard, comboCount: comboCounter, currentMultiplier: comboMultiplier, currentMultiplierBonus: turnMultiplierBonus)
            
            // The bonus for the next match is the one returned from this turn.
            turnMultiplierBonus = turnResult.newMultiplierBonus
            
            // Update score and gold based on the turn result
            withAnimation {
                gameManager.score += turnResult.score
                gameManager.gold += turnResult.score / 100
            }
            
            // Create floating score text
            if let centerCoord = turnResult.matchCenter {
                showFloatingScore(turnResult.score, at: centerCoord)
            }
            
            if !turnResult.newBombs.isEmpty {
                for bombCoord in turnResult.newBombs {
                    gameBoard.setSpecialEffect(at: bombCoord, effect: .bomb)
                }
            }
            
            // Check for bomb detonations to play the sound
            for coord in matches {
                if gameBoard.grid[coord.x][coord.y]?.specialEffect == .bomb {
                    SoundManager.shared.playSound(.bombExplode)
                    HapticManager.shared.trigger(.heavy)
                }
            }
            
            withAnimation(.easeIn(duration: 0.2)) {
                gameBoard.removeMatches(at: matches)
            }
            
            if turnResult.lightningStrikes > 0 {
                await triggerLightning()
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                gameBoard.shiftRunesDown()
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
                gameBoard.refillBoard()
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            matches = gameBoard.findMatches()
        }
        
        // When the loop is over, hide the combo text
        withAnimation(.easeOut(duration: 0.5)) {
            comboDisplay.isVisible = false
        }
        
        // Check if the level is complete
        if gameManager.score >= gameManager.scoreTarget {
            SoundManager.shared.playSound(.levelComplete)
            HapticManager.shared.trigger(.success)
            gameManager.completeLevel()
            return // Exit early so we don't check for game over
        }
        
        // Check for game over
        if gameManager.movesRemaining <= 0 {
            SoundManager.shared.playSound(.gameOver)
            HapticManager.shared.trigger(.error)
            gameManager.gameOver()
        }
    }
    
    private func triggerLightning() async {
        let randomRow = Int.random(in: 0..<gameBoard.height)
        
        SoundManager.shared.playSound(.lightning)
        HapticManager.shared.trigger(.heavy)
        
        withAnimation {
            lightningAnimation = (row: randomRow, isVisible: true)
        }
        
        try? await Task.sleep(nanoseconds: 150_000_000)
        
        let clearedByLightning = gameBoard.clearRow(at: randomRow)
        
        // We need the board state *before* clearing to get rune types.
        // This is a limitation we'll accept for now.
        for coord in clearedByLightning {
            triggerParticleExplosion(at: coord, color: .yellow)
        }
        
        withAnimation {
            lightningAnimation?.isVisible = false
        }
    }
    
    private func showFloatingScore(_ score: Int, at coordinate: Coordinate) {
        let newScoreText = FloatingScoreText(score: score, coordinate: coordinate)
        floatingScores.append(newScoreText)
        
        // After a delay, trigger the removal animation by setting isVisible to false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let index = floatingScores.firstIndex(where: { $0.id == newScoreText.id }) {
                floatingScores[index].isVisible = false
            }
        }
        
        // After the animation is done, remove it from the array
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            floatingScores.removeAll { $0.id == newScoreText.id }
        }
    }
    
    /// Converts a grid coordinate to a screen-space point for animations.
    private func coordinateToPoint(_ coord: Coordinate) -> CGPoint {
        let totalGridWidth = (runeFrameSize * CGFloat(gameBoard.width)) + (gridSpacing * CGFloat(gameBoard.width - 1))
        let startX = -totalGridWidth / 2 + runeFrameSize / 2
        
        let x = startX + (CGFloat(coord.x) * (runeFrameSize + gridSpacing))
        let y = startX + (CGFloat(coord.y) * (runeFrameSize + gridSpacing))
        
        return CGPoint(x: x, y: y)
    }
    
    private func prepareNextLevel() {
        gameManager.levelCleared()
        gameBoard.fillBoard() // Refill the board for the new level
    }
    
    private func startNewRun() {
        gameManager.startNewRun()
        gameBoard.fillBoard()
    }
    
    /// Checks if two coordinates are adjacent (not diagonal).
    private func areCoordinatesAdjacent(_ coord1: Coordinate, _ coord2: Coordinate) -> Bool {
        let dx = abs(coord1.x - coord2.x)
        let dy = abs(coord1.y - coord2.y)
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }
    
    private func triggerParticleExplosion(at coordinate: Coordinate, color: Color) {
        let startPoint = coordinateToPoint(coordinate)
        let numParticles = 10
        
        for _ in 0..<numParticles {
            let destination = CGPoint(
                x: startPoint.x + CGFloat.random(in: -40...40),
                y: startPoint.y + CGFloat.random(in: -40...40)
            )
            let duration = Double.random(in: 0.4...0.8)
            
            let particle = RuneParticle(color: color, position: startPoint, destination: destination, duration: duration)
            particles.append(particle)
            
            // Find the index of the newly added particle
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                // Animate its movement and disappearance
                withAnimation(.easeOut(duration: duration)) {
                    particles[index].position = destination
                }
                
                // Use a separate, slightly delayed animation for the fade-out
                withAnimation(.easeIn(duration: duration).delay(duration * 0.8)) {
                    // This is a proxy for fading out. The actual removal happens next.
                }
            }
        }
        
        // Clean up all particles after the longest possible animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll()
        }
    }
    
    /// Returns the corresponding color for a given rune type.
    private func color(for type: RuneType) -> Color {
        switch type {
        case .fire: return .red
        case .water: return .blue
        case .earth: return .brown
        case .air: return .cyan
        case .light: return .yellow
        }
    }
}

/// A custom Shape for drawing the jagged lightning bolt.
struct LightningShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint = CGPoint(x: rect.minX, y: rect.midY)
        path.move(to: startPoint)
        
        let segmentCount = 10
        var currentX: CGFloat = rect.minX
        
        for i in 1...segmentCount {
            currentX = (rect.width / CGFloat(segmentCount)) * CGFloat(i)
            let yJitter = CGFloat.random(in: -10...10)
            path.addLine(to: CGPoint(x: currentX, y: rect.midY + yJitter))
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A view that represents a single rune.
struct RuneView: View {
    let rune: Rune
    let size: CGFloat
    
    @State private var isAnimatingBomb = false
    
    var body: some View {
        ZStack {
            RuneShape(type: rune.type)
                .fill(color(for: rune.type))
            
            if rune.specialEffect == .bomb {
                Circle()
                    .stroke(Color.red, lineWidth: isAnimatingBomb ? 4 : 2)
                    .scaleEffect(isAnimatingBomb ? 1.1 : 1.0)
                    .opacity(isAnimatingBomb ? 0.5 : 1.0)
            }
        }
        .frame(width: size, height: size)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
        .onAppear {
            if rune.specialEffect == .bomb {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isAnimatingBomb = true
                }
            }
        }
    }
    
    /// Returns the corresponding color for a given rune type.
    private func color(for type: RuneType) -> Color {
        switch type {
        case .fire: return .red
        case .water: return .blue
        case .earth: return .brown
        case .air: return .cyan
        case .light: return .yellow
        }
    }
}

/// A custom SwiftUI Shape that draws a unique path for each rune type.
struct RuneShape: Shape {
    let type: RuneType
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch type {
        case .fire:
            // A stylized flame shape
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
            path.addQuadCurve(to: CGPoint(x: rect.minX + 8, y: rect.maxY - 5), control: CGPoint(x: rect.minX, y: rect.midY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 8, y: rect.maxY - 5), control: CGPoint(x: rect.midX, y: rect.maxY + 10))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + 5), control: CGPoint(x: rect.maxX, y: rect.midY))
            
        case .water:
            // A classic droplet shape
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - 5),
                          control1: CGPoint(x: rect.maxX, y: rect.minY + 5),
                          control2: CGPoint(x: rect.midX + 5, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + 5),
                          control1: CGPoint(x: rect.midX - 5, y: rect.maxY),
                          control2: CGPoint(x: rect.minX, y: rect.minY + 5))
            
        case .earth:
            // A solid, crystal-like hexagon
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
            path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY - 10))
            path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY + 10))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 5))
            path.addLine(to: CGPoint(x: rect.minX + 5, y: rect.midY + 10))
            path.addLine(to: CGPoint(x: rect.minX + 5, y: rect.midY - 10))
            path.closeSubpath()

        case .air:
            // A swirling, windy shape
            path.move(to: CGPoint(x: rect.minX + 10, y: rect.midY - 5))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 10, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.minY))
            path.move(to: CGPoint(x: rect.minX + 10, y: rect.midY + 5))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 5, y: rect.midY + 5), control: CGPoint(x: rect.midX + 5, y: rect.maxY))

        case .light:
            // A four-pointed star
            path.move(to: CGPoint(x: rect.midX, y: rect.minY + 5))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 5))
            path.move(to: CGPoint(x: rect.minX + 5, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.midY))
        }
        
        return path
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
} 