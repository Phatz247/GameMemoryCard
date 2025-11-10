enum GameMode {
  classic,
  timeAttack,
  survival,
  online
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

  
  (int rows, int columns) get gridSize {
    switch (difficulty) {
      case Difficulty.easy:
        return (2, 2);
      case Difficulty.medium:
        return (2, 3);
      case Difficulty.hard:
        return (4, 4);
    }
  }


  int getTimeLimit() {
    switch (mode) {
      case GameMode.classic:
        return switch (difficulty) {
          Difficulty.easy => 120,
          Difficulty.medium => 180,
          Difficulty.hard => 300,
        };
      case GameMode.timeAttack:
        return 60;
      case GameMode.survival:
        return -1;
      case GameMode.online:
        return 90;
    }
  }

  int getInitialHP() {
    return switch (difficulty) {
      Difficulty.easy => 5,
      Difficulty.medium => 4,
      Difficulty.hard => 3,
    };
  }
}
