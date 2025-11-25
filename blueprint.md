# Blueprint: 2D Top-Down Shooter

## Overview

This document outlines the plan for creating a 2D top-down shooter game in Flutter. The player will control a 'king' character that can move around a 2D space and shoot at enemies. The goal is to survive as long as possible, adapting to changing environments and increasingly difficult enemies.

## Features

### Core Gameplay
- **Player Character:** A 'king' character that the player can move using keyboard (arrow keys) and on-screen controls.
- **Shooting:** The player can shoot projectiles. Over time, new weapons can be unlocked.
- **Collision Detection:** The game will detect when bullets hit enemies and when enemies hit the player.
- **Scoring:** Players will earn points for each enemy destroyed, with more difficult enemies yielding higher scores.

### Player Progression
- **Health:** The player has a health bar that depletes when hit.
- **Weapon Unlocks:** The player will gain access to new weapons as the game progresses.

### Advanced Enemies
- **Enemy Variety:** The game will feature different types of enemies with unique characteristics:
  - **Sprites:** Each enemy type (e.g., archer, tank, gunner) will have a distinct visual appearance.
  - **Behavior:** Different speeds, health points, and attack patterns.
  - **Scoring:** Higher scores for defeating more challenging enemies.

### Dynamic Environment
- **Visual Themes:** The background and terrain will change over time to represent different seasons (e.g., summer, winter) and conditions (e.g., rainy).
- **Audio:** Background music and sound effects will adapt to the current environment and in-game events.

### UI
- **Game Over Screen:** A screen that appears when the player's health reaches zero, showing the final score and an option to restart.
- **HUD:** A Heads-Up Display showing the current score, player health, and selected weapon.

## Development Plan

### Iteration 1 & 2: Core Mechanics (Completed)
- Project setup, player movement, basic shooting, simple enemies, collision, and scoring.
- Added keyboard controls for desktop play.

### Iteration 3: Advanced Enemies & Asset Integration (Current)

1.  **Asset Structure:**
    *   Create an `assets/images` directory for game sprites.
    *   Update `pubspec.yaml` to include the assets.
2.  **Enemy Refactor:**
    *   Define different `EnemyType`s (e.g., `Grunt`, `Tank`) with unique properties (health, speed, score, image asset).
3.  **Image Loading:**
    *   Implement logic to load all image assets when the game starts.
4.  **Render Sprites:**
    *   Update the `CustomPainter` to draw the loaded images for the player and enemies instead of placeholder shapes.

### Iteration 4: Dynamic Environments & Audio
-   Implement a system to change the background theme over time.
-   Integrate the `audioplayers` package to add background music and sound effects.

### Iteration 5: Player Progression
-   Introduce a weapon unlock system.
-   Design and implement different weapon types (e.g., faster bullets, spread shot).
