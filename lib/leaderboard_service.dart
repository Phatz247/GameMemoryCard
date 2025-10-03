import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_modes.dart';
import 'player_score.dart';

class LeaderboardService {
  static const String _scorePrefix = 'scores_';

  static String _getKey(GameMode mode, int level) =>
    '${_scorePrefix}${mode.name}_$level';

  static Future<void> saveScore(
    GameMode mode,
    int level,
    PlayerScore newScore,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(mode, level);

    // Get existing scores
    final existingScoresJson = prefs.getString(key) ?? '[]';
    List<dynamic> scoresList = jsonDecode(existingScoresJson);

    // Add new score
    scoresList.add(newScore.toJson());

    // Sort by score descending
    scoresList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Keep only top 100 scores
    if (scoresList.length > 100) {
      scoresList = scoresList.take(100).toList();
    }

    // Save back to SharedPreferences
    await prefs.setString(key, jsonEncode(scoresList));
  }

  static Future<List<PlayerScore>> getScores(
    GameMode mode,
    int level,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(mode, level);
    final scoresJson = prefs.getString(key) ?? '[]';

    List<dynamic> scoresList = jsonDecode(scoresJson);
    return scoresList
        .map((json) => PlayerScore.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PlayerScore?> getPersonalBest(
    String playerName,
    GameMode mode,
    int level,
  ) async {
    final scores = await getScores(mode, level);
    return scores
        .where((score) => score.playerName == playerName)
        .fold<PlayerScore?>(null, (max, score) =>
            max == null || score.score > max.score ? score : max);
  }
}
