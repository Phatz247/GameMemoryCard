import 'package:flutter/material.dart';
import 'game_modes.dart';

class GameLevel {
  final String name;
  final String description;
  final int timeLimit;
  final int gridRows;
  final int gridCols;
  final int targetScore;
  final List<IconData> availableIcons;
  final bool isLocked;
  final Map<String, dynamic> modeSpecific;

  const GameLevel({
    required this.name,
    required this.description,
    required this.timeLimit,
    required this.gridRows,
    required this.gridCols,
    required this.targetScore,
    required this.availableIcons,
    this.isLocked = true,
    this.modeSpecific = const {},
  });
}

class LevelData {
  static const classicLevels = [
    GameLevel(
      name: "Khởi Đầu",
      description: "Tìm các cặp thẻ cơ bản",
      timeLimit: 60,
      gridRows: 3,
      gridCols: 4,
      targetScore: 300,
      isLocked: false,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.cake,
      ],
    ),
    GameLevel(
      name: "Thử Thách",
      description: "Nhiều cặp thẻ hơn, thời gian ít hơn",
      timeLimit: 90,
      gridRows: 4,
      gridCols: 4,
      targetScore: 500,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
      ],
    ),
    GameLevel(
      name: "Chuyên Gia",
      description: "Bạn đã sẵn sàng với thử thách khó nhất?",
      timeLimit: 120,
      gridRows: 4,
      gridCols: 5,
      targetScore: 800,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
        Icons.music_note, Icons.pets,
      ],
    ),
  ];

  static const timeAttackLevels = [
    GameLevel(
      name: "Tốc Độ 1",
      description: "60 giây để đạt điểm cao nhất",
      timeLimit: 60,
      gridRows: 4,
      gridCols: 4,
      targetScore: 400,
      isLocked: false,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
      ],
      modeSpecific: {
        'timeBonus': 2,
        'comboMultiplier': 1.5,
      },
    ),
    GameLevel(
      name: "Tốc Độ 2",
      description: "45 giây, điểm combo cao hơn",
      timeLimit: 45,
      gridRows: 4,
      gridCols: 4,
      targetScore: 600,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
      ],
      modeSpecific: {
        'timeBonus': 3,
        'comboMultiplier': 2.0,
      },
    ),
    GameLevel(
      name: "Tốc Độ Max",
      description: "30 giây, thử thách tốc độ tối đa",
      timeLimit: 30,
      gridRows: 4,
      gridCols: 4,
      targetScore: 800,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
      ],
      modeSpecific: {
        'timeBonus': 4,
        'comboMultiplier': 2.5,
      },
    ),
  ];

  static const survivalLevels = [
    GameLevel(
      name: "Sinh Tồn 1",
      description: "5 mạng, mỗi lần sai -1",
      timeLimit: -1,
      gridRows: 3,
      gridCols: 4,
      targetScore: 300,
      isLocked: false,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.cake,
      ],
      modeSpecific: {
        'startingHP': 5,
        'damageTaken': 1,
      },
    ),
    GameLevel(
      name: "Sinh Tồn 2",
      description: "4 mạng, mỗi lần sai -1",
      timeLimit: -1,
      gridRows: 4,
      gridCols: 4,
      targetScore: 500,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
      ],
      modeSpecific: {
        'startingHP': 4,
        'damageTaken': 1,
      },
    ),
    GameLevel(
      name: "Sinh Tồn 3",
      description: "3 mạng, mỗi lần sai -2",
      timeLimit: -1,
      gridRows: 4,
      gridCols: 5,
      targetScore: 800,
      availableIcons: [
        Icons.star, Icons.favorite, Icons.cloud, Icons.wb_sunny,
        Icons.anchor, Icons.bug_report, Icons.cake, Icons.lightbulb,
        Icons.music_note, Icons.pets,
      ],
      modeSpecific: {
        'startingHP': 3,
        'damageTaken': 2,
      },
    ),
  ];

  static List<GameLevel> getLevelsForMode(GameMode mode) {
    return switch (mode) {
      GameMode.classic => classicLevels,
      GameMode.timeAttack => timeAttackLevels,
      GameMode.survival => survivalLevels,
      GameMode.online => classicLevels, // Online mode uses classic levels
    };
  }
}
