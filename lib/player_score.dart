class PlayerScore {
  final String playerName;
  final int score;
  final int moves;
  final int timeSpent;
  final DateTime playedAt;

  const PlayerScore({
    required this.playerName,
    required this.score,
    required this.moves,
    required this.timeSpent,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'score': score,
    'moves': moves,
    'timeSpent': timeSpent,
    'playedAt': playedAt.toIso8601String(),
  };

  factory PlayerScore.fromJson(Map<String, dynamic> json) => PlayerScore(
    playerName: json['playerName'] as String,
    score: json['score'] as int,
    moves: json['moves'] as int,
    timeSpent: json['timeSpent'] as int,
    playedAt: DateTime.parse(json['playedAt'] as String),
  );
}
