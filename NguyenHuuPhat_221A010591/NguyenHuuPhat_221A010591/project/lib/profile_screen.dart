import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'audio_service.dart';
import 'auth_screen.dart';
import 'auth_service.dart';
import 'bottom_navigation.dart';
import 'game_theme.dart';
import 'game_modes.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isUnlocked': isUnlocked,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: _getIconFromId(json['id']),
    isUnlocked: json['isUnlocked'],
  );

  static IconData _getIconFromId(String id) {
    switch (id) {
      case 'first_win':
        return Icons.emoji_events;
      case 'play_10':
        return Icons.casino;
      case 'high_scorer':
        return Icons.stars;
      case 'speed_demon':
        return Icons.speed;
      case 'perfectionist':
        return Icons.workspace_premium;
      case 'dedicated':
        return Icons.favorite;
      default:
        return Icons.military_tech;
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String username = '';
  bool soundEnabled = true;
  bool notificationsEnabled = true;
  String currentLanguage = 'Tiếng Việt';
  bool isGuest = false; // Thêm biến để kiểm tra khách

  final AuthService _authService = AuthService(); // Thêm auth service

  Map<String, dynamic> stats = {
    'totalGames': 0,
    'wins': 0,
    'highScore': 0,
    'favoriteMode': 'Cổ điển',
    'registerDate': DateTime.now(),
    'playTime': 0, // in minutes
  };

  List<Achievement> achievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _initializeAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // ⭐ Kiểm tra trạng thái đăng nhập thực sự
    final savedUser = await _authService.getSavedUser();
    String displayName = 'Khách';
    bool guestMode = true;

    if (savedUser != null) {
      displayName = savedUser['displayName'] ?? 'Player';
      guestMode = savedUser['isGuest'] == true;

      // Kiểm tra Firebase Auth để đảm bảo người dùng vẫn đăng nhập
      if (!guestMode && _authService.currentUser == null) {
        // User đã đăng xuất khỏi Firebase nhưng vẫn còn data local
        guestMode = true;
        displayName = 'Khách';
      }
    }

    setState(() {
      username = displayName;
      isGuest = guestMode;
      soundEnabled = prefs.getBool('sound_enabled') ?? true;
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      currentLanguage = prefs.getString('language_$username') ?? 'Tiếng Việt';

      final registerDateStr = prefs.getString('register_date_$username');
      final registerDate = registerDateStr != null
          ? DateTime.parse(registerDateStr)
          : DateTime.now();

      stats = {
        'totalGames': prefs.getInt('total_games_$username') ?? 0,
        'wins': prefs.getInt('wins_$username') ?? 0,
        'highScore': prefs.getInt('high_score_$username') ?? 0,
        'favoriteMode': prefs.getString('favorite_mode_$username') ?? 'Cổ điển',
        'registerDate': registerDate,
        'playTime': prefs.getInt('play_time_$username') ?? 0,
      };
    });

    await _loadAchievements();
  }

  Future<void> _initializeAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString('achievements_$username');

    if (achievementsJson == null) {
      final defaultAchievements = [
        Achievement(
          id: 'first_win',
          title: 'Chiến thắng đầu tiên',
          description: 'Giành chiến thắng trong trận đầu tiên',
          icon: Icons.emoji_events,
          isUnlocked: false,
        ),
        Achievement(
          id: 'play_10',
          title: 'Người chơi tận tâm',
          description: 'Chơi 10 trận game',
          icon: Icons.casino,
          isUnlocked: false,
        ),
        Achievement(
          id: 'high_scorer',
          title: 'Tay chơi xuất sắc',
          description: 'Đạt 1000 điểm trong một trận',
          icon: Icons.stars,
          isUnlocked: false,
        ),
        Achievement(
          id: 'speed_demon',
          title: 'Tốc độ ánh sáng',
          description: 'Hoàn thành trận trong 3 phút',
          icon: Icons.speed,
          isUnlocked: false,
        ),
        Achievement(
          id: 'perfectionist',
          title: 'Người hoàn hảo',
          description: 'Giành chiến thắng không mắc lỗi',
          icon: Icons.workspace_premium,
          isUnlocked: false,
        ),
        Achievement(
          id: 'dedicated',
          title: 'Người chơi trung thành',
          description: 'Chơi game 7 ngày liên tiếp',
          icon: Icons.favorite,
          isUnlocked: false,
        ),
      ];

      await _saveAchievements(defaultAchievements);
    }
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString('achievements_$username');

    if (achievementsJson != null) {
      final List<dynamic> decoded = jsonDecode(achievementsJson);
      setState(() {
        achievements = decoded
            .map((json) => Achievement.fromJson(json))
            .toList();
      });
    }
  }

  Future<void> _saveAchievements(List<Achievement> achievementsList) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      achievementsList.map((a) => a.toJson()).toList(),
    );
    await prefs.setString('achievements_$username', encoded);
    setState(() {
      achievements = achievementsList;
    });
  }

  /// Unlock achievements based on game stats
  Future<void> unlockAchievements({
    required bool isWin,
    required int finalScore,
    required int totalGames,
    required int totalWins,
    required int gameTime, // in seconds
    required bool isPerfectMatch, // no wrong flips
  }) async {
    if (!isWin) return; // Only unlock on win

    final updatedAchievements = List<Achievement>.from(achievements);

    // 1. First win achievement
    if (totalWins == 1 &&
        !updatedAchievements
            .firstWhere(
              (a) => a.id == 'first_win',
              orElse: () => Achievement(
                id: '',
                title: '',
                description: '',
                icon: Icons.emoji_events,
                isUnlocked: false,
              ),
            )
            .isUnlocked) {
      final index = updatedAchievements.indexWhere((a) => a.id == 'first_win');
      if (index != -1) {
        updatedAchievements[index] = Achievement(
          id: 'first_win',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 2. Play 10 games achievement
    if (totalGames >= 10 &&
        !updatedAchievements
            .firstWhere(
              (a) => a.id == 'play_10',
              orElse: () => Achievement(
                id: '',
                title: '',
                description: '',
                icon: Icons.casino,
                isUnlocked: false,
              ),
            )
            .isUnlocked) {
      final index = updatedAchievements.indexWhere((a) => a.id == 'play_10');
      if (index != -1) {
        updatedAchievements[index] = Achievement(
          id: 'play_10',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 3. High scorer achievement (1000+ points)
    if (finalScore >= 1000 &&
        !updatedAchievements
            .firstWhere(
              (a) => a.id == 'high_scorer',
              orElse: () => Achievement(
                id: '',
                title: '',
                description: '',
                icon: Icons.stars,
                isUnlocked: false,
              ),
            )
            .isUnlocked) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'high_scorer',
      );
      if (index != -1) {
        updatedAchievements[index] = Achievement(
          id: 'high_scorer',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 4. Speed demon achievement (complete in under 3 minutes = 180 seconds)
    if (gameTime <= 180 &&
        !updatedAchievements
            .firstWhere(
              (a) => a.id == 'speed_demon',
              orElse: () => Achievement(
                id: '',
                title: '',
                description: '',
                icon: Icons.speed,
                isUnlocked: false,
              ),
            )
            .isUnlocked) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'speed_demon',
      );
      if (index != -1) {
        updatedAchievements[index] = Achievement(
          id: 'speed_demon',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 5. Perfectionist achievement (win without wrong flips)
    if (isPerfectMatch &&
        !updatedAchievements
            .firstWhere(
              (a) => a.id == 'perfectionist',
              orElse: () => Achievement(
                id: '',
                title: '',
                description: '',
                icon: Icons.workspace_premium,
                isUnlocked: false,
              ),
            )
            .isUnlocked) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'perfectionist',
      );
      if (index != -1) {
        updatedAchievements[index] = Achievement(
          id: 'perfectionist',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 6. Dedicated player - check if played 7 consecutive days (simplified: just track days played)
    final prefs = await SharedPreferences.getInstance();
    final lastPlayDate = prefs.getString('last_play_date_$username');
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format

    if (lastPlayDate != today) {
      // Different day, increment days played
      int daysPlayed = prefs.getInt('consecutive_days_$username') ?? 0;

      if (lastPlayDate != null) {
        final last = DateTime.parse(lastPlayDate);
        final now = DateTime.now();
        final dayDifference = now.difference(last).inDays;

        if (dayDifference == 1) {
          // Consecutive day
          daysPlayed++;
        } else if (dayDifference > 1) {
          // Streak broken, restart
          daysPlayed = 1;
        }
      } else {
        daysPlayed = 1;
      }

      await prefs.setString('last_play_date_$username', today);
      await prefs.setInt('consecutive_days_$username', daysPlayed);

      // Unlock if 7 consecutive days
      if (daysPlayed >= 7 &&
          !updatedAchievements
              .firstWhere(
                (a) => a.id == 'dedicated',
                orElse: () => Achievement(
                  id: '',
                  title: '',
                  description: '',
                  icon: Icons.favorite,
                  isUnlocked: false,
                ),
              )
              .isUnlocked) {
        final index = updatedAchievements.indexWhere(
          (a) => a.id == 'dedicated',
        );
        if (index != -1) {
          updatedAchievements[index] = Achievement(
            id: 'dedicated',
            title: updatedAchievements[index].title,
            description: updatedAchievements[index].description,
            icon: updatedAchievements[index].icon,
            isUnlocked: true,
          );
        }
      }
    }

    await _saveAchievements(updatedAchievements);
  }

  /// Static method to unlock achievements from GameScreen
  static Future<void> unlockAchievementsStatic({
    required String playerName,
    required bool isWin,
    required int finalScore,
    required int totalGames,
    required int totalWins,
    required int gameTime,
    required bool isPerfectMatch,
  }) async {
    if (!isWin) return;

    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString('achievements_$playerName');

    List<Achievement> achievements = [];
    if (achievementsJson != null) {
      final List<dynamic> decoded = jsonDecode(achievementsJson);
      achievements = decoded.map((json) => Achievement.fromJson(json)).toList();
    } else {
      achievements = [
        Achievement(
          id: 'first_win',
          title: 'Chiến thắng đầu tiên',
          description: 'Giành chiến thắng trong trận đầu tiên',
          icon: Icons.emoji_events,
          isUnlocked: false,
        ),
        Achievement(
          id: 'play_10',
          title: 'Người chơi tận tâm',
          description: 'Chơi 10 trận game',
          icon: Icons.casino,
          isUnlocked: false,
        ),
        Achievement(
          id: 'high_scorer',
          title: 'Tay chơi xuất sắc',
          description: 'Đạt 1000 điểm trong một trận',
          icon: Icons.stars,
          isUnlocked: false,
        ),
        Achievement(
          id: 'speed_demon',
          title: 'Tốc độ ánh sáng',
          description: 'Hoàn thành trận trong 3 phút',
          icon: Icons.speed,
          isUnlocked: false,
        ),
        Achievement(
          id: 'perfectionist',
          title: 'Người hoàn hảo',
          description: 'Giành chiến thắng không mắc lỗi',
          icon: Icons.workspace_premium,
          isUnlocked: false,
        ),
        Achievement(
          id: 'dedicated',
          title: 'Người chơi trung thành',
          description: 'Chơi game 7 ngày liên tiếp',
          icon: Icons.favorite,
          isUnlocked: false,
        ),
      ];
    }

    final updatedAchievements = List<Achievement>.from(achievements);

    // 1. First win
    if (totalWins == 1) {
      final index = updatedAchievements.indexWhere((a) => a.id == 'first_win');
      if (index != -1 && !updatedAchievements[index].isUnlocked) {
        updatedAchievements[index] = Achievement(
          id: 'first_win',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 2. Play 10 games
    if (totalGames >= 10) {
      final index = updatedAchievements.indexWhere((a) => a.id == 'play_10');
      if (index != -1 && !updatedAchievements[index].isUnlocked) {
        updatedAchievements[index] = Achievement(
          id: 'play_10',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 3. High scorer (1000+ points)
    if (finalScore >= 1000) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'high_scorer',
      );
      if (index != -1 && !updatedAchievements[index].isUnlocked) {
        updatedAchievements[index] = Achievement(
          id: 'high_scorer',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 4. Speed demon (complete in under 3 minutes)
    if (gameTime <= 180) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'speed_demon',
      );
      if (index != -1 && !updatedAchievements[index].isUnlocked) {
        updatedAchievements[index] = Achievement(
          id: 'speed_demon',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 5. Perfectionist (no wrong flips)
    if (isPerfectMatch) {
      final index = updatedAchievements.indexWhere(
        (a) => a.id == 'perfectionist',
      );
      if (index != -1 && !updatedAchievements[index].isUnlocked) {
        updatedAchievements[index] = Achievement(
          id: 'perfectionist',
          title: updatedAchievements[index].title,
          description: updatedAchievements[index].description,
          icon: updatedAchievements[index].icon,
          isUnlocked: true,
        );
      }
    }

    // 6. Dedicated player (7 consecutive days)
    final lastPlayDate = prefs.getString('last_play_date_$playerName');
    final today = DateTime.now().toString().split(' ')[0];

    if (lastPlayDate != today) {
      int daysPlayed = prefs.getInt('consecutive_days_$playerName') ?? 0;

      if (lastPlayDate != null) {
        final last = DateTime.parse(lastPlayDate);
        final now = DateTime.now();
        final dayDifference = now.difference(last).inDays;

        if (dayDifference == 1) {
          daysPlayed++;
        } else if (dayDifference > 1) {
          daysPlayed = 1;
        }
      } else {
        daysPlayed = 1;
      }

      await prefs.setString('last_play_date_$playerName', today);
      await prefs.setInt('consecutive_days_$playerName', daysPlayed);

      if (daysPlayed >= 7) {
        final index = updatedAchievements.indexWhere(
          (a) => a.id == 'dedicated',
        );
        if (index != -1 && !updatedAchievements[index].isUnlocked) {
          updatedAchievements[index] = Achievement(
            id: 'dedicated',
            title: updatedAchievements[index].title,
            description: updatedAchievements[index].description,
            icon: updatedAchievements[index].icon,
            isUnlocked: true,
          );
        }
      }
    }

    final encoded = jsonEncode(
      updatedAchievements.map((a) => a.toJson()).toList(),
    );
    await prefs.setString('achievements_$playerName', encoded);
  }

  String _formatPlayTime(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}p';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with support and settings buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: _showSupportDialog,
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: GameThemeData.primaryColor,
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          username,
                          style: GameThemeData.titleTextStyle.copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _tabController.animateTo(2);
                      },
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: GameThemeData.primaryColor.withAlpha(77),
                  ),
                  labelColor: GameThemeData.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Thành tích'),
                    Tab(text: 'Cài đặt'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildAchievementsTab(),
                    _buildSettingsTab(),
                  ],
                ),
              ),

              // Bottom Navigation
              GameBottomNavigation(
                currentIndex: 2,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/menu');
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(
                        context,
                        '/leaderboard',
                        arguments: {
                          'gameMode': GameMode.classic,
                          'level': 1,
                          'currentPlayer': username,
                        },
                      );
                      break;
                    case 2:
                      // Already in profile
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _buildStatCard(
                'Số trận đã chơi',
                '${stats['totalGames']}',
                Icons.casino,
              ),
              _buildStatCard(
                'Chiến thắng',
                '${stats['wins']}',
                Icons.emoji_events,
              ),
              _buildStatCard(
                'Điểm cao nhất',
                '${stats['highScore']}',
                Icons.stars,
              ),
              _buildStatCard(
                'Chế độ yêu thích',
                stats['favoriteMode'].toString(),
                Icons.favorite,
              ),
              _buildStatCard(
                'Ngày đăng ký',
                _formatDate(stats['registerDate']),
                Icons.calendar_today,
              ),
              _buildStatCard(
                'Thời gian chơi',
                _formatPlayTime(stats['playTime']),
                Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (achievements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? GameThemeData.primaryColor.withAlpha(77)
              : Colors.grey.withAlpha(51),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? GameThemeData.primaryColor.withAlpha(51)
                    : Colors.grey.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                size: 32,
                color: achievement.isUnlocked
                    ? GameThemeData.primaryColor
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              achievement.isUnlocked ? Icons.check_circle : Icons.lock,
              color: achievement.isUnlocked
                  ? GameThemeData.primaryColor
                  : Colors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt tài khoản',
            style: GoogleFonts.poppins(
              color: GameThemeData.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Đổi tên hiển thị
          _buildSettingsButton(
            'Đổi tên hiển thị',
            Icons.person_outline,
            onTap: _showChangeNameDialog,
            isDisabled: isGuest,
          ),

          // Đổi mật khẩu - chỉ cho tài khoản đã đăng ký
          _buildSettingsButton(
            'Đổi mật khẩu',
            Icons.lock_outline,
            onTap: _showChangePasswordDialog,
            isDisabled: isGuest,
          ),

          const SizedBox(height: 24),
          Text(
            'Cài đặt chung',
            style: GoogleFonts.poppins(
              color: GameThemeData.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Âm thanh
          _buildSwitchSetting(
            'Âm thanh',
            Icons.volume_up_outlined,
            soundEnabled,
            (value) async {
              setState(() {
                soundEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('sound_enabled', value);
              final audioService = AudioService();
              await audioService.setMusicEnabled(value);
              await audioService.setSfxEnabled(value);
            },
          ),

          const SizedBox(height: 16),

          _buildSwitchSetting(
            'Thông báo',
            Icons.notifications_outlined,
            notificationsEnabled,
            (value) async {
              setState(() {
                notificationsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
            },
          ),

          // Ngôn ngữ
          _buildSettingsButton(
            'Ngôn ngữ',
            Icons.language,
            trailing: Text(
              currentLanguage,
              style: TextStyle(color: Colors.grey),
            ),
            onTap: _showLanguageDialog,
          ),

          const SizedBox(height: 32),
          // Đăng xuất
          _buildSettingsButton(
            isGuest ? 'Đăng nhập' : 'Đăng xuất',
            isGuest ? Icons.login : Icons.logout,
            onTap:
                _logout, // Fixed: changed to _logout instead of _handleAuthAction
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // Hàm hiển thị dialog đổi mật khẩu
  void _showChangePasswordDialog() {
    if (isGuest || _authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đổi mật khẩu')),
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: GameThemeData.darkBackgroundColor,
              title: Text(
                'Đổi mật khẩu',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mật khẩu hiện tại
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: GameThemeData.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mật khẩu mới
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: GameThemeData.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Xác nhận mật khẩu mới
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: GameThemeData.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validate input
                          if (currentPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'Vui lòng điền đầy đủ thông tin';
                            });
                            return;
                          }

                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            setState(() {
                              errorMessage = 'Xác nhận mật khẩu không khớp';
                            });
                            return;
                          }

                          if (newPasswordController.text.length < 6) {
                            setState(() {
                              errorMessage =
                                  'Mật khẩu mới phải có ít nhất 6 ký tự';
                            });
                            return;
                          }

                          // Set loading state
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          // Call the change password method
                          final result = await _authService.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          if (!result['success']) {
                            setState(() {
                              isLoading = false;
                              errorMessage = result['message'];
                            });
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đổi mật khẩu thành công'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameThemeData.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: GameThemeData.primaryColor
                        .withOpacity(0.6),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Đổi mật khẩu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hiển thị dialog đổi tên hiển thị
  void _showChangeNameDialog() {
    // Implementation will go here
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: username);
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: GameThemeData.darkBackgroundColor,
              title: Text(
                'Đổi tên hiển thị',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tên hiển thị mới',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: GameThemeData.primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameController.text.trim();

                          if (newName.isEmpty) {
                            setState(() {
                              errorMessage = 'Tên hiển thị không được để trống';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          final result = await _authService.updateDisplayName(
                            newName,
                          );

                          if (result) {
                            if (mounted) {
                              setState(() => username = newName);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đổi tên hiển thị thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Refresh user data
                              _loadUserData();
                            }
                          } else {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'Không thể cập nhật tên hiển thị';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameThemeData.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: GameThemeData.primaryColor
                        .withOpacity(0.6),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hiển thị dialog chọn ngôn ngữ
  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn ngôn ngữ',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('Tiếng Việt'),
            _buildLanguageOption('English'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label) {
    final isSelected = currentLanguage == label;
    return ListTile(
      leading: Icon(
        Icons.language,
        color: isSelected ? GameThemeData.primaryColor : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? GameThemeData.primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: GameThemeData.primaryColor)
          : null,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_$username', label);
        setState(() {
          currentLanguage = label;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã chuyển sang $label')));
      },
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Liên hệ hỗ trợ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cần hỗ trợ? Hãy liên hệ với chúng tôi:',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'support@mygame.com',
                    style: GoogleFonts.poppins(
                      color: GameThemeData.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'support@mygame.com'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép email vào clipboard'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              // In a real app, this would open the email client
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở ứng dụng email...')),
              );
              Navigator.pop(context);
            },
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Nếu là khách, chuyển đến màn hình đăng nhập ngay lập tức
    if (isGuest) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
      return;
    }

    // Nếu là người dùng đã đăng nhập, hiển thị xác nhận đăng xuất
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Đăng xuất?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất?',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Sử dụng AuthService để đăng xuất (xóa cả Firebase Auth và local data)
      await _authService.signOut();

      if (mounted) {
        // Chuyển đến màn hình đăng nhập
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: GameThemeData.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
    String title,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
    bool isDisabled = false,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      onTap: isDisabled ? null : onTap,
      leading: Icon(icon, color: isDisabled ? Colors.grey : iconColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(color: isDisabled ? Colors.grey : textColor),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDisabled ? Colors.grey : Colors.white54,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      activeColor: GameThemeData.primaryColor,
      secondary: Icon(icon, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// Public wrapper function to unlock achievements from GameScreen
Future<void> unlockGameAchievements({
  required String playerName,
  required bool isWin,
  required int finalScore,
  required int totalGames,
  required int totalWins,
  required int gameTime,
  required bool isPerfectMatch,
}) async {
  await _ProfileScreenState.unlockAchievementsStatic(
    playerName: playerName,
    isWin: isWin,
    finalScore: finalScore,
    totalGames: totalGames,
    totalWins: totalWins,
    gameTime: gameTime,
    isPerfectMatch: isPerfectMatch,
  );
}
