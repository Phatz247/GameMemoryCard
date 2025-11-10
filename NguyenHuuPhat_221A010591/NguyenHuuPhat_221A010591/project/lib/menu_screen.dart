import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'audio_service.dart';
import 'game_modes.dart';
import 'online_menu_screen.dart';
import 'profile_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  GameMode _selectedMode = GameMode.classic;
  Difficulty _selectedDifficulty = Difficulty.easy;
  GameTheme _selectedTheme = GameTheme.icons;

  String username = 'Player';

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _initializeAudio();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    _loadUsername();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    // Phát nhạc nền menu
    await _audioService.playBackgroundMusic('audio/menu_background_music.mp3');
  }

  @override
  void dispose() {
    _audioService.pauseBackgroundMusic();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ⭐ Load username từ SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString('current_user');

    if (currentUserJson != null && currentUserJson.isNotEmpty) {
      try {
        final userData = jsonDecode(currentUserJson) as Map<String, dynamic>;
        final displayName =
            userData['displayName'] ??
            userData['email']?.split('@')[0] ??
            'Player';
        if (mounted) {
          setState(() {
            username = displayName;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            username = currentUserJson;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderWithProfile(),
                    const SizedBox(height: 40),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(children: [_buildGameModeSection()]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithProfile() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo/Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Colors.amber, Colors.white],
                    ).createShader(bounds),
                    child: Text(
                      'Memory Game',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Xin chào, $username! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ).then((_) {
                  // Reload username khi quay lại từ profile
                  _loadUsername();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64ffda), Color(0xFF1de9b6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64ffda).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildGameModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF64ffda), Color(0xFF1de9b6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.games, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Chọn chế độ chơi',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...GameMode.values.map((mode) => _buildEnhancedModeCard(mode)),
      ],
    );
  }

  Widget _buildEnhancedModeCard(GameMode mode) {
    final isSelected = mode == _selectedMode;

    String title;
    String description;
    IconData icon;
    LinearGradient gradient;

    switch (mode) {
      case GameMode.classic:
        title = 'Cổ điển';
        description = 'Tìm các cặp thẻ giống nhau trong thời gian giới hạn';
        icon = Icons.grid_4x4;
        gradient = const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        );
        break;
      case GameMode.timeAttack:
        title = 'Đấu thời gian';
        description = 'Tìm càng nhiều cặp thẻ càng tốt trong 60 giây';
        icon = Icons.timer;
        gradient = const LinearGradient(
          colors: [Color(0xFF2d1b69), Color(0xFF1a1a2e)],
        );
        break;
      case GameMode.survival:
        title = 'Sinh tồn';
        description = 'Giới hạn mạng, mỗi lần sai sẽ mất mạng';
        icon = Icons.favorite;
        gradient = const LinearGradient(
          colors: [Color(0xFF0f3460), Color(0xFF16213e)],
        );
        break;
      case GameMode.online:
        title = 'Chơi trực tuyến';
        description = 'Thách đấu với người chơi khác trực tuyến!';
        icon = Icons.public;
        gradient = const LinearGradient(
          colors: [Color(0xFF16213e), Color(0xFF0f0f23)],
        );
        break;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMode = mode;
            });
            if (mode == GameMode.online) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OnlineMenuScreen(),
                ),
              );
            } else {
              Navigator.of(context).pushNamed(
                '/game',
                arguments: {
                  'config': GameConfig(
                    mode: _selectedMode,
                    difficulty: _selectedDifficulty,
                    theme: _selectedTheme,
                  ),
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF64ffda), Color(0xFF1de9b6)],
                    )
                  : LinearGradient(
                      colors: [
                        const Color(0xFF1a1a2e).withOpacity(0.3),
                        const Color(0xFF16213e).withOpacity(0.5),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF64ffda).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF64ffda).withOpacity(0.4)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: isSelected ? 20 : 10,
                  offset: Offset(0, isSelected ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: const Color(0xFF64ffda)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
