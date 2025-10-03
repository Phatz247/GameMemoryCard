// lib/game_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'card_model.dart';
import 'game_modes.dart';
import 'game_theme.dart';
import 'game_widgets.dart';
import 'bottom_navigation.dart';
import 'leaderboard_screen.dart';
import 'leaderboard_service.dart';
import 'player_score.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';
import 'shop_screen.dart';
import 'inventory_screen.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({Key? key, required this.config}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game state variables
  int score = 0;
  int combo = 0;
  int hp = 0;
  int highScore = 0;
  bool hasShield = false;
  bool isPaused = false;
  int _currentNavIndex = 0;

  // Cấu hình cho từng chế độ game
  final Map<GameMode, List<LevelConfig>> levelConfigs = {
    GameMode.classic: [
      LevelConfig(pairs: 4, time: 120, gridSize: (2, 4)),   // Level 1: 2x4 (8 cards)
      LevelConfig(pairs: 6, time: 150, gridSize: (2, 6)),   // Level 2: 2x6 (12 cards)
      LevelConfig(pairs: 8, time: 180, gridSize: (2, 8)),   // Level 3: 2x8 (16 cards)
      LevelConfig(pairs: 10, time: 210, gridSize: (2, 10)), // Level 4: 2x10 (20 cards)
      LevelConfig(pairs: 12, time: 240, gridSize: (3, 8)),  // Level 5: 3x8 (24 cards)
    ],
    GameMode.timeAttack: [
      LevelConfig(pairs: 4, time: 45, gridSize: (2, 4)),    // Level 1: 45s
      LevelConfig(pairs: 6, time: 60, gridSize: (2, 6)),    // Level 2: 60s
      LevelConfig(pairs: 8, time: 75, gridSize: (2, 8)),    // Level 3: 75s
      LevelConfig(pairs: 10, time: 90, gridSize: (2, 10)),  // Level 4: 90s
      LevelConfig(pairs: 12, time: 105, gridSize: (3, 8)),  // Level 5: 105s
    ],
    GameMode.survival: [
      LevelConfig(pairs: 4, time: -1, gridSize: (2, 4), hp: 5),   // Level 1: 5 HP
      LevelConfig(pairs: 6, time: -1, gridSize: (2, 6), hp: 5),   // Level 2: 5 HP
      LevelConfig(pairs: 8, time: -1, gridSize: (2, 8), hp: 4),   // Level 3: 4 HP
      LevelConfig(pairs: 10, time: -1, gridSize: (2, 10), hp: 4), // Level 4: 4 HP
      LevelConfig(pairs: 12, time: -1, gridSize: (3, 8), hp: 3),  // Level 5: 3 HP
    ],
    GameMode.challenge: [
      LevelConfig(pairs: 4, time: 90, gridSize: (2, 4), specialCards: 1),   // Level 1
      LevelConfig(pairs: 6, time: 120, gridSize: (2, 6), specialCards: 2),  // Level 2
      LevelConfig(pairs: 8, time: 150, gridSize: (2, 8), specialCards: 3),  // Level 3
      LevelConfig(pairs: 10, time: 180, gridSize: (2, 10), specialCards: 4), // Level 4
      LevelConfig(pairs: 12, time: 210, gridSize: (3, 8), specialCards: 5),  // Level 5
    ],
  };

  // Danh sách hình ảnh (đủ cho tất cả levels)
  final List<String> allImages = [
    'assets/hinh1.jpg', 'assets/hinh2.jpg', 'assets/hinh3.jpg', 'assets/hinh4.jpg',
    'assets/hinh5.jpg', 'assets/hinh6.jpg', 'assets/hinh7.jpg', 'assets/hinh8.jpg',
    'assets/hinh9.jpg', 'assets/hinh10.jpg', 'assets/hinh11.jpg', 'assets/hinh12.jpg',
    'assets/hinh13.png', 'assets/hinh14.jpg', 'assets/hinh15.jpg', 'assets/hinh16.jpg',
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHighScore();
    _setupGame();

    if (widget.config.mode == GameMode.survival) {
      hp = _getCurrentLevelConfig().hp ?? 5;
    }
  }

  LevelConfig _getCurrentLevelConfig() {
    final configs = levelConfigs[widget.config.mode] ?? levelConfigs[GameMode.classic]!;
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

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
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

      // Start timer
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
            // Delay để đảm bảo UI đã update
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

      // Generate cards
      final List<CardItem> newCards = [];
      final currentImages = allImages.take(levelConfig.pairs).toList();

      for (int i = 0; i < levelConfig.pairs; i++) {
        newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
        newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
      }

      // Add special cards for challenge mode
      if (widget.config.mode == GameMode.challenge && levelConfig.specialCards > 0) {
        for (int i = 0; i < levelConfig.specialCards; i++) {
          if (i == 0) {
            newCards.add(CardItem(
              iconIndex: -1,
              imagePath: 'assets/bomb.png',
              type: CardType.bomb,
            ));
          } else if (i == 1) {
            newCards.add(CardItem(
              iconIndex: -2,
              imagePath: 'assets/ice.png',
              type: CardType.ice,
            ));
          } else if (i == 2) {
            newCards.add(CardItem(
              iconIndex: -3,
              imagePath: 'assets/bonus.png',
              type: CardType.bonus,
            ));
          } else if (i == 3) {
            newCards.add(CardItem(
              iconIndex: -4,
              imagePath: 'assets/shield.png',
              type: CardType.shield,
            ));
          }
        }
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
    if (widget.config.mode == GameMode.classic) return;

    final prefs = await SharedPreferences.getInstance();
    final playerName = prefs.getString('current_user') ?? 'Unknown';

    final playerScore = PlayerScore(
      playerName: playerName,
      score: this.score,
      moves: moves,
      timeSpent: remainingTime > 0 ?
      _getCurrentLevelConfig().time - remainingTime : elapsedTime,
      playedAt: DateTime.now(),
    );

    await LeaderboardService.saveScore(
      widget.config.mode,
      currentLevel + 1,
      playerScore,
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
                colors: [
                  const Color(0xFF1a237e),
                  const Color(0xFF0d47a1),
                ],
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
                  child: const Text(
                    '🎉',
                    style: TextStyle(fontSize: 48),
                  ),
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
                                final prefs = await SharedPreferences.getInstance();
                                final playerName = prefs.getString('current_user') ?? 'Unknown';
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
                                side: const BorderSide(color: Colors.white, width: 1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                              side: const BorderSide(color: Colors.white, width: 1),
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
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
                  colors: [
                    const Color(0xFF1a237e),
                    const Color(0xFF0d47a1),
                  ],
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
                    child: const Text(
                      '😢',
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Game Over',
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
                            _buildStatItem(Icons.swap_horiz, 'Lần lật', '$moves'),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(Icons.check_circle, 'Đã ghép', '$matchedPairs'),
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

    // Handle special cards
    if (widget.config.mode == GameMode.challenge) {
      if (card.type == CardType.bomb) {
        _handleBombCard(card);
        return;
      } else if (card.type == CardType.ice) {
        _handleIceCard(card);
        return;
      } else if (card.type == CardType.bonus) {
        _handleBonusCard(card);
        return;
      } else if (card.type == CardType.shield) {
        _handleShieldCard(card);
        return;
      }
    }

    setState(() {
      card.isFlipped = true;
    });

    if (firstFlippedCard == null) {
      firstFlippedCard = card;
    } else if (secondFlippedCard == null) {
      secondFlippedCard = card;
      _checkMatch();
    }
  }

  void _handleBombCard(CardItem card) {
    setState(() {
      card.isFlipped = true;
      card.isMatched = true;
      if (hasShield) {
        hasShield = false;
        score += 50; // Bonus for blocking bomb
      } else {
        score = (score - 200).clamp(0, 999999);
        if (widget.config.mode == GameMode.survival) {
          hp--;
          if (hp <= 0) _gameOver(false);
        }
      }
    });
  }

  void _handleIceCard(CardItem card) {
    setState(() {
      card.isFlipped = true;
      card.isMatched = true;
      isChecking = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    });
  }

  void _handleBonusCard(CardItem card) {
    setState(() {
      card.isFlipped = true;
      card.isMatched = true;
      score += 300;
    });
    _updateHighScore();
  }

  void _handleShieldCard(CardItem card) {
    setState(() {
      card.isFlipped = true;
      card.isMatched = true;
      hasShield = true;
    });
  }

  void _checkMatch() {
    if (firstFlippedCard == null || secondFlippedCard == null) return;

    setState(() {
      isChecking = true;
      moves++;
    });

    Timer(const Duration(milliseconds: 800), () {
      bool isMatch = firstFlippedCard!.imagePath == secondFlippedCard!.imagePath;

      setState(() {
        if (isMatch) {
          firstFlippedCard!.isMatched = true;
          secondFlippedCard!.isMatched = true;
          matchedPairs++;
          _calculateScore(true);
        } else {
          firstFlippedCard!.isFlipped = false;
          secondFlippedCard!.isFlipped = false;
          _handleMismatch();
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
      int timeBonus = widget.config.mode == GameMode.timeAttack ? remainingTime * 2 : 0;
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

    // Count only normal card pairs (exclude special cards)
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

    // Restart timer
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

  void _resetGame() {
    setState(() {
      score = 0;
      combo = 0;
      moves = 0;
      matchedPairs = 0;
      isGameOver = false;
      isPaused = false;
      elapsedTime = 0;
      firstFlippedCard = null;
      secondFlippedCard = null;
      isChecking = false;
      hasShield = false;

      if (widget.config.mode == GameMode.survival) {
        hp = _getCurrentLevelConfig().hp ?? 5;
      }
    });

    _setupGame();
    _fadeController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
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
                      progress: cards.isNotEmpty ? matchedPairs / (cards.where((c) => c.type == CardType.normal).length / 2) : 0,
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
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GameBottomNavigation(
                  currentIndex: _currentNavIndex,
                  onTap: _onBottomNavTap,
                ),
              ),

              if (isPaused) _buildPauseOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(
              gameMode: widget.config.mode,
              level: currentLevel + 1,
              currentPlayer: 'Current Player',
            ),
          ),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ShopScreen()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
        break;
    }
  }

  // Calculate optimal grid dimensions based on total cards
  (int rows, int cols) _calculateGridSize(int totalCards) {
    // Common card count layouts
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

    // Auto-fit for non-standard counts
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

        // Calculate card dimensions
        final cardWidth = (maxWidth - (cols - 1) * spacing) / cols;
        final cardHeight = (maxHeight - (rows - 1) * spacing) / rows;
        final cardSize = cardWidth < cardHeight ? cardWidth : cardHeight;

        // Determine if scrolling is needed
        final needsScroll = cardSize < minCardSize;
        final effectiveCardSize = needsScroll ? minCardSize : cardSize;

        return Center(
          child: GridView.builder(
            shrinkWrap: !needsScroll,
            physics: needsScroll
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: needsScroll ? 0 : (maxWidth - cols * effectiveCardSize - (cols - 1) * spacing) / 2,
              vertical: needsScroll ? 0 : (maxHeight - rows * effectiveCardSize - (rows - 1) * spacing) / 2,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.0, // Keep cards square
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return GameCard(
                imageAsset: card.imagePath,
                isFlipped: card.isFlipped,
                isMatched: card.isMatched,
                isEnabled: !isChecking && !isPaused && !isGameOver,
                onTap: () => _onCardTapped(card),
                cardType: card.type,
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
              colors: [
                const Color(0xFF1a237e),
                const Color(0xFF0d47a1),
              ],
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
                'Game Paused',
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

// Level configuration class
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
