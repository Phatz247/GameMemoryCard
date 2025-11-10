import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'online_game_service.dart';
import 'online_game_screen.dart';

class OnlineMenuScreen extends StatefulWidget {
  const OnlineMenuScreen({Key? key}) : super(key: key);

  @override
  State<OnlineMenuScreen> createState() => _OnlineMenuScreenState();
}

class _OnlineMenuScreenState extends State<OnlineMenuScreen> with SingleTickerProviderStateMixin {
  final OnlineGameService _gameService = OnlineGameService();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();

  bool _isSearching = false;
  String _playerName = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();

    // Animation cho nút Tìm Trận Nhanh
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadPlayerName() async {
    setState(() {
      _playerName = 'NguoiChoi${DateTime.now().millisecondsSinceEpoch % 10000}';
      _playerNameController.text = _playerName;
    });
  }

  Future<void> _quickMatch() async {
    final playerName = _playerNameController.text.trim();
    if (playerName.isEmpty) {
      _showError('Vui lòng nhập tên người chơi');
      return;
    }

    setState(() => _isSearching = true);

    try {
      print('Đang tìm phòng ngẫu nhiên cho: $playerName');
      final room = await _gameService.findRandomRoom(playerName);

      if (room != null && mounted) {
        print('Đã tìm/tạo phòng: ${room.roomId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(
              room: room,
              playerName: playerName,
            ),
          ),
        );
      } else {
        _showError('Không thể tìm hoặc tạo phòng chơi');
      }
    } catch (e) {
      print('Lỗi khi tìm trận nhanh: $e');
      _showError('Lỗi: $e\n\nKiểm tra kết nối internet và cấu hình Firebase');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _createRoom() async {
    final playerName = _playerNameController.text.trim();
    if (playerName.isEmpty) {
      _showError('Vui lòng nhập tên người chơi');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final room = await _gameService.createRoom(
        playerName: playerName,
        numberOfPairs: 8,
        timeLimit: 90,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(
              room: room,
              playerName: playerName,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Lỗi tạo phòng: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _joinRoom() async {
    final playerName = _playerNameController.text.trim();
    final roomId = _roomIdController.text.trim().toUpperCase();

    if (playerName.isEmpty) {
      _showError('Vui lòng nhập tên người chơi');
      return;
    }

    if (roomId.isEmpty) {
      _showError('Vui lòng nhập mã phòng');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final success = await _gameService.joinRoom(roomId, playerName);

      if (success && mounted) {
        final roomDoc = await _gameService.watchRoom(roomId).first;
        if (roomDoc != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OnlineGameScreen(
                room: roomDoc,
                playerName: playerName,
              ),
            ),
          );
        }
      } else {
        _showError('Không thể tham gia phòng. Phòng không tồn tại hoặc đã đầy.');
      }
    } catch (e) {
      _showError('Lỗi tham gia phòng: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Chế Độ Trực Tuyến',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0e27),
              Color(0xFF1a1f3a),
              Color(0xFF0f172a),
              Color(0xFF0a0e27),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Geometric patterns background
            _buildBackgroundPattern(),

            // Main content
            SafeArea(
              child: _isSearching
                  ? _buildLoadingScreen()
                  : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildPlayerCard(),
                            const SizedBox(height: 30),
                            _buildQuickMatchButton(),
                            const SizedBox(height: 25),
                            _buildDivider(),
                            const SizedBox(height: 25),
                            _buildCreateRoomSection(),
                            const SizedBox(height: 20),
                            _buildJoinRoomSection(),
                            const SizedBox(height: 30),
                            _buildWaitingRoomsSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return CustomPaint(
      painter: GeometricPatternPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Đang tìm đối thủ...',
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vui lòng chờ trong giây lát',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1e293b).withValues(alpha: 0.8),
            Color(0xFF334155).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.blue],
              ),
            ),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Người chơi hiện tại',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  controller: _playerNameController,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Nhập tên của bạn',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMatchButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _quickMatch,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber,
                Colors.orange.shade700,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'TÌM TRẬN\nNHANH',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white38,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'HOẶC',
            style: GoogleFonts.orbitron(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white38,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateRoomSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF065f46).withValues(alpha: 0.3),
            Color(0xFF047857).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _createRoom,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Tạo phòng mới',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1e3a8a).withValues(alpha: 0.3),
            Color(0xFF3b82f6).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tham gia phòng',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.blue.shade200,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1e293b).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _roomIdController,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'VD: ABC123',
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        letterSpacing: 2,
                      ),
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.blue.shade300, size: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: _joinRoom,
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.login, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoomsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1e293b).withValues(alpha: 0.6),
            Color(0xFF334155).withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Phòng chờ',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          StreamBuilder<List<OnlineGameRoom>>(
            stream: _gameService.getAvailableRooms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Lỗi tải danh sách phòng',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                );
              }

              final rooms = snapshot.data ?? [];

              if (rooms.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, color: Colors.white38, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Không có phòng nào đang chờ',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: rooms.map((room) => _buildRoomCard(room)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(OnlineGameRoom room) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF334155).withValues(alpha: 0.8),
            Color(0xFF1e293b).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: Colors.blue.shade200, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.hostName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mã: ${room.roomId}',
                  style: GoogleFonts.orbitron(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final playerName = _playerNameController.text.trim();
              if (playerName.isEmpty) {
                _showError('Vui lòng nhập tên người chơi');
                return;
              }

              setState(() => _isSearching = true);

              try {
                final success = await _gameService.joinRoom(room.roomId, playerName);

                if (success && mounted) {
                  final updatedRoom = await _gameService.watchRoom(room.roomId).first;
                  if (updatedRoom != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnlineGameScreen(
                          room: updatedRoom,
                          playerName: playerName,
                        ),
                      ),
                    );
                  }
                } else {
                  _showError('Không thể tham gia phòng này');
                }
              } catch (e) {
                _showError('Lỗi: $e');
              } finally {
                if (mounted) {
                  setState(() => _isSearching = false);
                }
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vào',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _playerNameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw diagonal lines
    paint.color = Colors.cyan.withValues(alpha: 0.05);
    for (double i = -size.height; i < size.width; i += 100) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
