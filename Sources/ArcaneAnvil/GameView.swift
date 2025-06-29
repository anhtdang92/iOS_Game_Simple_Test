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

/// A struct to manage confetti particles for celebrations
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    var velocity: CGPoint
    var rotation: Double
    var rotationSpeed: Double
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
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var tutorialManager = TutorialManager()
    @StateObject private var dailyChallengeManager = DailyChallengeManager()
    @State private var selectedCoordinate: Coordinate?
    @State private var lightningAnimation: (row: Int, isVisible: Bool)? = nil
    @State private var comboDisplay: (multiplier: Double, isVisible: Bool) = (1.0, false)
    @State private var floatingScores: [FloatingScoreText] = []
    @State private var particles: [RuneParticle] = []
    @State private var comboCounter: Int = 0
    @State private var showComboText: Bool = false
    @State private var animatedScore: Double = 0
    @State private var scoreAnimationTimer: Timer?
    @State private var showLevelComplete: Bool = false
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showSettings: Bool = false
    @State private var showLoadingScreen: Bool = true
    @State private var loadingProgress: Double = 0
    @State private var showDailyChallenges: Bool = false
    @State private var lastRunePositions: [UUID: Coordinate] = [:]
    @State private var draggedTileData: (rune: Rune, position: CGPoint)? = nil
    
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
                .overlay(achievementOverlay)
                .overlay(levelCompleteOverlay)
                .overlay(tutorialOverlay)
                .overlay(settingsOverlay)
                .overlay(loadingScreenOverlay)
                .overlay(dailyChallengesOverlay)
            
            Spacer()
            
            Text("Active Enchantments: \(gameManager.activeEnchantments.map { $0.name }.joined(separator: ", "))")
                .font(.caption)
                .padding()
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea())
        .onAppear {
            startLoadingSequence()
            ensureBoardFilled()
        }
    }
    
    private var gameHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    showDailyChallenges = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 2, y: 2)
                        
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    SoundManager.shared.playSound(.buttonClick)
                    HapticManager.shared.trigger(.light)
                    showSettings = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.8), .black.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 2, y: 2)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("Arcane Anvil")
                    .font(.system(size: 52, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .white, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.8), radius: 8, x: 4, y: 4)
                    .shadow(color: .purple.opacity(0.6), radius: 4, x: 2, y: 2)
                
                Text("by Dang Production")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gray.opacity(0.8), .white.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.bottom, 4)
            }
            .padding(.vertical, 8)
            
            gameStats
            
            Text("High Score: \(gameManager.highScore)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow.opacity(0.9), .orange.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .foregroundColor(.white)
    }
    
    private var gameStats: some View {
        HStack(spacing: 16) {
            statView(icon: "star.fill", value: "\(Int(animatedScore))", label: "Score", color: .yellow)
            statView(icon: "target", value: "\(gameManager.scoreTarget)", label: "Target", color: .red)
            statView(icon: "arrow.up.circle.fill", value: "\(gameManager.currentLevel)", label: "Level", color: .blue)
            statView(icon: "arrow.2.squarepath", value: "\(gameManager.movesRemaining)", label: "Moves", color: .green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onChange(of: gameManager.score) { _, newScore in
            animateScoreChange(from: animatedScore, to: Double(newScore))
        }
    }
    
    private func statView(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: color.opacity(0.3), radius: 3, x: 1, y: 1)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.9), color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .textCase(.uppercase)
                .foregroundColor(.white.opacity(0.8))
                .tracking(0.5)
        }
    }
    
    private var gameGridView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                Grid(horizontalSpacing: gridSpacing, verticalSpacing: gridSpacing) {
                    ForEach(0..<gameBoard.height, id: \.self) { y in
                        GridRow {
                            ForEach(0..<gameBoard.width, id: \.self) { x in
                                let coord = Coordinate(x: x, y: y)
                                if let rune = gameBoard.grid[x][y] {
                                    let runeId = rune.id
                                    let previousPosition = lastRunePositions[runeId] ?? coord
                                    let yOffset = CGFloat(previousPosition.y - coord.y) * (runeFrameSize + gridSpacing)
                                    
                                    RuneView(rune: rune, size: runeFrameSize)
                                        .border(Color.yellow, width: selectedCoordinate == coord ? 3 : 0)
                                        .scaleEffect(selectedCoordinate == coord ? 0.9 : 1.0)
                                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: selectedCoordinate)
                                        .transition(.scale.animation(.spring(response: 0.3, dampingFraction: 0.6)))
                                        .offset(y: yOffset)
                                        .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: coord)
                                        .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: yOffset)
                                        .gesture(
                                            DragGesture(minimumDistance: 5)
                                                .onChanged { value in
                                                    handleDragChanged(value: value, coordinate: coord)
                                                }
                                                .onEnded { value in
                                                    handleDragEnded(value: value, coordinate: coord)
                                                }
                                        )
                                        .onTapGesture {
                                            HapticManager.shared.trigger(.selection)
                                            runeTapped(at: coord)
                                        }
                                        .disabled(gameManager.gameState != .playing)
                                } else {
                                    // Placeholder for an empty space - should not happen with proper fill
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: runeFrameSize, height: runeFrameSize)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Dragged tile overlay
                if let draggedTile = draggedTileData {
                    RuneView(rune: draggedTile.rune, size: runeFrameSize)
                        .scaleEffect(1.2)
                        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                        .position(draggedTile.position)
                        .opacity(0.9)
                        .animation(.easeOut(duration: 0.1), value: draggedTile.position)
                }
            }
        }
        .background(
            ZStack {
                // Main background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.4),
                        Color.black.opacity(0.6),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let gridSize: CGFloat = 20
                        for x in stride(from: 0, through: geometry.size.width, by: gridSize) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        for y in stride(from: 0, through: geometry.size.height, by: gridSize) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                }
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 8)
        .onChange(of: gameBoard.grid) { _, _ in
            updateLastRunePositions()
            ensureBoardFilled()
        }
    }
    
    @ViewBuilder
    private var comboOverlay: some View {
        if comboDisplay.isVisible {
            VStack(spacing: 8) {
                Text("COMBO!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                
                Text("\(String(format: "%.1f", comboDisplay.multiplier))x")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 3, y: 3)
                    .scaleEffect(showComboText ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showComboText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            .transition(.asymmetric(
                insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.5)),
                removal: .opacity.animation(.easeOut(duration: 0.5))
            ))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                    showComboText = true
                }
            }
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
                    HStack {
                        Text(card.name)
                            .font(.title2).bold()
                        Spacer()
                        rarityBadge(for: card.rarity)
                    }
                    
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
                        .stroke(rarityColor(for: card.rarity).opacity(0.7), lineWidth: 2)
                )
                .shadow(color: rarityColor(for: card.rarity).opacity(0.3), radius: 5, x: 3, y: 3)
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
            }
        }
        .animation(.default, value: gameManager.shopSelection)
    }
    
    private func rarityBadge(for rarity: CardRarity) -> some View {
        Text(rarity.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(rarityColor(for: rarity))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
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
                            HStack {
                                Text(card.displayName)
                                    .bold()
                                rarityBadge(for: card.rarity)
                            }
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
                            .stroke(rarityColor(for: card.rarity).opacity(0.5), lineWidth: 1)
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
            ZStack {
                // Animated background
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Game Over Title with animation
                    Text("GAME OVER")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .red.opacity(0.8), radius: 10, x: 5, y: 5)
                        .scaleEffect(showComboText ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showComboText)
                        .onAppear {
                            showComboText = true
                        }
                    
                    // Final Score
                    VStack(spacing: 10) {
                        Text("Final Score")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("\(gameManager.score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    )
                    
                    // High Score or Current High Score
                    if gameManager.score > gameManager.highScore {
                        VStack(spacing: 8) {
                            Text("🎉 NEW HIGH SCORE! 🎉")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                            
                            Text("Previous: \(gameManager.highScore)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.yellow.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                                )
                        )
                    } else {
                        Text("High Score: \(gameManager.highScore)")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            SoundManager.shared.playSound(.buttonClick)
                            HapticManager.shared.trigger(.light)
                            startNewRun()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("New Run")
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                        }
                        
                        Button(action: {
                            SoundManager.shared.playSound(.buttonClick)
                            HapticManager.shared.trigger(.light)
                            showSettings = true
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(40)
            }
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.5)),
                removal: .opacity.animation(.easeOut(duration: 0.3))
            ))
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
    
    @ViewBuilder
    private var achievementOverlay: some View {
        VStack {
            ForEach(achievementManager.recentlyUnlocked) { achievement in
                HStack {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievementRarityColor(for: achievement.rarity))
                    
                    VStack(alignment: .leading) {
                        Text("Achievement Unlocked!")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(achievement.name)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(achievement.rarity.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(achievementRarityColor(for: achievement.rarity))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievementRarityColor(for: achievement.rarity), lineWidth: 2)
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.top, 100)
        .padding(.horizontal)
    }
    
    private func achievementRarityColor(for rarity: Achievement.AchievementRarity) -> Color {
        switch rarity {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
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
            triggerLevelComplete()
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
    private func coordinateToPoint(_ coordinate: Coordinate) -> CGPoint {
        let x = CGFloat(coordinate.x) * (runeFrameSize + gridSpacing) + runeFrameSize / 2
        let y = CGFloat(coordinate.y) * (runeFrameSize + gridSpacing) + runeFrameSize / 2
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
    
    private func animateScoreChange(from: Double, to: Double) {
        let difference = to - from
        let steps = 30
        let stepValue = difference / Double(steps)
        let stepDuration = 0.016 // ~60fps
        
        scoreAnimationTimer?.invalidate()
        
        var currentStep = 0
        scoreAnimationTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            animatedScore = from + (stepValue * Double(currentStep))
            
            if currentStep >= steps {
                animatedScore = to
                timer.invalidate()
                scoreAnimationTimer = nil
            }
        }
    }
    
    @ViewBuilder
    private var levelCompleteOverlay: some View {
        if showLevelComplete {
            ZStack {
                // Confetti background
                ForEach(confettiParticles) { particle in
                    Rectangle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .opacity(particle.opacity)
                }
                // Level complete content
                ScrollView {
                    VStack(spacing: 20) {
                        Text("LEVEL COMPLETE!")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.8), radius: 5, x: 3, y: 3)
                        Text("Score: \(gameManager.score)")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Level \(gameManager.currentLevel)")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Button("Continue") {
                            showLevelComplete = false
                            confettiParticles.removeAll()
                            gameManager.completeLevel()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow, .orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                }
            }
            .transition(.asymmetric(
                insertion: .scale.animation(.spring(response: 0.6, dampingFraction: 0.8)),
                removal: .opacity.animation(.easeOut(duration: 0.3))
            ))
        }
    }
    
    private func triggerLevelComplete() {
        showLevelComplete = true
        createConfetti()
    }
    
    private func createConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                color: colors.randomElement() ?? .red,
                position: CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -20),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: 200...400)
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                size: CGFloat.random(in: 5...15),
                opacity: Double.random(in: 0.7...1.0)
            )
            confettiParticles.append(particle)
        }
        
        // Animate confetti
        for i in 0..<confettiParticles.count {
            let duration = Double.random(in: 2.0...4.0)
            withAnimation(.easeOut(duration: duration)) {
                confettiParticles[i].position.y = screenHeight + 50
                confettiParticles[i].rotation += confettiParticles[i].rotationSpeed * duration
            }
        }
        
        // Clean up confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            confettiParticles.removeAll()
        }
    }
    
    @ViewBuilder
    private var tutorialOverlay: some View {
        if tutorialManager.isTutorialActive, let step = tutorialManager.currentStep {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Progress indicator
                    ProgressView(value: tutorialManager.progressPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)
                    
                    // Tutorial content
                    VStack(spacing: 15) {
                        Text(step.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        if !step.isRequired {
                            Button("Skip") {
                                SoundManager.shared.playSound(.buttonClick)
                                HapticManager.shared.trigger(.light)
                                tutorialManager.skipTutorial()
                            }
                            .font(.title3)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(step.isRequired ? "Got it!" : "Next") {
                            SoundManager.shared.playSound(.buttonClick)
                            HapticManager.shared.trigger(.light)
                            tutorialManager.completeCurrentStep()
                        }
                        .font(.title3)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                    }
                }
                .padding(30)
            }
            .transition(.opacity.animation(.easeInOut))
        }
    }
    
    @ViewBuilder
    private var settingsOverlay: some View {
        if showSettings {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showSettings = false
                    }
                
                VStack(spacing: 25) {
                    Text("Settings")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Game Statistics
                            settingsSection(title: "Statistics") {
                                VStack(spacing: 10) {
                                    statRow(label: "High Score", value: "\(gameManager.highScore)")
                                    statRow(label: "Achievements", value: "\(achievementManager.unlockedAchievements.count)/\(achievementManager.achievements.count)")
                                    statRow(label: "Completion", value: "\(String(format: "%.1f", achievementManager.completionPercentage))%")
                                }
                            }
                            
                            // Tutorial
                            settingsSection(title: "Tutorial") {
                                Button("Reset Tutorial") {
                                    SoundManager.shared.playSound(.buttonClick)
                                    HapticManager.shared.trigger(.light)
                                    tutorialManager.resetTutorial()
                                    showSettings = false
                                }
                                .font(.body)
                                .padding()
                                .background(Color.orange.opacity(0.3))
                                .foregroundColor(.orange)
                                .cornerRadius(10)
                            }
                            
                            // Credits
                            settingsSection(title: "Credits") {
                                VStack(spacing: 8) {
                                    Text("Arcane Anvil")
                                        .font(.headline)
                                        .foregroundColor(.cyan)
                                    Text("by Dang Production")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("Version 1.0")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button("Close") {
                        SoundManager.shared.playSound(.buttonClick)
                        HapticManager.shared.trigger(.light)
                        showSettings = false
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .foregroundColor(.white)
            }
            .transition(.asymmetric(
                insertion: .scale.animation(.spring(response: 0.6, dampingFraction: 0.8)),
                removal: .opacity.animation(.easeOut(duration: 0.3))
            ))
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.cyan)
            
            content()
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var loadingScreenOverlay: some View {
        if showLoadingScreen {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: loadingProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            .foregroundColor(.white)
        }
    }
    
    private func startLoadingSequence() {
        // Animate loading progress
        withAnimation(.easeInOut(duration: 2.0)) {
            loadingProgress = 100
        }
        
        // Initialize game components
        gameManager.setup(with: gameBoard)
        gameManager.setupAchievements(with: achievementManager)
        gameManager.setupDailyChallenges(with: dailyChallengeManager)
        
        // Hide loading screen after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showLoadingScreen = false
            }
            startNewRun()
        }
    }
    
    @ViewBuilder
    private var dailyChallengesOverlay: some View {
        if showDailyChallenges {
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDailyChallenges = false
                    }
                
                VStack(spacing: 20) {
                    Text("Daily Challenges")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Progress indicator
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(dailyChallengeManager.completionPercentage))%")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        ProgressView(value: dailyChallengeManager.completionPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                    
                    // Challenges list
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(dailyChallengeManager.todaysChallenges) { challenge in
                                dailyChallengeCard(challenge)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Total rewards
                    if dailyChallengeManager.totalRewards > 0 {
                        HStack {
                            Text("Total Rewards:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(dailyChallengeManager.totalRewards) Gold")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(15)
                    }
                    
                    Button("Close") {
                        SoundManager.shared.playSound(.buttonClick)
                        HapticManager.shared.trigger(.light)
                        showDailyChallenges = false
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .foregroundColor(.white)
            }
            .transition(.asymmetric(
                insertion: .scale.animation(.spring(response: 0.6, dampingFraction: 0.8)),
                removal: .opacity.animation(.easeOut(duration: 0.3))
            ))
        }
    }
    
    private func dailyChallengeCard(_ challenge: DailyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: challenge.type.icon)
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(challenge.progress)/\(challenge.target)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("+\(challenge.reward)G")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            // Progress bar
            ProgressView(value: Double(challenge.progress), total: Double(challenge.target))
                .progressViewStyle(LinearProgressViewStyle(tint: challenge.isCompleted ? .green : .orange))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            if challenge.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed!")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(challenge.isCompleted ? Color.green.opacity(0.5) : Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private func handleDragChanged(value: DragGesture.Value, coordinate: Coordinate) {
        guard let rune = gameBoard.grid[coordinate.x][coordinate.y] else { return }
        
        // Calculate the position for the dragged tile overlay
        let basePosition = coordinateToPoint(coordinate)
        let draggedPosition = CGPoint(
            x: basePosition.x + value.translation.width,
            y: basePosition.y + value.translation.height
        )
        
        // Only show dragged tile if we've moved enough distance
        if abs(value.translation.width) > 5 || abs(value.translation.height) > 5 {
            draggedTileData = (rune: rune, position: draggedPosition)
            selectedCoordinate = coordinate
        }
    }
    
    private func handleDragEnded(value: DragGesture.Value, coordinate: Coordinate) {
        guard let draggedTile = draggedTileData else { 
            // If no drag occurred, just select the tile
            selectedCoordinate = coordinate
            return 
        }
        
        // Calculate the target coordinate based on drag direction
        let dragThreshold: CGFloat = runeFrameSize / 3 // More sensitive threshold
        let dx = value.translation.width
        let dy = value.translation.height
        var target: Coordinate? = nil
        
        if abs(dx) > abs(dy) {
            if dx > dragThreshold, coordinate.x < gameBoard.width - 1 {
                target = Coordinate(x: coordinate.x + 1, y: coordinate.y)
            } else if dx < -dragThreshold, coordinate.x > 0 {
                target = Coordinate(x: coordinate.x - 1, y: coordinate.y)
            }
        } else {
            if dy > dragThreshold, coordinate.y < gameBoard.height - 1 {
                target = Coordinate(x: coordinate.x, y: coordinate.y + 1)
            } else if dy < -dragThreshold, coordinate.y > 0 {
                target = Coordinate(x: coordinate.x, y: coordinate.y - 1)
            }
        }
        
        // Clear the dragged tile overlay with animation
        withAnimation(.easeOut(duration: 0.2)) {
            draggedTileData = nil
        }
        
        // Process the move if we have a valid target
        if let target = target {
            HapticManager.shared.trigger(.selection)
            Task {
                await processMove(from: coordinate, to: target)
            }
        }
        
        selectedCoordinate = nil
    }
    
    private func updateLastRunePositions() {
        var newPositions: [UUID: Coordinate] = [:]
        for x in 0..<gameBoard.width {
            for y in 0..<gameBoard.height {
                if let rune = gameBoard.grid[x][y] {
                    newPositions[rune.id] = Coordinate(x: x, y: y)
                }
            }
        }
        lastRunePositions = newPositions
    }
    
    private func ensureBoardFilled() {
        // Check if any positions are empty and fill them
        var needsRefill = false
        for x in 0..<gameBoard.width {
            for y in 0..<gameBoard.height {
                if gameBoard.grid[x][y] == nil {
                    needsRefill = true
                    break
                }
            }
            if needsRefill { break }
        }
        
        if needsRefill {
            gameBoard.refillBoard()
        }
    }
}

