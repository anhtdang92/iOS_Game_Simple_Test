# Arcane Anvil

## Project Scope

**Arcane Anvil** is a simple yet addictive iOS puzzle roguelike. The game combines the intuitive nature of match-3 gameplay with the strategic depth and high replayability of a deck-builder, inspired by the compelling synergies found in games like Balatro.

### Core Gameplay Loop

1.  **The Forge (The Grid):** The main screen is a grid filled with various elemental runes (e.g., Fire, Water, Earth, Air). The player swaps adjacent runes to create matches of three or more, clearing them from the board and contributing to their score.

2.  **Forging an Item (The Objective):** Each level, or "Forging," requires the player to reach a target score by matching runes. Successfully reaching the score means you have forged a powerful magical item and can proceed.

3.  **The Spellbook (The Synergies):** This is where the Balatro-like magic happens. The player has a limited number of slots for "Enchantment Cards," which act as passive buffs and synergy-multipliers. The goal is to build a "deck" of enchantments that work together to create explosive, high-scoring combos.
    *   **Example Enchantments:**
        *   **Volcanic Heart:** Matching 5 or more Fire runes creates a bomb that clears all surrounding runes.
        *   **Tidal Affinity:** All points from Water rune matches are worth 2x.
        *   **Stonemason's Secret:** Matching Earth runes also adds +1 to the score multiplier for the rest of the round.
        *   **Chain Reaction:** The first match in a cascade creates a lightning bolt that clears a random row.

4.  **Roguelike Progression:**
    *   After successfully forging an item (clearing a level), the player enters a shop.
    *   Here, they can spend gold earned during the level to purchase new Enchantment Cards from a random, limited selection.
    *   Players can also upgrade their existing enchantments or sell them to make space for better ones.
    *   The run continues through progressively harder levels until the player fails to meet the score target.

### Why It's Addictive

*   **Simple Core, Deep Strategy:** The match-3 mechanic is immediately understandable, but the real game lies in the strategic choices of which enchantments to buy, keep, and combine.
*   **High Replayability:** The random assortment of Enchantment Cards offered in each run ensures that no two games are the same. Players will constantly be discovering new, powerful, and unexpected synergies.
*   **The "Just One More Run" Feeling:** The desire to get a better combination of cards, beat a high score, or try a different strategy is a powerful hook for players.

---

## Graphics Prompts

Here are some prompts that can be used with an AI image generator (like Midjourney, DALL-E, etc.) to create the visual assets for the game.

### Game Logo
> A stylized, glowing anvil with a magical rune carved into its side. The title "Arcane Anvil" is forged in a fantasy, slightly serif font with an inner glow. Cinematic, epic, fantasy game logo.

### Game Assets

*   **Elemental Runes:**
    > A set of 5 distinct elemental runes (Fire, Water, Earth, Air, Light) for a fantasy match-3 puzzle game. Each rune must be visually distinct, set in a slightly rounded square tile. The style should be clean, vibrant, and stylized, with a magical glow. Flat vector art style on a dark, textured background.

*   **Game Background:**
    > A warm, cozy, slightly magical blacksmith's forge interior. There are tools on the walls, a glowing furnace in the background (out of focus), and a large anvil in the foreground where the game board will eventually sit. The lighting is warm and inviting, coming from the forge, with magical blue and purple highlights. Fantasy, painterly art style.

*   **Enchantment Card Template:**
    > A fantasy card template for a digital card game. Ornate, magical border made of dark metal and infused with glowing runes. It needs a central area for an illustration and a text box below for the description. The style is a mix of ancient parchment and powerful magic.

*   **Example Card Illustrations:**
    *   **For "Volcanic Heart":**
        > A glowing, stylized heart made of magma and obsidian, pulsing with fiery power. Fantasy art, digital painting, item icon.
    *   **For "Tidal Affinity":**
        > A swirling vortex of magical water with energy radiating from the center. Fantasy art, digital painting, item icon.

---

## Game Logic Documentation (Current)

This document outlines the architecture and logic of the fully-featured Arcane Anvil prototype.

### 1. Core Data & Managers

