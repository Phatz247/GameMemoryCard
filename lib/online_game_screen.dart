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
  static const int _maxPausePerPlayer = 3;
  final OnlineGameService _gameService = OnlineGameService();
  final TimeSyncService _timeSyncService = TimeSyncService();

  late String myPlayerId;
  late bool isP1;
  Timer? gameTimer;
  int remainingTime = 90;
  bool gameEnded = false;
  bool _timeSyncInitialized = false;
  OnlineGameRoom? _latestRoom;
  bool _timeUpWarningShown = false; // Để tránh show warning nhiều lần
  bool _timeUpHandled = false; // Để tránh gọi _handleTimeUp nhiều lần
  bool _isPaused = false;
  String? _lastHandledDepartureRole;
  bool _isProcessingDeparture = false;
  bool _pauseRequestInProgress = false;
  String? _currentPauseBy;

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

  Future<bool> _confirmLeaveGame() async {
    final result = await showDialog<bool>(
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

    return result ?? false;
  }

  Future<void> _leaveRoomAndExit() async {
    try {
      await _gameService.leaveRoom(widget.room.roomId, myPlayerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể rời phòng: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _onPausePressed(OnlineGameRoom room) async {
    if (_pauseRequestInProgress || gameEnded) {
      return;
    }

    if (room.status != RoomStatus.playing ||
        room.p1 == null ||
        room.p2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể tạm dừng khi trận đấu đang diễn ra.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final String roleKey = isP1 ? 'p1' : 'p2';
    final int usedCount = room.pauseCounts[roleKey] ?? 0;

    if (usedCount >= _maxPausePerPlayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn chỉ có $_maxPausePerPlayer lần tạm dừng trong trận.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _pauseRequestInProgress = true;
    });

    final int timeBeforePause = room.getRemainingTime();

    try {
      await _gameService.setPauseState(
        roomId: room.roomId,
        playerId: myPlayerId,
        isPaused: true,
      );

      gameTimer?.cancel();
      gameTimer = null;

      if (!mounted) {
        return;
      }

      setState(() {
        _isPaused = true;
        _currentPauseBy = roleKey;
        remainingTime = timeBeforePause;
        _pauseRequestInProgress = false;
      });

      await _showPauseDialog(room, usedCount + 1);
    } on PauseLimitReachedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isEmpty
                  ? 'Bạn đã sử dụng hết $_maxPausePerPlayer lần tạm dừng.'
                  : e.message,
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        setState(() {
          _pauseRequestInProgress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạm dừng: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _pauseRequestInProgress = false;
        });
      }
    }
  }

  Future<void> _showPauseDialog(OnlineGameRoom room, int usedCount) async {
    if (!mounted) return;

    final int remainingPauses = _maxPausePerPlayer - usedCount;
    final int safeRemaining = remainingPauses < 0 ? 0 : remainingPauses;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        title: Row(
          children: const [
            Icon(Icons.pause_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Tạm dừng trận đấu', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trận đấu đã tạm dừng cho cả hai người chơi.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Text(
              'Lần tạm dừng đã sử dụng: $usedCount/$_maxPausePerPlayer',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (safeRemaining > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Bạn còn lại $safeRemaining lần tạm dừng.',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thời gian còn lại: ${remainingTime < 0 ? 0 : remainingTime} giây',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final shouldLeave = await _confirmLeaveGame();
              if (shouldLeave && mounted) {
                await _leaveRoomAndExit();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } else if (mounted) {
                await _onResumePressed(_latestRoom ?? room);
              }
            },
            child: const Text(
              'Rời phòng',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.of(context).pop();
              await _onResumePressed(_latestRoom ?? room);
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _onResumePressed(OnlineGameRoom? room) async {
    final activeRoom = room ?? _latestRoom;
    if (activeRoom == null) {
      return;
    }

    if (_pauseRequestInProgress) {
      return;
    }

    setState(() {
      _pauseRequestInProgress = true;
    });

    final int resumeRemaining =
        activeRoom.pauseRemaining ?? activeRoom.getRemainingTime();

    try {
      await _gameService.setPauseState(
        roomId: activeRoom.roomId,
        playerId: myPlayerId,
        isPaused: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPaused = false;
        _currentPauseBy = null;
        remainingTime = resumeRemaining;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tiếp tục: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pauseRequestInProgress = false;
        });
      }
    }
  }

  Future<void> _handleRoomDeparture(
    OnlineGameRoom room, {
    required bool hostLeft,
  }) async {
    if (_isProcessingDeparture) return;
    _isProcessingDeparture = true;

    try {
      if (hostLeft) {
        await _gameService.promoteGuestToHost(room);
      } else {
        await _gameService.prepareRoomForNewGuest(room);
      }

      if (!mounted) return;

      setState(() {
        gameEnded = false;
        _timeUpHandled = false;
        _isPaused = false;
      });

      final message = hostLeft
          ? 'Bạn hiện là chủ phòng. Đang chờ người chơi mới.'
          : 'Đối thủ đã rời phòng. Đang chờ người chơi mới.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.blueAccent),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật phòng: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isProcessingDeparture = false;
    }
  }

  void _startTimer() {
    gameTimer?.cancel();

    print('▶️ Bắt đầu đếm ngược cho ${isP1 ? "P1" : "P2"}');

    if (_isPaused) {
      print('⏸️ Bỏ qua việc khởi động timer vì đang tạm dừng');
      return;
    }

    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _latestRoom != null) {
        if (_isPaused) {
          timer.cancel();
          return;
        }

        final newRemaining = _latestRoom!.getRemainingTime();
        if (newRemaining != remainingTime) {
          setState(() {
            remainingTime = newRemaining;
          });
        }

        // Warning khi còn 5 giây
        if (remainingTime == 5 && !_timeUpWarningShown) {
          _timeUpWarningShown = true;
          print('⚠️ Còn 5 giây nữa hết giờ!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⏰ Còn 5 giây nữa hết giờ!'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Timer chỉ cập nhật UI, không gọi _handleTimeUp()
        // vì _handleTimeUp() sẽ được gọi từ stream builder (chi ơi một nơi)
        if (remainingTime <= 0) {
          timer.cancel();
          if (!gameEnded && !_timeUpHandled) {
            print('⏰ Timer phát hiện hết giờ, chờ stream builder xử lý...');
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTimeUp() {
    print(
      '📌 _handleTimeUp() được gọi. mounted=$mounted, gameEnded=$gameEnded',
    );

    gameTimer?.cancel();

    if (!mounted) {
      print('❌ Widget không mounted, không thể hiển thị dialog!');
      return;
    }

    if (gameEnded) {
      print('⚠️ Game đã kết thúc, không gọi lại!');
      return;
    }

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

    print('📊 Kết quả: $resultText');
    _showGameResultDialog(resultText, winner);
  }

  void _showGameResultDialog(String resultText, String winner) {
    print('🎯 _showGameResultDialog() được gọi...');

    if (!mounted) {
      print('❌ Lỗi: Widget không mounted, không thể show dialog!');
      return;
    }

    final p1Score = _latestRoom?.p1?.score ?? 0;
    final p2Score = _latestRoom?.p2?.score ?? 0;

    // Xác định kết quả cho người chơi hiện tại
    String myResult = '';
    Color resultColor = Colors.amber;

    if (p1Score == p2Score) {
      myResult = 'HÒA';
      resultColor = Colors.amber;
    } else if ((isP1 && p1Score > p2Score) || (!isP1 && p2Score > p1Score)) {
      myResult = '🎉 THẮNG 🎉';
      resultColor = Colors.green;
    } else {
      myResult = '😢 THUA';
      resultColor = Colors.red;
    }

    print('✅ Hiển thị dialog với kết quả: $myResult');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: resultColor.withOpacity(0.5), width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              Text(
                myResult,
                style: TextStyle(
                  color: resultColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kết thúc trận',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Điểm chi tiết
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Column(
                children: [
                  // Player 1
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isP1
                          ? resultColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isP1
                            ? resultColor.withOpacity(0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _latestRoom?.p1?.name ?? 'Người chơi 1',
                            style: TextStyle(
                              color: isP1 ? resultColor : Colors.white,
                              fontSize: 15,
                              fontWeight: isP1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_latestRoom?.p1?.score ?? 0}',
                          style: TextStyle(
                            color: isP1 ? resultColor : Colors.cyan,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withOpacity(0.2), height: 1),
                  const SizedBox(height: 8),
                  // Player 2
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: !isP1
                          ? resultColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !isP1
                            ? resultColor.withOpacity(0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _latestRoom?.p2?.name ?? 'Người chơi 2',
                            style: TextStyle(
                              color: !isP1 ? resultColor : Colors.white,
                              fontSize: 15,
                              fontWeight: !isP1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_latestRoom?.p2?.score ?? 0}',
                          style: TextStyle(
                            color: !isP1 ? resultColor : Colors.cyan,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Câu hỏi chơi tiếp
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có muốn chơi lại không?',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            child: const Text(
              'Không, thoát',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.replay, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showRematchDialog();
            },
            label: const Text(
              'Chơi lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRematchDialog() {
    _gameService.requestRematch(widget.room.roomId, myPlayerId);

    // Timeout sau 30 giây nếu đối thủ không phản hồi
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Đối thủ không phản hồi. Về menu'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StreamBuilder<OnlineGameRoom?>(
          stream: _gameService.watchRoom(widget.room.roomId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1a1a2e),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text(
                  '⏳ Đề nghị chơi lại',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                content: const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ),
              );
            }

            final room = snapshot.data!;
            final p1Agreed = room.rematchRequests['p1'] ?? false;
            final p2Agreed = room.rematchRequests['p2'] ?? false;
            final bothAgreed = p1Agreed && p2Agreed;

            if (bothAgreed && mounted) {
              // Cả hai đồng ý, reset game
              timeoutTimer?.cancel();
              Future.microtask(() async {
                Navigator.pop(context);
                Navigator.pop(context);

                // Reset trạng thái game
                gameEnded = false;
                remainingTime = widget.room.timeLimit;
                gameTimer?.cancel();
                gameTimer = null;
                _timeUpWarningShown = false; // Reset warning flag
                _timeUpHandled = false; // Reset time up flag

                // Reset Firestore room
                await _gameService.resetForRematch(widget.room.roomId);

                // Re-initialize time sync
                _timeSyncInitialized = false;
                await _initializeTimeSync();
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: bothAgreed
                      ? Colors.green.withOpacity(0.5)
                      : Colors.amber.withOpacity(0.3),
                  width: 2,
                ),
              ),
              title: Center(
                child: Column(
                  children: [
                    Text(
                      bothAgreed ? '✅ Cả hai đã đồng ý!' : '⏳ Chờ đối thủ...',
                      style: TextStyle(
                        color: bothAgreed ? Colors.green : Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đề nghị chơi lại',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status của P1
                  _buildPlayerRematchStatus(
                    playerName: room.hostName,
                    agreed: p1Agreed,
                    isCurrentPlayer: isP1,
                  ),
                  const SizedBox(height: 16),
                  // Status của P2
                  _buildPlayerRematchStatus(
                    playerName: room.guestName ?? 'Đối thủ',
                    agreed: p2Agreed,
                    isCurrentPlayer: !isP1,
                  ),
                  if (bothAgreed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Khởi động trận đấu mới...',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (!bothAgreed)
                  TextButton.icon(
                    onPressed: () {
                      timeoutTimer?.cancel();
                      _gameService.cancelRematchRequest(
                        widget.room.roomId,
                        myPlayerId,
                      );
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ).then((_) {
      timeoutTimer?.cancel();
    });
  }

  Widget _buildPlayerRematchStatus({
    required String playerName,
    required bool agreed,
    required bool isCurrentPlayer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            agreed
                ? Colors.green.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            agreed
                ? Colors.green.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: agreed
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCurrentPlayer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isCurrentPlayer) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: agreed
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: agreed ? Colors.green : Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  agreed ? Icons.check_circle : Icons.schedule,
                  color: agreed ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  agreed ? '✓ Đồng ý' : 'Chờ...',
                  style: TextStyle(
                    color: agreed ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCardTap(int cardIndex) async {
    if (_isPaused) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trò chơi đang tạm dừng'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

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
        final shouldLeave = await _confirmLeaveGame();
        if (shouldLeave == true && mounted) {
          await _leaveRoomAndExit();
          if (mounted) {
            Navigator.of(context).pop();
          }
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
                final room = snapshot.data;

                if (room == null) {
                  Future.microtask(() {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                  return const SizedBox.shrink();
                }

                // Cập nhật trạng thái host hiện tại dựa trên dữ liệu mới nhất
                isP1 = room.p1?.uid == myPlayerId;

                final opponentConnected = isP1
                    ? room.p2 != null
                    : room.p1 != null;

                final hostMissing = room.p1 == null;
                final guestMissing = room.p2 == null;

                if (!opponentConnected) {
                  String? roleToHandle;
                  if (!isP1 &&
                      hostMissing &&
                      room.p2 != null &&
                      room.p2!.uid == myPlayerId) {
                    roleToHandle = 'host';
                  } else if (isP1 && guestMissing) {
                    roleToHandle = 'guest';
                  }

                  if (roleToHandle != null &&
                      _lastHandledDepartureRole != roleToHandle) {
                    _lastHandledDepartureRole = roleToHandle;
                    _handleRoomDeparture(
                      room,
                      hostLeft: roleToHandle == 'host',
                    );
                  }
                } else if (_lastHandledDepartureRole != null) {
                  _lastHandledDepartureRole = null;
                }

                // Lấy remainingTime từ room (đã đồng bộ với server)
                final currentRemainingTime = _timeSyncInitialized
                    ? room.getRemainingTime()
                    : remainingTime;

                // Auto-end nếu hết giờ - CHỈ GỌI MỘT LẦN
                if (currentRemainingTime <= 0 &&
                    !gameEnded &&
                    !_timeUpHandled &&
                    room.status == RoomStatus.playing) {
                  print(
                    '⏰ Phát hiện hết giờ từ stream: remainingTime=$currentRemainingTime',
                  );
                  _timeUpHandled = true; // Mark as handled

                  Future.microtask(() {
                    if (mounted) {
                      print('⏰ Gọi _handleTimeUp() NGAY LẬP TỨC');
                      _handleTimeUp();
                    }
                  });
                }

                // Dừng timer khi không còn chơi
                if (room.status != RoomStatus.playing && gameTimer != null) {
                  gameTimer?.cancel();
                  gameTimer = null;
                }

                // Đồng bộ trạng thái tạm dừng từ server
                if (room.pauseActive) {
                  final int pausedRemaining =
                      room.pauseRemaining ?? currentRemainingTime;
                  if (!_isPaused || remainingTime != pausedRemaining) {
                    gameTimer?.cancel();
                    gameTimer = null;
                    _isPaused = true;
                    remainingTime = pausedRemaining;
                  }
                } else if (_isPaused) {
                  _isPaused = false;
                  remainingTime = currentRemainingTime;
                }

                if (_currentPauseBy != room.pausedBy) {
                  _currentPauseBy = room.pausedBy;
                }

                if (room.status == RoomStatus.waiting) {
                  gameEnded = false;
                  _timeUpHandled = false;
                }

                // Bắt đầu timer khi có đủ 2 người và không tạm dừng
                if (room.status == RoomStatus.playing &&
                    !_isPaused &&
                    gameTimer == null &&
                    room.startTime != null &&
                    _timeSyncInitialized) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_isPaused) {
                      _startTimer();
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        const Icon(Icons.timer, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
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
                  const SizedBox(width: 10),
                  _buildPauseButton(room),
                ],
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

  Widget _buildPauseButton(OnlineGameRoom room) {
    final String roleKey = isP1 ? 'p1' : 'p2';
    final int usedCount = room.pauseCounts[roleKey] ?? 0;
    final int remaining = _maxPausePerPlayer - usedCount;
    final int safeRemaining = remaining < 0 ? 0 : remaining;

    final bool isRoomPaused = room.pauseActive;
    final bool canPause =
        !gameEnded &&
        !isRoomPaused &&
        !_pauseRequestInProgress &&
        room.status == RoomStatus.playing &&
        room.p1 != null &&
        room.p2 != null &&
        safeRemaining > 0;
    final bool canResume = isRoomPaused && !_pauseRequestInProgress;

    final String tooltip;
    if (isRoomPaused) {
      tooltip = 'Tiếp tục trận đấu';
    } else if (safeRemaining > 0) {
      tooltip = 'Tạm dừng trận đấu (còn $safeRemaining lần)';
    } else {
      tooltip = 'Bạn đã hết lượt tạm dừng';
    }

    final IconData icon = isRoomPaused
        ? Icons.play_arrow_rounded
        : Icons.pause_rounded;
    final VoidCallback? onTap;

    if (isRoomPaused) {
      onTap = canResume ? () => _onResumePressed(room) : null;
    } else {
      onTap = canPause ? () => _onPausePressed(room) : null;
    }

    final bool isEnabled =
        (isRoomPaused && canResume) || (!isRoomPaused && canPause);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEnabled ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        '${safeRemaining < 0 ? 0 : safeRemaining}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

    final grid = Padding(
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

    if (!_isPaused) {
      return grid;
    }

    return Stack(
      children: [
        grid,
        Positioned.fill(child: _buildPauseOverlay(room)),
      ],
    );
  }

  Widget _buildPauseOverlay(OnlineGameRoom room) {
    final String? pauseRole = room.pausedBy ?? _currentPauseBy;
    String pausedByName;
    if (pauseRole == 'p1') {
      pausedByName = room.p1?.name ?? 'Người chơi 1';
    } else if (pauseRole == 'p2') {
      pausedByName = room.p2?.name ?? 'Người chơi 2';
    } else {
      pausedByName = 'Người chơi';
    }

    final int pausedRemaining = room.pauseRemaining ?? remainingTime;

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Trận đấu đang tạm dừng',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bởi: $pausedByName',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              'Thời gian còn lại: ${pausedRemaining < 0 ? 0 : pausedRemaining} giây',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pauseRequestInProgress
                ? null
                : () => _onResumePressed(room),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text(
              'Tiếp tục',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
        imageAsset: card.image,
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
