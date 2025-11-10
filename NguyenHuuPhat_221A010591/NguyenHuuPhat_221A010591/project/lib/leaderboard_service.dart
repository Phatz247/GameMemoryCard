import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_modes.dart';
import 'player_score.dart';

enum LeaderboardPeriod { allTime, today, thisWeek, thisMonth }

class LeaderboardStats {
  final int totalPlayers;
  final int totalGames;
  final double averageScore;
  final int highestScore;
  final String topPlayer;

  LeaderboardStats({
    required this.totalPlayers,
    required this.totalGames,
    required this.averageScore,
    required this.highestScore,
    required this.topPlayer,
  });
}

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

    
    final existingScoresJson = prefs.getString(key) ?? '[]';
    List<dynamic> scoresList = jsonDecode(existingScoresJson);

    
    final updatedScore = PlayerScore(
      playerName: newScore.playerName,
      score: newScore.score,
      moves: newScore.moves,
      timeSpent: newScore.timeSpent,
      playedAt: newScore.playedAt,
      avatarUrl: newScore.avatarUrl,
      previousRank: newScore.currentRank,
      currentRank: null, // Will be calculated
      consecutiveWins: newScore.consecutiveWins,
      country: newScore.country,
    );

    scoresList.add(updatedScore.toJson());

    scoresList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    for (int i = 0; i < scoresList.length; i++) {
      scoresList[i]['currentRank'] = i + 1;
    }

    if (scoresList.length > 100) {
      scoresList = scoresList.take(100).toList();
    }

    await prefs.setString(key, jsonEncode(scoresList));
  }

  static Future<List<PlayerScore>> getScores(
    GameMode mode,
    int level, {
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    int limit = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(mode, level);
    final scoresJson = prefs.getString(key) ?? '[]';

    List<dynamic> scoresList = jsonDecode(scoresJson);
    List<PlayerScore> scores = scoresList
        .map((json) => PlayerScore.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filter by period
    if (period != LeaderboardPeriod.allTime) {
      final now = DateTime.now();
      scores = scores.where((score) {
        switch (period) {
          case LeaderboardPeriod.today:
            return score.playedAt.year == now.year &&
                score.playedAt.month == now.month &&
                score.playedAt.day == now.day;
          case LeaderboardPeriod.thisWeek:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            return score.playedAt.isAfter(weekStart);
          case LeaderboardPeriod.thisMonth:
            return score.playedAt.year == now.year &&
                score.playedAt.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    return scores.take(limit).toList();
  }

  static Future<PlayerScore?> getPersonalBest(
    String playerName,
    GameMode mode,
    int level,
  ) async {
    final scores = await getScores(mode, level);
    final playerScores = scores
        .where((score) => score.playerName == playerName)
        .toList();

    if (playerScores.isEmpty) return null;

    return playerScores.reduce(
      (max, score) => score.score > max.score ? score : max,
    );
  }

  static Future<int?> getPlayerRank(
    String playerName,
    GameMode mode,
    int level,
  ) async {
    final scores = await getScores(mode, level);

    for (int i = 0; i < scores.length; i++) {
      if (scores[i].playerName == playerName) {
        return i + 1;
      }
    }

    return null;
  }

  static Future<List<PlayerScore>> searchPlayers(
    String query,
    GameMode mode,
    int level,
  ) async {
    final scores = await getScores(mode, level);
    final lowerQuery = query.toLowerCase();

    return scores
        .where((score) => score.playerName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  static Future<LeaderboardStats> getStats(GameMode mode, int level) async {
    final scores = await getScores(mode, level);

    if (scores.isEmpty) {
      return LeaderboardStats(
        totalPlayers: 0,
        totalGames: 0,
        averageScore: 0,
        highestScore: 0,
        topPlayer: '',
      );
    }

    final uniquePlayers = <String>{};
    int totalScore = 0;

    for (final score in scores) {
      uniquePlayers.add(score.playerName);
      totalScore += score.score;
    }

    return LeaderboardStats(
      totalPlayers: uniquePlayers.length,
      totalGames: scores.length,
      averageScore: totalScore / scores.length,
      highestScore: scores.first.score,
      topPlayer: scores.first.playerName,
    );
  }

  static Future<List<PlayerScore>> getTopScoresAllLevels(
    GameMode mode, {
    int topN = 10,
  }) async {
    final allScores = <PlayerScore>[];

    // Collect scores from all levels
    for (int level = 1; level <= 10; level++) {
      final levelScores = await getScores(mode, level);
      allScores.addAll(levelScores);
    }

    // Sort by score
    allScores.sort((a, b) => b.score.compareTo(a.score));

    return allScores.take(topN).toList();
  }

  static Future<void> clearLeaderboard(GameMode mode, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(mode, level);
    await prefs.remove(key);
  }

  static Future<Map<String, dynamic>> getPlayerStats(
    String playerName,
    GameMode mode,
    int level,
  ) async {
    final scores = await getScores(mode, level);
    final playerScores = scores
        .where((s) => s.playerName == playerName)
        .toList();

    if (playerScores.isEmpty) {
      return {
        'gamesPlayed': 0,
        'bestScore': 0,
        'averageScore': 0.0,
        'bestRank': null,
        'totalTime': 0,
      };
    }

    int totalScore = 0;
    int totalTime = 0;
    int bestScore = 0;
    int? bestRank;

    for (final score in playerScores) {
      totalScore += score.score;
      totalTime += score.timeSpent;
      if (score.score > bestScore) bestScore = score.score;
      if (score.currentRank != null) {
        if (bestRank == null || score.currentRank! < bestRank) {
          bestRank = score.currentRank;
        }
      }
    }

    return {
      'gamesPlayed': playerScores.length,
      'bestScore': bestScore,
      'averageScore': totalScore / playerScores.length,
      'bestRank': bestRank,
      'totalTime': totalTime,
    };
  }
}