*   **Models (`Rune.swift`, `EnchantmentCard.swift`)**: These define the basic data structures. `Rune` now includes a `specialEffect` property to designate bombs. `EnchantmentCard` contains a master list (`allCards`) of every card in the game for the shop to use.
*   **`GameBoard.swift`**: The heart of the grid logic. It now has enhanced functions to handle special effects, such as `setSpecialEffect`, `clearRow` for lightning, and an `areaOfEffect` calculator for bomb detonations. The `removeMatches` function was upgraded to check for and detonate bombs.
*   **`GameManager.swift`**: The central brain of the game. It manages all major state variables:
    *   **`GameState`**: An enum (`playing`, `shop`, `gameOver`) that dictates the overall state of the application.
    *   **Player Stats**: `score`, `gold`, `currentLevel`, `scoreTarget`, `movesRemaining`, and `highScore`.
    *   **Gameplay Logic**: The `processMatches` function is the core of the synergy system. It takes the current `comboCount` and a `currentMultiplierBonus` to calculate score and determine if any new special effects (bombs, lightning) should be created.
    *   **Progression**: It handles the logic for the `shop`, `levelCleared`, and `gameOver` states.
*   **`PersistenceManager.swift`**: A dedicated singleton responsible for saving and loading the `highScore` to the device's `UserDefaults`, ensuring it persists between game sessions.
*   **`SoundManager.swift` & `HapticManager.swift`**: Singletons that provide a framework for audio and haptic feedback. They contain enums for every possible sound and haptic effect. While they currently only print to the console, they are fully integrated throughout the game logic, ready for media assets to be added in Xcode.

### 2. The Gameplay Loop (`GameView.swift`)

The `processMove` function in `GameView` orchestrates the entire turn sequence:
1.  **Initiation**: A player swaps two runes. A `swap` sound and a `light` haptic are triggered. The `movesRemaining` counter is decremented.
2.  **Validation**: The board checks for matches. If none are found, the runes are swapped back with an `error` haptic, and the turn ends.
3.  **Cascade Loop**: If matches are found, the game enters a loop that continues as long as new matches are formed. For each cycle:
    *   **Counters**: A `comboCounter` and a `turnMultiplierBonus` (for Stonemason's Secret) are tracked.
    *   **Sounds & Haptics**: A `match` sound and `medium` haptic are triggered.
    *   **Synergy Calculation**: The `GameManager.processMatches` function is called with the current state to get a `TurnResult`.
    *   **Score & Gold**: The score and gold from the `TurnResult` are added to the player's totals. The main score counter animates to the new value.
    *   **Floating Text**: The score from the match appears on the grid and floats upwards.
    *   **Special Effects**:
        *   If the result contains a `newBomb`, the effect is applied to the rune. A pulsating animation is added to the bomb.
        *   If the result contains `lightningStrikes`, the `triggerLightning` function is called, which plays a sound, a `heavy` haptic, and a visual effect before clearing a random row.
        *   If a bomb is part of a match, a `bombExplode` sound and `heavy` haptic are triggered.
    *   **Board Resolution**: Matched runes are removed with a fade/scale animation. Runes above fall into place with a spring animation. New runes drop in from the top with the same spring animation.
4.  **Loop End**: When no new matches are found, the cascade loop ends.
5.  **State Check**:
    *   The game checks if `score >= scoreTarget`. If true, it plays a `levelComplete` sound, a `success` haptic, and sets the game state to `.shop`.
    *   If false, it checks if `movesRemaining <= 0`. If true, it plays a `gameOver` sound, an `error` haptic, checks if a new high score was set, and changes the state to `.gameOver`.

### 3. UI and Polish (`GameView.swift`)

The UI is designed to be responsive and satisfying.
*   **State-Driven Overlays**: The view uses a stack of overlays that appear based on the `GameManager.gameState` (`shop`, `gameOver`). This keeps the UI logic clean.
*   **Programmatic Graphics**: All game pieces and effects (`RuneShape`, `LightningShape`) are drawn programmatically with SwiftUI, making them scalable and easy to modify.
*   **Animations**:
    *   **Score Counter**: The main score doesn't snap to new values; it animates upwards.
    *   **Grid**: Runes scale and fade on creation/destruction and fall with a bouncy spring animation.
    *   **Floating Text**: Score and combo text use custom transitions to pop onto the screen and fade away.
    *   **Particle Effects**: When runes are matched, they burst into small, animated particles that fly outwards and fade.
*   **Audio-Visual-Tactile Feedback**: Every significant action is paired with a corresponding sound, haptic, and visual effect to make the game feel immersive and responsive.
*   **High Score Display**: The high score is always visible on the main screen and is a central part of the Game Over screen to motivate the player.
