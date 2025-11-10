class PlayerScore {
  final String playerName;
  final int score;
  final int moves;
  final int timeSpent;
  final DateTime playedAt;
  final String? avatarUrl;
  final int? previousRank;
  final int? currentRank;
  final int consecutiveWins;
  final String? country;

  const PlayerScore({
    required this.playerName,
    required this.score,
    required this.moves,
    required this.timeSpent,
    required this.playedAt,
    this.avatarUrl,
    this.previousRank,
    this.currentRank,
    this.consecutiveWins = 0,
    this.country,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'score': score,
    'moves': moves,
    'timeSpent': timeSpent,
    'playedAt': playedAt.toIso8601String(),
    'avatarUrl': avatarUrl,
    'previousRank': previousRank,
    'currentRank': currentRank,
    'consecutiveWins': consecutiveWins,
    'country': country,
  };

  factory PlayerScore.fromJson(Map<String, dynamic> json) => PlayerScore(
    playerName: json['playerName'] as String,
    score: json['score'] as int,
    moves: json['moves'] as int,
    timeSpent: json['timeSpent'] as int,
    playedAt: DateTime.parse(json['playedAt'] as String),
    avatarUrl: json['avatarUrl'] as String?,
    previousRank: json['previousRank'] as int?,
    currentRank: json['currentRank'] as int?,
    consecutiveWins: json['consecutiveWins'] as int? ?? 0,
    country: json['country'] as String?,
  );

  // Helper methods
  int? get rankChange {
    if (previousRank == null || currentRank == null) return null;
    return previousRank! - currentRank!;
  }

  bool get isImproving => rankChange != null && rankChange! > 0;
  bool get isDeclining => rankChange != null && rankChange! < 0;

  String formatTime() {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String formatDate() {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
    }
  }
}
