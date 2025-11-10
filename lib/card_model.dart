import 'package:flutter/material.dart';

enum CardType {
  normal,
  bomb,
  ice,
  bonus,
  shield
}

class CardItem {
  final int iconIndex;
  final String imagePath;
  final CardType type;
  bool isFlipped;
  bool isMatched;
  bool isFrozen;
  late AnimationController controller;
  late Animation<double> animation;

  CardItem({
    required this.iconIndex,
    required this.imagePath,
    this.type = CardType.normal,
    this.isFlipped = false,
    this.isMatched = false,
    this.isFrozen = false,
  });

  void initAnimation(TickerProvider vsync) {
    controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller);
  }

  void dispose() {
    controller.dispose();
  }

  Map<String, dynamic> toJson() => {
    'iconIndex': iconIndex,
    'imagePath': imagePath,
    'type': type.toString(),
    'isFlipped': isFlipped,
    'isMatched': isMatched,
    'isFrozen': isFrozen,
  };

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
    iconIndex: json['iconIndex'],
    imagePath: json['imagePath'],
    type: CardType.values.firstWhere((e) => e.toString() == json['type']),
    isFlipped: json['isFlipped'],
    isMatched: json['isMatched'],
    isFrozen: json['isFrozen'],
  );
}
