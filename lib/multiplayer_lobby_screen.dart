// lib/multiplayer_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_theme.dart';
import 'multiplayer_service.dart';
import 'multiplayer_game_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final _nameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  int _selectedLevel = 1;
  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên của bạn');
      return;
    }

    setState(() => _isCreatingRoom = true);

    try {
      await MultiplayerService.initUser(_nameController.text.trim());
      final room = await MultiplayerService.createRoom(_selectedLevel);

      if (!mounted) return;

      // Navigate to waiting room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomScreen(
            room: room,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
      }
    }
  }

  Future<void> _joinRoom() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên của bạn');
      return;
    }

    if (_roomCodeController.text.trim().isEmpty) {
      _showError('Vui lòng nhập mã phòng');
      return;
    }

    setState(() => _isJoiningRoom = true);

    try {
      await MultiplayerService.initUser(_nameController.text.trim());
      final room = await MultiplayerService.joinRoom(_roomCodeController.text.trim());

      if (room == null) {
        throw Exception('Không thể tham gia phòng. Phòng không tồn tại hoặc đã đầy.');
      }

      if (!mounted) return;

      // Navigate to waiting room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomScreen(
            room: room,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isJoiningRoom = false);
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

  void _showAvailableRooms() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên của bạn trước');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableRoomsScreen(
          playerName: _nameController.text.trim(),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Chơi Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Player name input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tên của bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Nhập tên...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Create Room Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GameThemeData.primaryColor.withOpacity(0.3),
                        GameThemeData.primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GameThemeData.primaryColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎮 Tạo Phòng Mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Level selector
                      const Text(
                        'Level:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final isSelected = _selectedLevel == level;
                          return ChoiceChip(
                            label: Text('Level $level'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedLevel = level);
                            },
                            selectedColor: GameThemeData.accentColor,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _isCreatingRoom ? null : _createRoom,
                        icon: _isCreatingRoom
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isCreatingRoom ? 'Đang tạo...' : 'Tạo Phòng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameThemeData.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Join Room Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔗 Tham Gia Phòng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _roomCodeController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã phòng...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.vpn_key, color: Colors.white70),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isJoiningRoom ? null : _joinRoom,
                              icon: _isJoiningRoom
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_isJoiningRoom ? 'Đang vào...' : 'Tham Gia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GameThemeData.accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showAvailableRooms,
                              icon: const Icon(Icons.list),
                              label: const Text('Danh sách'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tạo phòng và chia sẻ mã với bạn bè, hoặc tham gia phòng có sẵn!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Available Rooms Screen
class AvailableRoomsScreen extends StatelessWidget {
  final String playerName;

  const AvailableRoomsScreen({Key? key, required this.playerName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Phòng Có Sẵn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Rooms list
              Expanded(
                child: StreamBuilder<List<GameRoom>>(
                  stream: MultiplayerService.getAvailableRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(GameThemeData.primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final rooms = snapshot.data ?? [];

                    if (rooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có phòng nào',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _RoomCard(
                          room: room,
                          playerName: playerName,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final GameRoom room;
  final String playerName;

  const _RoomCard({required this.room, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameThemeData.primaryColor.withOpacity(0.2),
            GameThemeData.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameThemeData.primaryColor.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          room.hostName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Level ${room.level}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            try {
              await MultiplayerService.initUser(playerName);
              final joinedRoom = await MultiplayerService.joinRoom(room.roomId);

              if (joinedRoom == null) {
                throw Exception('Không thể tham gia phòng');
              }

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WaitingRoomScreen(
                    room: joinedRoom,
                    isHost: false,
                  ),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GameThemeData.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Vào'),
        ),
      ),
    );
  }
}

// Waiting Room Screen
class WaitingRoomScreen extends StatefulWidget {
  final GameRoom room;
  final bool isHost;

  const WaitingRoomScreen({
    Key? key,
    required this.room,
    required this.isHost,
  }) : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  @override
  void dispose() {
    if (!widget.isHost) {
      MultiplayerService.leaveRoom(widget.room.roomId, MultiplayerService.currentUserId);
    }
    super.dispose();
  }

  Future<void> _startGame() async {
    try {
      await MultiplayerService.startGame(widget.room.roomId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerGameScreen(
            room: widget.room,
            isHost: widget.isHost,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: StreamBuilder<GameRoom>(
            stream: MultiplayerService.watchRoom(widget.room.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final room = snapshot.data ?? widget.room;

              // Auto navigate when game starts
              if (room.status == 'playing') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiplayerGameScreen(
                        room: room,
                        isHost: widget.isHost,
                      ),
                    ),
                  );
                });
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            MultiplayerService.leaveRoom(room.roomId, MultiplayerService.currentUserId);
                            Navigator.pop(context);
                          },
                        ),
                        const Text(
                          'Phòng Chờ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Room code
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Mã Phòng',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.roomId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: room.roomId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã sao chép mã phòng!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Players
                    Expanded(
                      child: Column(
                        children: [
                          _PlayerCard(
                            name: room.hostName,
                            isHost: true,
                            isReady: true,
                          ),
                          const SizedBox(height: 16),
                          room.guestId != null
                              ? _PlayerCard(
                                  name: room.guestName!,
                                  isHost: false,
                                  isReady: true,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          GameThemeData.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Đang chờ người chơi...',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Start button (host only)
                    if (widget.isHost && room.guestId != null)
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameThemeData.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Bắt Đầu Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final bool isHost;
  final bool isReady;

  const _PlayerCard({
    required this.name,
    required this.isHost,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameThemeData.primaryColor.withOpacity(0.3),
            GameThemeData.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameThemeData.primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: GameThemeData.accentColor,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GameThemeData.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isReady ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: isReady ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReady ? 'Sẵn sàng' : 'Chờ...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
