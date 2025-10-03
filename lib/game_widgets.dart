// lib/game_widgets.dart - Updated version

import 'package:flutter/material.dart';
import 'game_modes.dart';
import 'game_theme.dart';
import 'card_model.dart';

class GameStatusBar extends StatelessWidget {
  final GameMode mode;
  final int timeRemaining;
  final int score;
  final int highScore;
  final int lives;
  final int currentLevel;
  final int totalLevels;
  final double progress;
  final VoidCallback onPause;
  final bool hasShield;

  const GameStatusBar({
    Key? key,
    required this.mode,
    required this.timeRemaining,
    required this.score,
    required this.highScore,
    required this.lives,
    required this.currentLevel,
    this.totalLevels = 5,
    required this.progress,
    required this.onPause,
    this.hasShield = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Top row: Score, Level, Pause
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Score',
                          style: GameThemeData.statusTextStyle.copyWith(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$score',
                      style: GameThemeData.statusTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (highScore > 0)
                      Text(
                        'Best: $highScore',
                        style: GameThemeData.statusTextStyle.copyWith(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),

              // Level indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: GameThemeData.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: GameThemeData.primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'LEVEL',
                      style: GameThemeData.statusTextStyle.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '$currentLevel/$totalLevels',
                      style: GameThemeData.statusTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GameThemeData.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Pause button
              GestureDetector(
                onTap: onPause,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row: Time/Lives and Progress
          Row(
            children: [
              // Time or Lives display
              Expanded(
                child: mode == GameMode.survival
                    ? _buildLivesDisplay()
                    : _buildTimeDisplay(),
              ),

              const SizedBox(width: 12),

              // Shield indicator
              if (hasShield)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GameThemeData.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: GameThemeData.accentColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: GameThemeData.accentColor,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final isLowTime = timeRemaining < 20 && mode != GameMode.classic;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLowTime
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowTime ? Colors.red : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: isLowTime ? Colors.red : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            mode == GameMode.classic ? 'Time: $timeString' : timeString,
            style: GameThemeData.statusTextStyle.copyWith(
              color: isLowTime ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivesDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: lives <= 1
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lives <= 1 ? Colors.red : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            color: lives <= 1 ? Colors.red : Colors.pink,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'HP: $lives',
            style: GameThemeData.statusTextStyle.copyWith(
              color: lives <= 1 ? Colors.red : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GameThemeData.statusTextStyle.copyWith(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GameThemeData.statusTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: GameThemeData.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(GameThemeData.primaryColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class GameCard extends StatefulWidget {
  final String imageAsset;
  final bool isFlipped;
  final bool isMatched;
  final bool isEnabled;
  final VoidCallback onTap;
  final CardType cardType;

  const GameCard({
    Key? key,
    required this.imageAsset,
    required this.isFlipped,
    required this.isMatched,
    required this.isEnabled,
    required this.onTap,
    this.cardType = CardType.normal,
  }) : super(key: key);

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _controller.forward();
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedOpacity(
        opacity: widget.isMatched ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * 3.14159;
            final isShowingFront = angle > 1.5708;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isShowingFront
                  ? _buildFrontSide()
                  : _buildBackSide(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getCardBorderColor(),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCardBorderColor().withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Card image
              Positioned.fill(
                child: Image.asset(
                  widget.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: GameThemeData.primaryColor,
                      child: Icon(
                        _getCardIcon(),
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),

              // Overlay for special cards
              if (widget.cardType != CardType.normal)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCardBorderColor().withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Icon badge for special cards
              if (widget.cardType != CardType.normal)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getCardBorderColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCardBorderColor().withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCardIcon(),
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        gradient: GameThemeData.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameThemeData.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.help_outline_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Color _getCardBorderColor() {
    switch (widget.cardType) {
      case CardType.bomb:
        return Colors.red;
      case CardType.ice:
        return Colors.cyan;
      case CardType.bonus:
        return GameThemeData.primaryColor; // Changed from Colors.amber to remove yellow border
      case CardType.shield:
        return Colors.green;
      default:
        return GameThemeData.primaryColor;
    }
  }

  IconData _getCardIcon() {
    switch (widget.cardType) {
      case CardType.bomb:
        return Icons.warning_rounded;
      case CardType.ice:
        return Icons.ac_unit_rounded;
      case CardType.bonus:
        return Icons.stars_rounded;
      case CardType.shield:
        return Icons.shield_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class GameResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final int score;
  final int time;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const GameResultDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.score,
    required this.time,
    required this.onPlayAgain,
    required this.onBackToMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: GameThemeData.cardGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GameThemeData.titleTextStyle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GameThemeData.statusTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Score:', style: GameThemeData.statusTextStyle),
                      Text(
                        '$score',
                        style: GameThemeData.statusTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: GameThemeData.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time:', style: GameThemeData.statusTextStyle),
                      Text(
                        '${time}s',
                        style: GameThemeData.statusTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: GameThemeData.primaryButtonStyle,
                    child: const Text('Play Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBackToMenu,
                    style: GameThemeData.secondaryButtonStyle,
                    child: const Text('Menu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}