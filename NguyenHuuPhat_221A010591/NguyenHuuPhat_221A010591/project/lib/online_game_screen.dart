import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'online_game_service.dart';
import 'time_sync_service.dart';
import 'chat_message.dart';

class OnlineGameScreen extends StatefulWidget {
  final OnlineGameRoom room;
  final String playerName;

  const OnlineGameScreen({
    Key? key,
    required this.room,
    required this.playerName,
  }) : super(key: key);

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final OnlineGameService _gameService = OnlineGameService();
  final TimeSyncService _timeSyncService = TimeSyncService();

  late String myPlayerId;
  late bool isP1;
  Timer? gameTimer;
  int remainingTime = 90;
  bool gameEnded = false;
  bool _timeSyncInitialized = false;
  OnlineGameRoom? _latestRoom;

  // Chat
  final TextEditingController _chatController = TextEditingController();
  bool _chatExpanded = false;

  @override
  void initState() {
    super.initState();

    // Lấy UID thực từ Firebase Auth để xác định chính xác người chơi
    final user = FirebaseAuth.instance.currentUser;
    myPlayerId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    print('🎮 My Player ID: $myPlayerId');
    print('🎮 Room P1 UID: ${widget.room.p1?.uid}');
    print('🎮 Room P2 UID: ${widget.room.p2?.uid}');

    // Xác định xem mình là P1 hay P2
    isP1 = widget.room.p1?.uid == myPlayerId;

    print('🎮 Am I P1? $isP1');

    _initializeTimeSync();
  }

  Future<void> _initializeTimeSync() async {
    try {
      print('🔄 Đang khởi tạo đồng bộ thời gian...');
      await _timeSyncService.initialize();
      if (mounted) {
        setState(() {
          _timeSyncInitialized = true;
          if (_latestRoom != null) {
            remainingTime = _latestRoom!.getRemainingTime();
            print('✅ Đồng bộ thời gian thành công!');
            print('   Offset: ${_timeSyncService.currentOffset}ms');
            print('   Thời gian còn lại: $remainingTime giây');
          }
        });
      }
    } catch (e) {
      print('❌ Lỗi khi khởi tạo đồng bộ thời gian: $e');
      // Fallback: vẫn cho phép chơi nhưng có thể không đồng bộ hoàn toàn
      if (mounted) {
        setState(() {
          _timeSyncInitialized = true;
        });
      }
    }
  }

