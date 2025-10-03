// Updated leaderboard design - Version 2.1
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modes.dart';
import 'game_levels.dart';
import 'player_score.dart';
import 'leaderboard_service.dart';

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

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<PlayerScore> _scores = [];
  PlayerScore? _personalBest; // kept for potential future use
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await LeaderboardService.getScores(
      widget.gameMode,
      widget.level,
    );
    final personalBest = await LeaderboardService.getPersonalBest(
      widget.currentPlayer,
      widget.gameMode,
      widget.level,
    );

    if (mounted) {
      setState(() {
        _scores = scores;
        _personalBest = personalBest;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelData.getLevelsForMode(widget.gameMode)[widget.level - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E78), // Dark blue background like mockup
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Text(
                      'Bảng Xếp Hạng',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Level pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    level.name, // ví dụ: "Khối Đầu"
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List scores
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _scores.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có điểm nào được ghi nhận',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final visibleCount = _showAll ? _scores.length : math.min(6, _scores.length);
                            final showSeeMore = !_showAll && _scores.length > visibleCount;
                            final totalItems = showSeeMore ? visibleCount + 1 : visibleCount;
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: totalItems,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (showSeeMore && index == totalItems - 1) {
                                  return _SeeMoreTile(onTap: () => setState(() => _showAll = true));
                                }
                                final score = _scores[index];
                                final isCurrentPlayer = score.playerName == widget.currentPlayer;
                                return _RankingTile(
                                  rank: index + 1,
                                  score: score,
                                  isCurrentPlayer: isCurrentPlayer,
                                  subtitle: 'Lê Văn',
                                );
                              },
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

class _RankingTile extends StatelessWidget {
  final int rank;
  final PlayerScore score;
  final bool isCurrentPlayer;
  final String? subtitle;

  const _RankingTile({
    Key? key,
    required this.rank,
    required this.score,
    required this.isCurrentPlayer,
    this.subtitle,
  }) : super(key: key);

  Map<String, dynamic> _iconForRank() {
    // Icon and color logic to match the mockup
    if (rank == 1) return {'icon': Icons.person, 'color': Colors.green};
    if (rank == 2) return {'icon': Icons.person, 'color': Colors.purple};
    if (rank == 3) return {'icon': Icons.favorite, 'color': Colors.redAccent};
    if (score.playerName == "Bạn") return {'icon': Icons.lock, 'color': Colors.redAccent};
    return {'icon': Icons.person, 'color': Colors.green};
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _iconForRank();
    final IconData icon = iconData['icon'];
    final Color color = iconData['color'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B6BAA).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.playerName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? 'Lê Văn',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${score.score} điểm',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeeMoreTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeMoreTile({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF6B6BAA).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.green, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nguyễn Văn A',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lê Văn',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Xem thêm',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