/// A view that represents a single rune.
struct RuneView: View {
    let rune: Rune
    let size: CGFloat
    
    @State private var isAnimatingBomb = false
    @State private var isAnimatingSpecial = false
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(runeColor.opacity(0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 8)
            
            // Main tile background
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(
                    LinearGradient(
                        colors: [
                            runeColor.opacity(0.9),
                            runeColor.opacity(0.7),
                            runeColor.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: runeColor.opacity(0.6), radius: 6, x: 2, y: 3)
            
            // Inner highlight
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
            
            // Rune symbol
            Text(runeSymbol)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                .shadow(color: runeColor.opacity(0.8), radius: 1, x: 0, y: 0)
            
            // Special effect overlays
            if let specialEffect = rune.specialEffect {
                specialEffectOverlay(for: specialEffect)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            startSpecialAnimations()
        }
    }
    
    @ViewBuilder
    private func specialEffectOverlay(for effect: SpecialEffect) -> some View {
        switch effect {
        case .bomb:
            ZStack {
                // Bomb glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .scaleEffect(isAnimatingBomb ? 1.3 : 1.0)
                    .opacity(isAnimatingBomb ? 0.8 : 0.4)
                
                // Bomb border
                RoundedRectangle(cornerRadius: size * 0.15)
                    .stroke(
                        LinearGradient(
                            colors: [Color.red, Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isAnimatingBomb ? 4 : 2
                    )
                    .frame(width: size * 0.95, height: size * 0.95)
                    .scaleEffect(isAnimatingBomb ? 1.1 : 1.0)
                    .opacity(isAnimatingBomb ? 0.8 : 1.0)
                
                // Bomb icon
                Image(systemName: "burst.fill")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .scaleEffect(isAnimatingBomb ? 1.2 : 1.0)
            }
                
        case .lineClearer(let direction):
            ZStack {
                // Line clearer glow
                if direction == .horizontal || direction == .cross {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: size * 1.8, height: size * 0.4)
                        .scaleEffect(isAnimatingSpecial ? 1.3 : 1.0)
                        .opacity(isAnimatingSpecial ? 0.7 : 0.4)
                }
                if direction == .vertical || direction == .cross {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.4, height: size * 1.8)
                        .scaleEffect(isAnimatingSpecial ? 1.3 : 1.0)
                        .opacity(isAnimatingSpecial ? 0.7 : 0.4)
                }
                
                // Line clearer icon
                Image(systemName: direction == .cross ? "arrow.up.left.and.arrow.down.right" : 
                              direction == .horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .scaleEffect(isAnimatingSpecial ? 1.2 : 1.0)
            }
            
        case .colorChanger:
            ZStack {
                // Color changer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .scaleEffect(isAnimatingSpecial ? 1.3 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.8 : 0.4)
                
                // Color changer border
                RoundedRectangle(cornerRadius: size * 0.15)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple, Color(red: 1.0, green: 0.0, blue: 1.0), Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size * 0.95, height: size * 0.95)
                    .scaleEffect(isAnimatingSpecial ? 1.2 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.8 : 1.0)
                
                // Color changer icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .rotationEffect(.degrees(isAnimatingSpecial ? 180 : 0))
            }
                
        case .areaClearer(let radius):
            ZStack {
                // Area clearer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * CGFloat(radius) * 0.6
                        )
                    )
                    .frame(width: size * CGFloat(radius) * 1.2, height: size * CGFloat(radius) * 1.2)
                    .scaleEffect(isAnimatingSpecial ? 1.4 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.7 : 0.4)
                
                // Area clearer border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size * CGFloat(radius) * 0.9, height: size * CGFloat(radius) * 0.9)
                    .scaleEffect(isAnimatingSpecial ? 1.3 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.8 : 1.0)
                
                // Area clearer icon
                Image(systemName: "burst")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .scaleEffect(isAnimatingSpecial ? 1.2 : 1.0)
            }
                
        case .multiplier:
            ZStack {
                // Multiplier glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .scaleEffect(isAnimatingSpecial ? 1.3 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.8 : 0.4)
                
                // Multiplier border
                RoundedRectangle(cornerRadius: size * 0.15)
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size * 0.95, height: size * 0.95)
                    .scaleEffect(isAnimatingSpecial ? 1.1 : 1.0)
                    .opacity(isAnimatingSpecial ? 0.8 : 1.0)
                
                // Multiplier text
                Text("×2")
                    .font(.system(size: size * 0.25, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                    .scaleEffect(isAnimatingSpecial ? 1.2 : 1.0)
            }
        }
    }
    
    private func startSpecialAnimations() {
        if rune.specialEffect == .bomb {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimatingBomb = true
            }
        } else if rune.specialEffect != nil {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimatingSpecial = true
            }
        }
    }
    
    private var runeColor: Color {
        switch rune.type {
        case .fire: return .red
        case .water: return .blue
        case .earth: return .brown
        case .air: return .cyan
        case .light: return .yellow
        }
    }
    
    private var runeSymbol: String {
        switch rune.type {
        case .fire: return "🔥"
        case .water: return "💧"
        case .earth: return "🌍"
        case .air: return "💨"
        case .light: return "✨"
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