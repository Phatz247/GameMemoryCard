import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';
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
    final currentUser = prefs.getString('current_user') ?? 'Chưa xác định';

    setState(() {
      username = currentUser;
      soundEnabled = prefs.getBool('sound_enabled') ?? true;
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      currentLanguage = prefs.getString('language_$username') ?? 'Tiếng Việt';

      // Load register date
      final registerDateStr = prefs.getString('register_date_$username');
      final registerDate = registerDateStr != null
          ? DateTime.parse(registerDateStr)
          : DateTime.now();

      stats = {
        'totalGames': prefs.getInt('total_games_$username') ?? 0,
        'wins': prefs.getInt('wins_$username') ?? 0,
        'highScore': prefs.getInt('high_score_$username') ?? 0,
        'favoriteMode':
        prefs.getString('favorite_mode_$username') ?? 'Cổ điển',
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
      // Initialize default achievements
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
        achievements =
            decoded.map((json) => Achievement.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveAchievements(List<Achievement> achievementsList) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    jsonEncode(achievementsList.map((a) => a.toJson()).toList());
    await prefs.setString('achievements_$username', encoded);
    setState(() {
      achievements = achievementsList;
    });
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
        decoration: const BoxDecoration(
          gradient: GameThemeData.darkGradient,
        ),
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
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
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
                currentIndex: 3,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/menu');
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(context, '/leaderboard',
                          arguments: {
                            'gameMode': GameMode.classic,
                            'level': 1,
                            'currentPlayer': username,
                          });
                      break;
                    case 2:
                      Navigator.pushReplacementNamed(context, '/shop');
                      break;
                    case 3:
                    // Already in profile
                      break;
                    case 4:
                      Navigator.pushReplacementNamed(context, '/inventory');
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
          // Preferences Section
          Text(
            'Tùy chọn',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingSwitch(
            'Âm thanh',
            Icons.volume_up,
            soundEnabled,
                (value) async {
              setState(() => soundEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('sound_enabled', value);
            },
          ),
          _buildSettingSwitch(
            'Thông báo',
            Icons.notifications,
            notificationsEnabled,
                (value) async {
              setState(() => notificationsEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
            },
          ),
          _buildSettingItem(
            'Ngôn ngữ',
            Icons.language,
            trailing: Text(
              currentLanguage,
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: _showLanguageSelection,
          ),
          const SizedBox(height: 24),

          // Account Section
          Text(
            'Tài khoản',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Đổi mật khẩu',
            Icons.lock_outline,
            onTap: _showChangePasswordDialog,
          ),
          _buildSettingItem(
            'Xóa lịch sử chơi',
            Icons.delete_outline,
            color: Colors.red,
            onTap: _resetStats,
          ),
          const SizedBox(height: 24),

          // Support Section
          Text(
            'Hỗ trợ',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            'Liên hệ hỗ trợ',
            Icons.headset_mic,
            onTap: _showSupportDialog,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GameThemeData.primaryColor.withAlpha(77),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: GameThemeData.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      String title,
      IconData icon, {
        Widget? trailing,
        VoidCallback? onTap,
        Color? color,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? Colors.white),
        title: Text(
          title,
          style: TextStyle(color: color ?? Colors.white),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      ),
    );
  }

  Widget _buildSettingSwitch(
      String title,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: GameThemeData.primaryColor,
          activeTrackColor: GameThemeData.primaryColor.withAlpha(77),
        ),
      ),
    );
  }

  void _showLanguageSelection() {
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
            _buildLanguageOption('Tiếng Việt', 'vi'),
            _buildLanguageOption('English', 'en'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chuyển sang $label')),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Đổi mật khẩu',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mật khẩu cũ',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GameThemeData.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GameThemeData.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GameThemeData.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final storedPassword = prefs.getString('password_$username');

              if (storedPassword != null &&
                  oldPasswordController.text != storedPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu cũ không đúng')),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
                );
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mật khẩu xác nhận không khớp')),
                );
                return;
              }

              await prefs.setString(
                  'password_$username', newPasswordController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đổi mật khẩu thành công')),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
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
                        const ClipboardData(text: 'support@mygame.com'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã sao chép email vào clipboard')),
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

  Future<void> _resetStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Xóa lịch sử?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa toàn bộ lịch sử chơi game? Hành động này không thể hoàn tác.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('total_games_$username');
      await prefs.remove('wins_$username');
      await prefs.remove('high_score_$username');
      await prefs.remove('favorite_mode_$username');
      await prefs.remove('play_time_$username');

      setState(() {
        stats = {
          'totalGames': 0,
          'wins': 0,
          'highScore': 0,
          'favoriteMode': 'Cổ điển',
          'registerDate': stats['registerDate'],
          'playTime': 0,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch sử chơi game')),
        );
      }
    }
  }

  Future<void> _logout() async {
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
      final prefs = await SharedPreferences.getInstance();

      // Clear session data but keep user data for future logins
      await prefs.remove('current_user');
      await prefs.remove('session_token');
      await prefs.remove('last_login');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );
      }
    }
  }
}