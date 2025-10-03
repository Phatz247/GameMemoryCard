enum GameMode {
  classic,    // Normal gameplay
  timeAttack, // Limited time, score based on pairs found
  survival,   // Losing HP on mistakes
  challenge   // Special cards with traps
}

enum Difficulty {
  easy,    // 2x2 grid
  medium,  // 3x2 grid
  hard     // 4x4 grid
}

enum GameTheme {
  icons,
  animals,
  flags,
  fruits,
  superheroes,
  random
}

class GameConfig {
  final GameMode mode;
  final Difficulty difficulty;
  final GameTheme theme;

  const GameConfig({
    this.mode = GameMode.classic,
    this.difficulty = Difficulty.easy,
    this.theme = GameTheme.icons
  });

  // Get grid dimensions based on difficulty
  (int rows, int columns) get gridSize {
    switch (difficulty) {
      case Difficulty.easy:
        return (2, 2);  // 4 cards (2 pairs)
      case Difficulty.medium:
        return (2, 3);  // 6 cards (3 pairs) - changed from 3x3
      case Difficulty.hard:
        return (4, 4);  // 16 cards (8 pairs)
    }
  }

  // Get time limit based on mode and difficulty
  int getTimeLimit() {
    switch (mode) {
      case GameMode.classic:
        return switch (difficulty) {
          Difficulty.easy => 120,
          Difficulty.medium => 180,
          Difficulty.hard => 300,
        };
      case GameMode.timeAttack:
        return 60;  // Fixed time for time attack
      case GameMode.survival:
        return -1;  // No time limit for survival
      case GameMode.challenge:
        return switch (difficulty) {
          Difficulty.easy => 150,
          Difficulty.medium => 210,
          Difficulty.hard => 330,
        };
    }
  }

  // Get initial HP for survival mode
  int getInitialHP() {
    return switch (difficulty) {
      Difficulty.easy => 5,
      Difficulty.medium => 4,
      Difficulty.hard => 3,
    };
  }
}
