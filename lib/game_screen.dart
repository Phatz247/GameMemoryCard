import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';
import 'card_model.dart';
import 'game_modes.dart';
import 'game_theme.dart';
import 'game_widgets.dart';
import 'leaderboard_screen.dart';
import 'leaderboard_service.dart';
import 'player_score.dart';
import 'profile_screen.dart' as profile_screen;
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({Key? key, required this.config}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int score = 0;
  int combo = 0;
  int hp = 0;
  int highScore = 0;
  bool hasShield = false;
  bool isPaused = false;

  int wrongFlipsCount = 0;

  static final Map<GameMode, List<LevelConfig>> levelConfigs = {
    GameMode.classic: [
      LevelConfig(pairs: 4, time: 60, gridSize: (2, 4)),
      LevelConfig(pairs: 6, time: 90, gridSize: (2, 6)),
      LevelConfig(pairs: 8, time: 120, gridSize: (2, 8)),
      LevelConfig(pairs: 10, time: 150, gridSize: (2, 10)),
      LevelConfig(pairs: 12, time: 180, gridSize: (3, 8)),
    ],
    GameMode.timeAttack: [
      LevelConfig(pairs: 4, time: 30, gridSize: (2, 4)),
      LevelConfig(pairs: 6, time: 45, gridSize: (2, 6)),
      LevelConfig(pairs: 8, time: 60, gridSize: (2, 8)),
      LevelConfig(pairs: 10, time: 75, gridSize: (2, 10)),
      LevelConfig(pairs: 12, time: 90, gridSize: (3, 8)),
    ],
    GameMode.survival: [
      LevelConfig(pairs: 4, time: -1, gridSize: (2, 4), hp: 5),
      LevelConfig(pairs: 6, time: -1, gridSize: (2, 6), hp: 5),
      LevelConfig(pairs: 8, time: -1, gridSize: (2, 8), hp: 4),
      LevelConfig(pairs: 10, time: -1, gridSize: (2, 10), hp: 4),
      LevelConfig(pairs: 12, time: -1, gridSize: (3, 8), hp: 3),
    ],
  };

  // Danh sách hình ảnh
  final List<String> allImages = [
    'assets/img/hinh1.jpg',
    'assets/img/hinh2.jpg',
    'assets/img/hinh3.jpg',
    'assets/img/hinh4.jpg',
    'assets/img/hinh5.jpg',
    'assets/img/hinh6.jpg',
    'assets/img/hinh7.jpg',
    'assets/img/hinh8.jpg',
    'assets/img/hinh9.jpg',
    'assets/img/hinh10.jpg',
    'assets/img/hinh11.jpg',
    'assets/img/hinh12.jpg',
    'assets/img/hinh13.png',
    'assets/img/hinh14.jpg',
    'assets/img/hinh15.jpg',
    'assets/img/hinh16.jpg',
  ];

  List<CardItem> cards = [];
  CardItem? firstFlippedCard;
  CardItem? secondFlippedCard;
  int moves = 0;
  int matchedPairs = 0;
  bool isChecking = false;
  int currentLevel = 0;
  Timer? gameTimer;
  int remainingTime = 0;
  int elapsedTime = 0;
  bool isGameOver = false;

  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _initializeAudio();
    _initializeAnimations();
    _loadHighScore();
    _setupGame();

    if (widget.config.mode == GameMode.survival) {
      hp = _getCurrentLevelConfig().hp ?? 5;
    }
  }

  LevelConfig _getCurrentLevelConfig() {
    final configs =
        levelConfigs[widget.config.mode] ?? levelConfigs[GameMode.classic]!;
    return configs[currentLevel.clamp(0, configs.length - 1)];
  }

  int _getTotalLevels() {
    return levelConfigs[widget.config.mode]?.length ?? 5;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('current_user') ?? 'Unknown';
    setState(() {
      highScore = prefs.getInt('high_score_$username') ?? 0;
    });
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user') ?? 'Unknown';
      await prefs.setInt('high_score_$username', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    // Phát nhạc nền khi vào game
    await _audioService.playBackgroundMusic('audio/game_background_music.mp3');
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _audioService.stopBackgroundMusic();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setupGame() {
    try {
      gameTimer?.cancel();

      final levelConfig = _getCurrentLevelConfig();

      setState(() {
        moves = 0;
        matchedPairs = 0;
        score = 0;
        combo = 0;
        firstFlippedCard = null;
        secondFlippedCard = null;
        isChecking = false;
        isGameOver = false;
        remainingTime = levelConfig.time;

        if (widget.config.mode == GameMode.survival) {
          hp = levelConfig.hp ?? 5;
        }
      });

      if (remainingTime > 0) {
        gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || isGameOver) {
            timer.cancel();
            return;
          }

          setState(() {
            remainingTime--;
          });

          if (remainingTime <= 0) {
            timer.cancel();

            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && !isGameOver) {
                _gameOver(false);
              }
            });
          }
        });
      } else if (widget.config.mode == GameMode.classic) {
        gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || isGameOver) {
            timer.cancel();
            return;
          }
          setState(() {
            elapsedTime++;
          });
        });
      }

      final List<CardItem> newCards = [];
      final currentImages = allImages.take(levelConfig.pairs).toList();

      for (int i = 0; i < levelConfig.pairs; i++) {
        newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
        newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
      }

      newCards.shuffle();

      setState(() {
        cards = newCards;
      });
    } catch (e) {
      print('Error in _setupGame: $e');
    }
  }

  void _gameOver(bool won) {
    if (moves == 0 && matchedPairs == 0) {
      return;
    }

    isGameOver = true;
    gameTimer?.cancel();

    if (won) {
      _saveScore().then((_) {
        _showWinDialog();
      });
    } else {
      _showLoseDialog();
    }
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    final playerName = prefs.getString('current_user') ?? 'Unknown';

    final totalGames = (prefs.getInt('total_games_$playerName') ?? 0) + 1;
    final totalWins = (prefs.getInt('wins_$playerName') ?? 0) + 1;
    final playTime =
        (prefs.getInt('play_time_$playerName') ?? 0) + (elapsedTime ~/ 60);

    await prefs.setInt('total_games_$playerName', totalGames);
    await prefs.setInt('wins_$playerName', totalWins);
    await prefs.setInt('play_time_$playerName', playTime);

    if (widget.config.mode != GameMode.classic) {
      final playerScore = PlayerScore(
        playerName: playerName,
        score: this.score,
        moves: moves,
        timeSpent: remainingTime > 0
            ? _getCurrentLevelConfig().time - remainingTime
            : elapsedTime,
        playedAt: DateTime.now(),
      );

      await LeaderboardService.saveScore(
        widget.config.mode,
        currentLevel + 1,
        playerScore,
      );
    }

    // Unlock achievements
    bool isPerfect = wrongFlipsCount == 0;

    // Call public function to unlock achievements
    await profile_screen.unlockGameAchievements(
      playerName: playerName,
      isWin: true,
      finalScore: score,
      totalGames: totalGames,
      totalWins: totalWins,
      gameTime: elapsedTime,
      isPerfectMatch: isPerfect,
    );
  }

  void _showWinDialog() {
    if (moves == 0 && matchedPairs == 0) {
      return;
    }

    final isLastLevel = currentLevel >= _getTotalLevels() - 1;
    final totalLevels = _getTotalLevels();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1a237e), const Color(0xFF0d47a1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameThemeData.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon và tiêu đề
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),

                Text(
                  isLastLevel ? 'Hoàn Thành Tất Cả!' : 'Level Hoàn Thành!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  isLastLevel
                      ? 'Chúc mừng! Bạn đã vượt qua $totalLevels level!'
                      : 'Level ${currentLevel + 1}/$totalLevels',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Thông tin điểm
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Điểm: $score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.swap_horiz, 'Lần lật', '$moves'),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            Icons.timer_outlined,
                            'Thời gian',
                            widget.config.mode == GameMode.classic
                                ? '${elapsedTime}s'
                                : '${_getCurrentLevelConfig().time - remainingTime}s',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Column(
                  children: [
                    if (!isLastLevel)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              currentLevel++;
                            });
                            _setupGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameThemeData.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Level Tiếp Theo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if (widget.config.mode != GameMode.classic)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final playerName =
                                    prefs.getString('current_user') ??
                                    'Unknown';
                                if (!context.mounted) return;

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LeaderboardScreen(
                                      gameMode: widget.config.mode,
                                      level: currentLevel + 1,
                                      currentPlayer: playerName,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Xem BXH'),
                            ),
                          ),
                        if (widget.config.mode != GameMode.classic)
                          const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (isLastLevel) {
                                setState(() {
                                  currentLevel = 0;
                                  score = 0;
                                });
                              }
                              _setupGame();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isLastLevel ? 'Chơi Lại' : 'Thử Lại'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _exitGame();
                      },
                      child: Text(
                        'Về Menu',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showLoseDialog() {
    if (!mounted) return;

    final totalLevels = _getTotalLevels();
    String loseReason = '';

    if (widget.config.mode == GameMode.survival) {
      loseReason = 'Bạn đã hết HP!';
    } else if (remainingTime <= 0) {
      loseReason = 'Hết thời gian!';
    } else {
      loseReason = 'Thử lại lần nữa!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1a237e), const Color(0xFF0d47a1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('😢', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Trò chơi kết thúc',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Level ${currentLevel + 1}/$totalLevels',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    loseReason,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Thông tin điểm
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Điểm: $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.swap_horiz,
                              'Lần lật',
                              '$moves',
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              Icons.check_circle,
                              'Đã ghép',
                              '$matchedPairs',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _setupGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameThemeData.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Chơi Lại',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exitGame();
                        },
                        child: Text(
                          'Về Menu',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCardTapped(CardItem card) {
    if (card.isFlipped || card.isMatched || isChecking || isGameOver) return;

    setState(() {
      card.isFlipped = true;
    });

    // Phát âm thanh lật thẻ
    _audioService.playSoundEffect('audio/card_flip.mp3');

    if (firstFlippedCard == null) {
      firstFlippedCard = card;
    } else if (secondFlippedCard == null) {
      secondFlippedCard = card;
      _checkMatch();
    }
  }

  void _checkMatch() {
    if (firstFlippedCard == null || secondFlippedCard == null) return;

    setState(() {
      isChecking = true;
      moves++;
    });

    Timer(const Duration(milliseconds: 800), () {
      bool isMatch =
          firstFlippedCard!.imagePath == secondFlippedCard!.imagePath;

      setState(() {
        if (isMatch) {
          firstFlippedCard!.isMatched = true;
          secondFlippedCard!.isMatched = true;
          matchedPairs++;
          _calculateScore(true);
          // Phát âm thanh khi tìm thấy cặp
          _audioService.playSoundEffect('audio/match_success.mp3');
        } else {
          firstFlippedCard!.isFlipped = false;
          secondFlippedCard!.isFlipped = false;
          _handleMismatch();
          // Phát âm thanh khi không khớp
          _audioService.playSoundEffect('audio/match_fail.mp3');
        }

        firstFlippedCard = null;
        secondFlippedCard = null;
        isChecking = false;
      });

      _checkGameEnd();
    });
  }

  void _calculateScore(bool isMatch) {
    if (isMatch) {
      combo++;
      int baseScore = 100;
      int comboBonus = combo > 1 ? (combo - 1) * 50 : 0;
      int timeBonus = widget.config.mode == GameMode.timeAttack
          ? remainingTime * 2
          : 0;
      int levelBonus = currentLevel * 50;

      setState(() {
        score += baseScore + comboBonus + timeBonus + levelBonus;
      });

      _updateHighScore();
    } else {
      combo = 0;
    }
  }

  void _handleMismatch() {
    wrongFlipsCount++;
    if (widget.config.mode == GameMode.survival) {
      hp--;
      if (hp <= 0) {
        _gameOver(false);
      }
    }
  }

  void _checkGameEnd() {
    if (cards.isEmpty || isGameOver || moves == 0) {
      return;
    }

    final normalCards = cards.where((c) => c.type == CardType.normal).length;
    final totalPairs = normalCards ~/ 2;

    if (totalPairs > 0 && matchedPairs >= totalPairs) {
      _gameOver(true);
    }
  }

  void _pauseGame() {
    setState(() {
      isPaused = true;
    });
    gameTimer?.cancel();
    _fadeController.forward();
  }

  void _resumeGame() {
    setState(() {
      isPaused = false;
    });
    _fadeController.reverse();

    final levelConfig = _getCurrentLevelConfig();
    if (levelConfig.time > 0) {
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && !isGameOver && !isPaused) {
          setState(() {
            if (remainingTime > 0) {
              remainingTime--;
            } else {
              timer.cancel();
              _gameOver(false);
            }
          });
        }
      });
    }
  }

  void _exitGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  GameStatusBar(
                    mode: widget.config.mode,
                    timeRemaining: widget.config.mode == GameMode.classic
                        ? elapsedTime
                        : remainingTime,
                    score: score,
                    highScore: highScore,
                    lives: hp,
                    currentLevel: currentLevel + 1,
                    totalLevels: _getTotalLevels(),
                    progress: cards.isNotEmpty
                        ? matchedPairs /
                              (cards
                                      .where((c) => c.type == CardType.normal)
                                      .length /
                                  2)
                        : 0,
                    onPause: _pauseGame,
                    hasShield: hasShield,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildGameGrid(),
                    ),
                  ),
                ],
              ),

              if (isPaused) _buildPauseOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateCardScaleFactor(int totalCards) {
    if (totalCards <= 4) {
      return 1.2; // Rất lớn cho 4 thẻ
    } else if (totalCards <= 6) {
      return 1.0; // Kích thước bình thường cho 6 thẻ
    } else if (totalCards <= 8) {
      return 0.95; // Nhỏ hơn một chút cho 8 thẻ
    } else if (totalCards <= 10) {
      return 0.90; // Nhỏ hơn cho 10 thẻ
    } else if (totalCards <= 12) {
      return 0.85; // Nhỏ hơn nữa cho 12 thẻ
    } else {
      return 0.75; // Rất nhỏ cho 16+ thẻ
    }
  }

  (int rows, int cols) _calculateGridSize(int totalCards) {
    final Map<int, (int, int)> commonLayouts = {
      4: (2, 2),
      6: (2, 3),
      8: (2, 4),
      10: (2, 5),
      12: (3, 4),
      16: (4, 4),
      20: (4, 5),
      24: (4, 6),
    };

    if (commonLayouts.containsKey(totalCards)) {
      return commonLayouts[totalCards]!;
    }

    final cols = sqrt(totalCards).ceil();
    final rows = (totalCards / cols).ceil();
    return (rows, cols);
  }

  Widget _buildGameGrid() {
    if (cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(GameThemeData.primaryColor),
        ),
      );
    }

    final totalCards = cards.length;
    final (rows, cols) = _calculateGridSize(totalCards);
    const double spacing = 8.0;
    const double minCardSize = 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final cardWidth = (maxWidth - (cols - 1) * spacing) / cols;
        final cardHeight = (maxHeight - (rows - 1) * spacing) / rows;
        final cardSize = cardWidth < cardHeight ? cardWidth : cardHeight;

        // Determine if scrolling is needed
        final needsScroll = cardSize < minCardSize;
        final effectiveCardSize = needsScroll ? minCardSize : cardSize;

        // **NEW: Calculate scale factor based on card count**
        final scaleFactor = _calculateCardScaleFactor(totalCards);
        final scaledCardSize = effectiveCardSize * scaleFactor;

        return Center(
          child: GridView.builder(
            shrinkWrap: !needsScroll,
            physics: needsScroll
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              // **UPDATED: Use scaledCardSize for centered positioning**
              horizontal: needsScroll
                  ? 0
                  : (maxWidth - cols * scaledCardSize - (cols - 1) * spacing) /
                        2,
              vertical: needsScroll
                  ? 0
                  : (maxHeight - rows * scaledCardSize - (rows - 1) * spacing) /
                        2,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];

              // **NEW: Return card with scaled size**
              return Transform.scale(
                scale: scaleFactor,
                child: GameCard(
                  imageAsset: card.imagePath,
                  isFlipped: card.isFlipped,
                  isMatched: card.isMatched,
                  isEnabled: !isChecking && !isPaused && !isGameOver,
                  onTap: () => _onCardTapped(card),
                  cardType: card.type,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPauseOverlay() {
    final totalLevels = _getTotalLevels();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1a237e), const Color(0xFF0d47a1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: GameThemeData.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Trò chơi tạm dừng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Level ${currentLevel + 1}/$totalLevels',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.stars_rounded, 'Điểm', '$score'),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem(Icons.swap_horiz, 'Lần lật', '$moves'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resumeGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameThemeData.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _exitGame,
                child: Text(
                  'Về Menu',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelConfig {
  final int pairs;
  final int time;
  final (int, int) gridSize;
  final int? hp;
  final int specialCards;

  const LevelConfig({
    required this.pairs,
    required this.time,
    required this.gridSize,
    this.hp,
    this.specialCards = 0,
  });
}
