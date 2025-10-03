import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modes.dart';
import 'game_levels.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final GameMode gameMode;
  final GameTheme theme;

  const LevelSelectionScreen({
    Key? key,
    required this.gameMode,
    required this.theme,
  }) : super(key: key);

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late final List<GameLevel> levels;

  @override
  void initState() {
    super.initState();
    levels = LevelData.getLevelsForMode(widget.gameMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chọn màn chơi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade900,
              Colors.indigo.shade500,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final isLocked = index > 0 && levels[index - 1].isLocked;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildLevelCard(level, index + 1, isLocked),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(GameLevel level, int levelNumber, bool isLocked) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isLocked ? null : () => _startLevel(level),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey : Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level $levelNumber',
                      style: GoogleFonts.poppins(
                        color: isLocked ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isLocked)
                    const Icon(Icons.lock, color: Colors.grey)
                  else
                    Icon(
                      switch (widget.gameMode) {
                        GameMode.classic => Icons.grid_4x4,
                        GameMode.timeAttack => Icons.timer,
                        GameMode.survival => Icons.favorite,
                        GameMode.challenge => Icons.warning,
                      },
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                level.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                level.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.grid_4x4,
                    label: '${level.gridRows}x${level.gridCols}',
                  ),
                  const SizedBox(width: 8),
                  if (level.timeLimit > 0) ...[
                    _buildStatChip(
                      icon: Icons.timer,
                      label: '${level.timeLimit}s',
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildStatChip(
                    icon: Icons.stars,
                    label: '${level.targetScore}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _startLevel(GameLevel level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          config: GameConfig(
            mode: widget.gameMode,
            difficulty: _getDifficultyForLevel(level),
            theme: widget.theme,
          ),
        ),
      ),
    );
  }

  Difficulty _getDifficultyForLevel(GameLevel level) {
    if (level.gridRows <= 3) return Difficulty.easy;
    if (level.gridRows <= 4 && level.gridCols <= 4) return Difficulty.medium;
    return Difficulty.hard;
  }
}
