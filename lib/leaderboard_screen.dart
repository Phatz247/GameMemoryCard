import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modes.dart';
import 'game_levels.dart';
import 'player_score.dart';
import 'leaderboard_service.dart';
import 'bottom_navigation.dart';

class LeaderboardScreen extends StatefulWidget {
  final GameMode gameMode;
  final int level;
  final String currentPlayer;

  const LeaderboardScreen({
    Key? key,
    required this.gameMode,
    required this.level,
    required this.currentPlayer,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<PlayerScore> _scores = [];
  List<PlayerScore> _filteredScores = [];
  PlayerScore? _personalBest;
  LeaderboardStats? _stats;
  bool _loading = true;
  bool _showSearch = false;

  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.allTime;
  GameMode _selectedMode;
  int _selectedLevel;

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  _LeaderboardScreenState()
      : _selectedMode = GameMode.classic,
        _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.gameMode;
    _selectedLevel = widget.level;
    _tabController = TabController(length: 2, vsync: this);
    _loadScores();

    _searchController.addListener(() {
      _filterScores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    setState(() => _loading = true);

    final scores = await LeaderboardService.getScores(
      _selectedMode,
      _selectedLevel,
      period: _selectedPeriod,
    );

    final personalBest = await LeaderboardService.getPersonalBest(
      widget.currentPlayer,
      _selectedMode,
      _selectedLevel,
    );

    final stats = await LeaderboardService.getStats(
      _selectedMode,
      _selectedLevel,
    );

    if (mounted) {
      setState(() {
        _scores = scores;
        _filteredScores = scores;
        _personalBest = personalBest;
        _stats = stats;
        _loading = false;
      });
    }
  }

  void _filterScores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredScores = _scores;
      } else {
        _filteredScores = _scores
            .where((score) => score.playerName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
            GameBottomNavigation(
              currentIndex: 1,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, '/menu');
                    break;
                  case 1:
                    // Already in leaderboard
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/profile');
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B6BAA),
            const Color(0xFF2C3E78),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Bảng Xếp Hạng',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _showSearch = !_showSearch);
                },
                icon: Icon(
                  _showSearch ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (_showSearch) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người chơi...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Mode and Level selector
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: _getModeName(_selectedMode),
                  icon: Icons.games,
                  onTap: _showModeSelector,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Cấp $_selectedLevel',
                  icon: Icons.layers,
                  onTap: _showLevelSelector,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Tất cả', LeaderboardPeriod.allTime),
                _buildPeriodChip('Hôm nay', LeaderboardPeriod.today),
                _buildPeriodChip('Tuần này', LeaderboardPeriod.thisWeek),
                _buildPeriodChip('Tháng này', LeaderboardPeriod.thisMonth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6B6BAA).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6B6BAA),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, LeaderboardPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedPeriod = period);
          _loadScores();
        },
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        selectedColor: const Color(0xFF6B6BAA),
        labelStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: const Color(0xFF6B6BAA),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Xếp hạng'),
          Tab(text: 'Thống kê'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_filteredScores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có điểm nào',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Top 3 Podium
        if (_filteredScores.length >= 3) _buildPodium(),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: math.max(0, _filteredScores.length - 3),
            itemBuilder: (context, index) {
              final actualIndex = index + 3;
              final score = _filteredScores[actualIndex];
              final isCurrentPlayer = score.playerName == widget.currentPlayer;
              return _buildRankTile(actualIndex + 1, score, isCurrentPlayer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    final first = _filteredScores[0];
    final second = _filteredScores.length > 1 ? _filteredScores[1] : null;
    final third = _filteredScores.length > 2 ? _filteredScores[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null) _buildPodiumItem(2, second, 120),
          const SizedBox(width: 8),
          _buildPodiumItem(1, first, 150),
          const SizedBox(width: 8),
          if (third != null) _buildPodiumItem(3, third, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(int rank, PlayerScore score, double height) {
    Color color;
    IconData medal;

    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700);
        medal = Icons.workspace_premium;
        break;
      case 2:
        color = const Color(0xFFC0C0C0);
        medal = Icons.military_tech;
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        medal = Icons.stars;
        break;
      default:
        color = Colors.grey;
        medal = Icons.emoji_events;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(medal, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          // Player name
          Text(
            score.playerName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Score
          Text(
            '${score.score}',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Podium base
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTile(int rank, PlayerScore score, bool isCurrentPlayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? const Color(0xFF6B6BAA).withValues(alpha: 0.5)
            : const Color(0xFF2C3E78).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayer
              ? const Color(0xFF6B6BAA)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF6B6BAA),
            child: Text(
              score.playerName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        score.playerName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (score.rankChange != null) ...[
                      const SizedBox(width: 8),
                      _buildRankChangeIndicator(score),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      score.formatTime(),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.touch_app, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${score.moves} nước',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                score.formatDate(),
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankChangeIndicator(PlayerScore score) {
    if (score.rankChange == null) return const SizedBox.shrink();

    final change = score.rankChange!;
    final isUp = change > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUp ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: isUp ? Colors.green : Colors.red,
          ),
          Text(
            '${change.abs()}',
            style: GoogleFonts.poppins(
              color: isUp ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_loading || _stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê chung',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Tổng người chơi',
                '${_stats!.totalPlayers}',
                Icons.people,
                const Color(0xFF6B6BAA),
              ),
              _buildStatCard(
                'Tổng trận đấu',
                '${_stats!.totalGames}',
                Icons.sports_esports,
                const Color(0xFF2C3E78),
              ),
              _buildStatCard(
                'Điểm cao nhất',
                '${_stats!.highestScore}',
                Icons.star,
                const Color(0xFFFFD700),
              ),
              _buildStatCard(
                'Điểm TB',
                _stats!.averageScore.toStringAsFixed(0),
                Icons.analytics,
                const Color(0xFF00BCD4),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Thành tích cá nhân',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_personalBest != null) ...[
            _buildPersonalBestCard(_personalBest!),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E78).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Chưa có thành tích',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestCard(PlayerScore score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B6BAA), Color(0xFF2C3E78)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điểm tốt nhất',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${score.score}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPersonalStat('Thời gian', score.formatTime(), Icons.timer),
              _buildPersonalStat('Nước đi', '${score.moves}', Icons.touch_app),
              if (score.currentRank != null)
                _buildPersonalStat('Hạng', '#${score.currentRank}', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getModeName(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return 'Cổ điển';
      case GameMode.timeAttack:
        return 'Thời gian';
      case GameMode.survival:
        return 'Sinh tồn';
      case GameMode.online:
        return 'Trực tuyến';
    }
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn chế độ chơi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...GameMode.values.map((mode) => ListTile(
              leading: const Icon(Icons.games, color: Colors.white),
              title: Text(
                _getModeName(mode),
                style: const TextStyle(color: Colors.white),
              ),
              selected: mode == _selectedMode,
              selectedTileColor: const Color(0xFF6B6BAA).withValues(alpha: 0.3),
              onTap: () {
                setState(() => _selectedMode = mode);
                Navigator.pop(context);
                _loadScores();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLevelSelector() {
    final levels = LevelData.getLevelsForMode(_selectedMode);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn cấp độ',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isSelected = level == _selectedLevel;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedLevel = level);
                      Navigator.pop(context);
                      _loadScores();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B6BAA)
                            : const Color(0xFF2C3E78),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Cấp $level',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
