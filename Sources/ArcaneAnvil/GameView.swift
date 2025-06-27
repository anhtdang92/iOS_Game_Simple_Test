import SwiftUI

/// A struct to manage the data for a single particle in an explosion effect.
struct RuneParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    let destination: CGPoint
    let duration: Double
    let size: CGFloat
    var opacity: Double
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
                .overlay(starterSelectionOverlay)
                .overlay(floatingScoreOverlay)
                .overlay(gameOverOverlay)
                .overlay(particleOverlay)
            
            Spacer()
            
            Text("Active Enchantments: \(gameManager.activeEnchantments.map { $0.name }.joined(separator: ", "))")
                .font(.caption)
                .padding()
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea())
        .onAppear {
            gameManager.setup(with: gameBoard)
            startNewRun()
        }
    }
    
    private var gameHeader: some View {
        VStack {
            Text("Arcane Anvil")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .shadow(color: .blue.opacity(0.8), radius: 3, x: 2, y: 2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .white, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 2)
            
            gameStats
            
            Text("High Score: \(gameManager.highScore)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
        .foregroundColor(.white)
    }
    
    private var gameStats: some View {
        HStack {
            Spacer()
            statView(icon: "star.fill", value: "\(gameManager.score)", label: "Score")
            Spacer()
            statView(icon: "target", value: "\(gameManager.scoreTarget)", label: "Target")
            Spacer()
            statView(icon: "arrow.up.circle.fill", value: "\(gameManager.currentLevel)", label: "Level")
            Spacer()
            statView(icon: "arrow.2.squarepath", value: "\(gameManager.movesRemaining)", label: "Moves")
            Spacer()
        }
        .padding(.vertical, 5)
    }
    
    private func statView(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow.opacity(0.8))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .textCase(.uppercase)
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
                                    .scaleEffect(selectedCoordinate == coord ? 0.9 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: selectedCoordinate)
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
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private var comboOverlay: some View {
        if comboDisplay.isVisible {
            Text("\(String(format: "%.1f", comboDisplay.multiplier))x Combo!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
                .transition(.asymmetric(
                    insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.5)),
                    removal: .opacity.animation(.easeOut(duration: 0.5)))
                )
        }
    }
    
    @ViewBuilder
    private var shopOverlay: some View {
        if gameManager.gameState == .shop {
            VStack(spacing: 15) {
                shopHeader
                Spacer()
                shopItemsForSale
                Spacer()
                ownedEnchantmentsSection
                Spacer()
                shopActionButtons
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            .transition(.opacity.animation(.easeIn))
        }
    }
    
    // MARK: - Shop Subviews
    
    private var shopHeader: some View {
        VStack {
            Text("Shop")
                .font(.system(size: 50, weight: .bold, design: .rounded))
            
            Text("Gold: \(gameManager.gold)")
                .font(.title)
        }
    }
    
    private var shopItemsForSale: some View {
        Group {
            ForEach(gameManager.shopSelection) { card in
                VStack(alignment: .leading) {
                    Text(card.name)
                        .font(.title2).bold()
                    Text(card.description)
                        .font(.body)
                    
                    Button(action: {
                        SoundManager.shared.playSound(.buyCard)
                        HapticManager.shared.trigger(.success)
                        gameManager.buyCard(card)
                    }) {
                        Text("Buy (\(card.cost) Gold)")
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(gameManager.gold >= card.cost ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .font(.title2)
                    .disabled(gameManager.gold < card.cost)
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                )
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 3, y: 3)
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
            }
        }
        .animation(.default, value: gameManager.shopSelection)
    }
    
    @ViewBuilder
    private var ownedEnchantmentsSection: some View {
        if !gameManager.activeEnchantments.isEmpty {
            Group {
                Text("Your Enchantments")
                    .font(.title2)
                    .padding(.top)
                
                ForEach(gameManager.activeEnchantments) { card in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(card.displayName)
                                .bold()
                            Text(card.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(spacing: 8) {
                            Button("Sell (+\(card.cost / 2)G)") {
                                SoundManager.shared.playSound(.buttonClick)
                                gameManager.sellCard(card)
                            }
                            .font(.body)
                            .padding(8)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.red)
                            
                            if let upgradeCost = card.upgradeCost {
                                Button("Upgrade (\(upgradeCost)G)") {
                                    gameManager.upgradeCard(card)
                                }
                                .font(.body)
                                .padding(8)
                                .background(gameManager.gold >= upgradeCost ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(gameManager.gold >= upgradeCost ? .green : .gray)
                                .disabled(gameManager.gold < upgradeCost)
                            } else {
                                Text("MAX LEVEL")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.asymmetric(insertion: .scale, removal: .opacity))
                }
            }
            .animation(.default, value: gameManager.activeEnchantments)
        }
    }
    
    private var shopActionButtons: some View {
        VStack(spacing: 20) {
            Button("Reroll (10 Gold)") {
                SoundManager.shared.playSound(.buttonClick)
                HapticManager.shared.trigger(.light)
                gameManager.rerollShop()
            }
            .font(.title2)
            .padding(10)
            .background(gameManager.gold < 10 ? Color.gray : Color.orange)
            .cornerRadius(10)
            .disabled(gameManager.gold < 10)

            Button("Next Level") {
                SoundManager.shared.playSound(.buttonClick)
                HapticManager.shared.trigger(.light)
                prepareNextLevel()
            }
            .font(.largeTitle)
            .padding()
        }
        .padding()
    }
    
    @ViewBuilder
    private var starterSelectionOverlay: some View {
        if gameManager.gameState == .choosingStarter {
            VStack(spacing: 15) {
                Text("Choose Your Path")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .padding(.bottom, 20)
                
                Text("Select your first enchantment to begin the run.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                
                ForEach(gameManager.starterSelection) { card in
                    Button(action: {
                        SoundManager.shared.playSound(.buttonClick)
                        HapticManager.shared.trigger(.success)
                        gameManager.selectStarter(card)
                    }) {
                        VStack(alignment: .leading) {
                            Text(card.name)
                                .font(.title2).bold()
                            Text(card.description)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.95))
            .foregroundColor(.white)
            .transition(.opacity.animation(.easeIn))
        }
    }
    
    @ViewBuilder
    private var lightningOverlay: some View {
        if let animation = lightningAnimation, animation.isVisible {
            Rectangle()
                .fill(Color.yellow)
                .frame(height: 44)
                .offset(y: CGFloat(animation.row - gameBoard.height / 2) * 44)
                .blur(radius: 20)
                .opacity(animation.isVisible ? 0.5 : 0)
                .animation(.easeInOut(duration: 0.1), value: animation.isVisible)
            
            LightningShape(animatableData: animation.isVisible ? 1 : 0)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .offset(y: CGFloat(animation.row - gameBoard.height / 2) * 44 + 22)
                .animation(.easeOut(duration: 0.3), value: animation.isVisible)
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
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .position(x: coordinateToPoint(textData.coordinate).x, y: coordinateToPoint(textData.coordinate).y)
                        .transition(
                            .asymmetric(
                                insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6)),
                                removal: .offset(y: -50).combined(with: .opacity)
                            )
                        )
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
                    .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .red.opacity(0.5), radius: 5)
                    .padding(.bottom)
                
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
                
                Button(action: {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    startNewRun()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("New Run")
                    }
                }
                .font(.largeTitle)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [.black.opacity(0.8), .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(.white)
            .transition(.opacity.animation(.easeIn))
        }
    }
    
    @ViewBuilder
    private var particleOverlay: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: 3.0)
                    .opacity(particle.opacity)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let index = floatingScores.firstIndex(where: { $0.id == newScoreText.id }) {
                withAnimation(.easeIn(duration: 0.8)) {
                    floatingScores[index].isVisible = false
                }
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
            let size = CGFloat.random(in: 5...12)
            let opacity = Double.random(in: 0.6...1.0)
            
            let particle = RuneParticle(color: color, position: startPoint, destination: destination, duration: duration, size: size, opacity: opacity)
            particles.append(particle)
            
            // Find the index of the newly added particle
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                // Animate its movement and disappearance
                withAnimation(.easeOut(duration: duration)) {
                    particles[index].position = destination
                }
                
                // Use a separate, slightly delayed animation for the fade-out
                withAnimation(.easeIn(duration: duration).delay(duration * 0.8)) {
                    particles[index].opacity = 0
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

/// A view that represents a single rune.
struct RuneView: View {
    let rune: Rune
    let size: CGFloat
    
    @State private var isAnimatingBomb = false
    
    var body: some View {
        ZStack {
            Image(String(describing: rune.type))
                .resizable()
                .scaledToFit()
            
            if rune.specialEffect == .bomb {
                Circle()
                    .stroke(Color.red, lineWidth: isAnimatingBomb ? 4 : 2)
                    .scaleEffect(isAnimatingBomb ? 1.1 : 1.0)
                    .opacity(isAnimatingBomb ? 0.5 : 1.0)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if rune.specialEffect == .bomb {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isAnimatingBomb = true
                }
            }
        }
    }
}

/// A custom Shape for drawing the jagged lightning bolt.
struct LightningShape: Shape, Animatable {
    var animatableData: CGFloat = 0
    
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
        
        // Trim the path based on the animatableData
        return path.trimmedPath(from: 0, to: animatableData)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
} 