  void _startTimer() {
    gameTimer?.cancel();

    print('▶️ Bắt đầu đếm ngược cho ${isP1 ? "P1" : "P2"}');

    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _latestRoom != null) {
        final newRemaining = _latestRoom!.getRemainingTime();
        if (newRemaining != remainingTime) {
          setState(() {
            remainingTime = newRemaining;
          });
        }

        if (remainingTime <= 0) {
          timer.cancel();
          if (!gameEnded) {
            setState(() {
              gameEnded = true;
            });
            _handleTimeUp();
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTimeUp() {
    gameTimer?.cancel();
    if (!gameEnded && mounted) {
      print('⏰ Hết giờ! Kết thúc game...');
      gameEnded = true;

      if (isP1) {
        _gameService.endGame(widget.room.roomId);
      }

      // So sánh điểm
      final p1Score = _latestRoom?.p1?.score ?? 0;
      final p2Score = _latestRoom?.p2?.score ?? 0;

      String resultText;
      String winner;

      if (p1Score > p2Score) {
        resultText =
            '${_latestRoom?.p1?.name ?? "Người chơi 1"} thắng!\n${p1Score} điểm vs ${p2Score} điểm';
        winner = _latestRoom?.p1?.uid ?? '';
      } else if (p2Score > p1Score) {
        resultText =
            '${_latestRoom?.p2?.name ?? "Người chơi 2"} thắng!\n${p2Score} điểm vs ${p1Score} điểm';
        winner = _latestRoom?.p2?.uid ?? '';
      } else {
        resultText = 'Hòa!\n${p1Score} điểm - ${p2Score} điểm';
        winner = '';
      }

      _showGameResultDialog(resultText, winner);
    }
  }

  void _showGameResultDialog(String resultText, String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Kết thúc trận',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Điểm chi tiết
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _latestRoom?.p1?.name ?? 'P1',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_latestRoom?.p1?.score ?? 0}',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _latestRoom?.p2?.name ?? 'P2',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_latestRoom?.p2?.score ?? 0}',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Thoát', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64ffda),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showRematchDialog();
            },
            child: const Text(
              'Chơi lại',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showOpponentDisconnectDialog() {
    if (gameEnded) return;
    gameEnded = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          '⚠️ Đối thủ đã rời',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Đối thủ đã mất kết nối. Trận đấu kết thúc.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Về menu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRematchDialog() {
    _gameService.requestRematch(widget.room.roomId, myPlayerId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<OnlineGameRoom?>(
        stream: _gameService.watchRoom(widget.room.roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              title: const Text(
                'Đề nghị chơi lại',
                style: TextStyle(color: Colors.white),
              ),
              content: const CircularProgressIndicator(),
            );
          }

          final room = snapshot.data!;
          final p1Agreed = room.rematchRequests['p1'] ?? false;
          final p2Agreed = room.rematchRequests['p2'] ?? false;
          final bothAgreed = p1Agreed && p2Agreed;

          if (bothAgreed && mounted) {
            // Cả hai đồng ý, reset game
            Future.microtask(() async {
              Navigator.pop(context);
              Navigator.pop(context);

              // Reset trạng thái game
              gameEnded = false;
              remainingTime = widget.room.timeLimit;
              gameTimer?.cancel();
              gameTimer = null;

              // Reset Firestore room
              await _gameService.resetForRematch(widget.room.roomId);

              // Re-initialize time sync
              _timeSyncInitialized = false;
              await _initializeTimeSync();
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Text(
              'Đề nghị chơi lại',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chờ đối thủ đồng ý chơi lại...',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            room.hostName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: p1Agreed
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              border: Border.all(
                                color: p1Agreed ? Colors.green : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p1Agreed ? '✓ Đồng ý' : 'Chờ...',
                              style: TextStyle(
                                color: p1Agreed ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            room.guestName ?? 'Đối thủ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: p2Agreed
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              border: Border.all(
                                color: p2Agreed ? Colors.green : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p2Agreed ? '✓ Đồng ý' : 'Chờ...',
                              style: TextStyle(
                                color: p2Agreed ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _gameService.cancelRematchRequest(
                    widget.room.roomId,
                    myPlayerId,
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Hủy', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onCardTap(int cardIndex) async {
    if (gameEnded) {
      print('Trò chơi đã kết thúc, không thể chọn thẻ');
      return;
    }

    print('Đã chọn thẻ: $cardIndex');
    await _gameService.flipCard(widget.room.roomId, cardIndex, myPlayerId);
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    await _gameService.sendChatMessage(
      widget.room.roomId,
      myPlayerId,
      widget.playerName,
      message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rời phòng?'),
            content: const Text('Bạn có chắc muốn rời khỏi trận đấu?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ở lại'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Rời đi'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0a0e27), Color(0xFF1a1f3a), Color(0xFF0f172a)],
            ),
          ),
          child: SafeArea(
            child: StreamBuilder<OnlineGameRoom?>(
              stream: _gameService.watchRoom(widget.room.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  );
                }
                final room = snapshot.data!;

                // Lấy remainingTime từ room (đã đồng bộ với server)
                final currentRemainingTime = _timeSyncInitialized
                    ? room.getRemainingTime()
                    : remainingTime;

                // Auto-end nếu hết giờ
                if (currentRemainingTime == 0 &&
                    !gameEnded &&
                    room.status == RoomStatus.playing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _handleTimeUp();
                  });
                }

                // Bắt đầu timer khi có đủ 2 người
                if (room.status == RoomStatus.playing &&
                    gameTimer == null &&
                    room.startTime != null &&
                    _timeSyncInitialized) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _startTimer();
                    }
                  });
                }

                // Kiểm tra game kết thúc
                // NOTE: Dialog sẽ được show bởi _handleTimeUp() thông qua _showGameResultDialog()
                // Nên không cần gọi _showGameOverDialog() ở đây
                // if (room.status == RoomStatus.finished && !gameEnded) {
                //   WidgetsBinding.instance.addPostFrameCallback((_) {
                //     if (mounted) {
                //       _showGameOverDialog(room);
                //     }
                //   });
                // }

                // Kiểm tra đối thủ rời phòng
                final opponentConnected = isP1
                    ? room.p2 != null
                    : room.p1 != null;

                if (room.status == RoomStatus.playing &&
                    !opponentConnected &&
                    !gameEnded &&
                    mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showOpponentDisconnectDialog();
                    }
                  });
                }

                final myScore = isP1 ? room.hostScore : room.guestScore;
                final opponentScore = isP1 ? room.guestScore : room.hostScore;
                final myName = isP1
                    ? (room.p1?.name ?? 'Đang chờ...')
                    : (room.p2?.name ?? 'Đang chờ...');
                final opponentName = isP1
                    ? (room.p2?.name ?? 'Đang chờ...')
                    : (room.p1?.name ?? 'Đang chờ...');
                final isMyTurn =
                    (isP1 && room.currentTurn == 'p1') ||
                    (!isP1 && room.currentTurn == 'p2');

                _latestRoom = room; // Cập nhật room mới nhất

                return Column(
                  children: [
                    _buildHeader(
                      room,
                      myScore,
                      myName,
                      opponentScore,
                      opponentName,
                      isMyTurn,
                      currentRemainingTime,
                    ),
                    if (room.status == RoomStatus.waiting && room.p2 == null)
                      Expanded(child: _buildWaitingScreen(room))
                    else
                      Expanded(child: _buildGameGrid(room, isMyTurn)),
                    // Chat button ở dưới
                    _buildChatToggleButton(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    OnlineGameRoom room,
    int myScore,
    String myName,
    int opponentScore,
    String opponentName,
    bool isMyTurn,
    int currentRemainingTime,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Room ID và timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Text(
                  'Room: ${room.roomId}',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: currentRemainingTime < 30
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentRemainingTime < 30
                        ? Colors.red
                        : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '$currentRemainingTime s',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Players info
          Row(
            children: [
              Expanded(
                child: _buildPlayerCard(myName, myScore, isMyTurn, true),
              ),
              SizedBox(width: 16),
              Icon(Icons.people, color: Colors.white70, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: _buildPlayerCard(
                  opponentName,
                  opponentScore,
                  !isMyTurn,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String name, int score, bool isActive, bool isMe) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.orange.withValues(alpha: 0.3),
                ]
              : [
                  Colors.grey.withValues(alpha: 0.2),
                  Colors.grey.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.amber : Colors.white24,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            '$score',
            style: GoogleFonts.orbitron(
              color: isActive ? Colors.amber : Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive)
            Text(
              'Lượt chơi',
              style: GoogleFonts.poppins(color: Colors.amber, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen(OnlineGameRoom room) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(Icons.person_search, size: 80, color: Colors.blue),
          ),
          SizedBox(height: 30),
          Text(
            'Đang chờ đối thủ...',
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Mã phòng: ${room.roomId}',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Chia sẻ mã này với bạn bè!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
          ),
          SizedBox(height: 30),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(OnlineGameRoom room, bool isMyTurn) {
    final cards = room.cards;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return _buildCard(card, index, isMyTurn);
        },
      ),
    );
  }

  Widget _buildCard(GameCard card, int index, bool isMyTurn) {
    final isFlipped = card.flipped || card.matched;

    return GestureDetector(
      onTap: () {
        if (!isMyTurn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chưa đến lượt bạn!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (!card.flipped && !card.matched) {
          _onCardTap(index);
        }
      },
      child: _FlipCard(
        isFlipped: isFlipped,
        isMatched: card.matched,
        imageAsset: 'assets/img/${card.image}',
      ),
    );
  }

  Widget _buildChatToggleButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _chatExpanded = !_chatExpanded;
              });
              if (_chatExpanded) {
                _showChatDrawer();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          border: Border(
            top: BorderSide(
              color: Colors.blue.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            // Chat messages
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _gameService.watchChatMessages(widget.room.roomId),
                builder: (context, snapshot) {
                  List<ChatMessage> messages = snapshot.data ?? [];

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == myPlayerId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blue.withValues(alpha: 0.6)
                                : Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.senderName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.message,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendChatMessage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.6),
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }
}

class _FlipCard extends StatefulWidget {
  final bool isFlipped;
  final bool isMatched;
  final String imageAsset;

  const _FlipCard({
    required this.isFlipped,
    required this.isMatched,
    required this.imageAsset,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
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
    return AnimatedOpacity(
      opacity: widget.isMatched ? 0.3 : 1.0,
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.isMatched
                        ? Colors.green.withValues(alpha: 0.5)
                        : (isShowingFront
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.black26),
                    blurRadius: widget.isMatched ? 15 : 8,
                    spreadRadius: widget.isMatched ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isShowingFront ? _buildFrontSide() : _buildBackSide(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Image.asset(
        widget.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blue.withValues(alpha: 0.3),
            child: Center(child: Icon(Icons.image, color: Colors.white)),
          );
        },
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.help_outline,
          color: Colors.white.withValues(alpha: 0.5),
          size: 30,
        ),
      ),
    );
  }
}
