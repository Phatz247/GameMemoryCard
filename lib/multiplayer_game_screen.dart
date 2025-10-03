// lib/multiplayer_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'card_model.dart';
import 'game_theme.dart';
import 'game_widgets.dart';
import 'multiplayer_service.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final GameRoom room;
  final bool isHost;

  const MultiplayerGameScreen({
    Key? key,
    required this.room,
    required this.isHost,
  }) : super(key: key);

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  List<CardItem> cards = [];
  Map<String, int> scores = {};
  String currentTurn = '';
  int myScore = 0;
  int opponentScore = 0;
  bool isMyTurn = false;
  bool isChecking = false;
  int moves = 0;
  int matchedPairs = 0;
  Timer? gameTimer;
  int elapsedTime = 0;

  StreamSubscription? _gameStateSubscription;

  final List<String> allImages = [
    'assets/hinh1.jpg', 'assets/hinh2.jpg', 'assets/hinh3.jpg', 'assets/hinh4.jpg',
    'assets/hinh5.jpg', 'assets/hinh6.jpg', 'assets/hinh7.jpg', 'assets/hinh8.jpg',
    'assets/hinh9.jpg', 'assets/hinh10.jpg', 'assets/hinh11.jpg', 'assets/hinh12.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _setupGame();
    _listenToGameState();

    // Start timer
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          elapsedTime++;
        });
      }
    });
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel();
    gameTimer?.cancel();
    MultiplayerService.leaveRoom(widget.room.roomId, MultiplayerService.currentUserId);
    super.dispose();
  }

  void _setupGame() {
    final pairs = [4, 6, 8, 10, 12][widget.room.level - 1];
    final currentImages = allImages.take(pairs).toList();

    final List<CardItem> newCards = [];
    for (int i = 0; i < pairs; i++) {
      newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
      newCards.add(CardItem(iconIndex: i, imagePath: currentImages[i]));
    }

    newCards.shuffle();

    setState(() {
      cards = newCards;
      currentTurn = widget.room.hostId;
      isMyTurn = widget.isHost;
      scores = {
        widget.room.hostId: 0,
        widget.room.guestId!: 0,
      };
    });
  }

  void _listenToGameState() {
    _gameStateSubscription = MultiplayerService.watchGameState(widget.room.roomId).listen((state) {
      if (!mounted) return;

      final lastAction = state['lastAction'] as Map?;
      if (lastAction != null) {
        _handleRemoteAction(lastAction);
      }

      // Update scores
      final scoresData = state['scores'] as Map?;
      if (scoresData != null) {
        setState(() {
          myScore = (scoresData[MultiplayerService.currentUserId] ?? 0) as int;
          final opponentId = widget.isHost ? widget.room.guestId : widget.room.hostId;
          opponentScore = (scoresData[opponentId] ?? 0) as int;
        });
      }
    });
  }

  void _handleRemoteAction(Map action) {
    final actionPlayerId = action['playerId'] as String?;

    // Ignore own actions
    if (actionPlayerId == MultiplayerService.currentUserId) return;

    final actionType = action['type'] as String?;
    final cardId = action['cardId'] as String?;

    if (actionType == 'flip' && cardId != null) {
      // Find and flip the card
      final cardIndex = int.tryParse(cardId);
      if (cardIndex != null && cardIndex < cards.length) {
        setState(() {
          cards[cardIndex].isFlipped = true;
        });
      }
    }
  }

  Future<void> _onCardTapped(CardItem card) async {
    if (!isMyTurn || card.isFlipped || card.isMatched || isChecking) return;

    final cardIndex = cards.indexOf(card);

    setState(() {
      card.isFlipped = true;
      moves++;
    });

    // Notify other player
    await MultiplayerService.flipCard(
      widget.room.roomId,
      cardIndex.toString(),
      MultiplayerService.currentUserId,
    );

    // Check for match
    final flippedCards = cards.where((c) => c.isFlipped && !c.isMatched).toList();

    if (flippedCards.length == 2) {
      setState(() {
        isChecking = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (flippedCards[0].imagePath == flippedCards[1].imagePath) {
        // Match found!
        setState(() {
          flippedCards[0].isMatched = true;
          flippedCards[1].isMatched = true;
          matchedPairs++;
          myScore += 100;
        });

        // Update score
        await MultiplayerService.updateScore(
          widget.room.roomId,
          MultiplayerService.currentUserId,
          myScore,
        );

        // Keep turn if matched
      } else {
        // No match
        setState(() {
          flippedCards[0].isFlipped = false;
          flippedCards[1].isFlipped = false;
          // Switch turn
          isMyTurn = !isMyTurn;
        });
      }

      setState(() {
        isChecking = false;
      });

      // Check if game ended
      _checkGameEnd();
    }
  }

  void _checkGameEnd() {
    final totalPairs = cards.length ~/ 2;

    if (matchedPairs >= totalPairs) {
      _showEndGameDialog();
    }
  }

  void _showEndGameDialog() {
    final didWin = myScore > opponentScore;
    final isDraw = myScore == opponentScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDraw ? '🤝 Hòa!' : (didWin ? '🎉 Bạn Thắng!' : '😢 Bạn Thua!'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                        Text(
                          'Bạn:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$myScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đối thủ:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$opponentScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameThemeData.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Về Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Thoát game?'),
                            content: const Text('Bạn có chắc muốn rời khỏi trận đấu?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Không'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('Có'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isMyTurn ? 'Lượt của bạn' : 'Lượt đối thủ',
                            style: TextStyle(
                              color: isMyTurn ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${elapsedTime}s',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Score bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Bạn',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$myScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Đối thủ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$opponentScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Game grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildGameGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final cols = (totalCards / 2).ceil();
    const double spacing = 8.0;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return GameCard(
          imageAsset: card.imagePath,
          isFlipped: card.isFlipped,
          isMatched: card.isMatched,
          isEnabled: isMyTurn && !isChecking && !card.isFlipped && !card.isMatched,
          onTap: () => _onCardTapped(card),
          cardType: card.type,
        );
      },
    );
  }
}

