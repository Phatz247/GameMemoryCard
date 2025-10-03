// lib/multiplayer_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class MultiplayerService {
  static final rtdb.FirebaseDatabase _database = rtdb.FirebaseDatabase.instance;
  static final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  static String currentUserId = '';
  static String currentUserName = '';

  // Initialize user
  static Future<void> initUser(String name) async {
    currentUserId = DateTime.now().millisecondsSinceEpoch.toString();
    currentUserName = name;
  }

  // Create room
  static Future<GameRoom> createRoom(int level) async {
    final roomId = _generateRoomCode();
    final room = GameRoom(
      roomId: roomId,
      hostId: currentUserId,
      hostName: currentUserName,
      level: level,
      status: 'waiting',
      createdAt: DateTime.now(),
    );

    await _database.ref('rooms/$roomId').set(room.toJson());

    // Auto-delete room after 1 hour
    Future.delayed(const Duration(hours: 1), () {
      _database.ref('rooms/$roomId').remove();
    });

    return room;
  }

  // Join room
  static Future<GameRoom?> joinRoom(String roomCode) async {
    final snapshot = await _database.ref('rooms/$roomCode').get();

    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final room = GameRoom.fromJson(data);

    if (room.status != 'waiting' || room.guestId != null) {
      return null; // Room full or game started
    }

    // Join as guest
    await _database.ref('rooms/$roomCode').update({
      'guestId': currentUserId,
      'guestName': currentUserName,
      'status': 'ready',
    });

    room.guestId = currentUserId;
    room.guestName = currentUserName;
    room.status = 'ready';

    return room;
  }

  // Get available rooms
  static Stream<List<GameRoom>> getAvailableRooms() {
    return _database
        .ref('rooms')
        .orderByChild('status')
        .equalTo('waiting')
        .onValue
        .map((event) {
      final rooms = <GameRoom>[];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final roomData = Map<String, dynamic>.from(value);
          rooms.add(GameRoom.fromJson(roomData));
        });
      }
      return rooms;
    });
  }

  // Start game
  static Future<void> startGame(String roomId) async {
    await _database.ref('rooms/$roomId').update({
      'status': 'playing',
    });

    // Initialize game state
    await _database.ref('games/$roomId').set({
      'cards': {},
      'scores': {
        currentUserId: 0,
      },
      'currentTurn': currentUserId,
      'moves': 0,
      'startTime': rtdb.ServerValue.timestamp,
    });
  }

  // Watch room changes
  static Stream<GameRoom> watchRoom(String roomId) {
    return _database.ref('rooms/$roomId').onValue.map((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return GameRoom.fromJson(data);
    });
  }

  // Watch game state
  static Stream<Map<String, dynamic>> watchGameState(String roomId) {
    return _database.ref('games/$roomId').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return <String, dynamic>{};
    });
  }

  // Flip card
  static Future<void> flipCard(String roomId, String cardId, String playerId) async {
    await _database.ref('games/$roomId/lastAction').set({
      'type': 'flip',
      'cardId': cardId,
      'playerId': playerId,
      'timestamp': rtdb.ServerValue.timestamp,
    });
  }

  // Update score
  static Future<void> updateScore(String roomId, String playerId, int score) async {
    await _database.ref('games/$roomId/scores/$playerId').set(score);
  }

  // Leave room
  static Future<void> leaveRoom(String roomId, String playerId) async {
    final roomRef = _database.ref('rooms/$roomId');
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      if (data['hostId'] == playerId) {
        // Host leaves, delete room
        await roomRef.remove();
        await _database.ref('games/$roomId').remove();
      } else if (data['guestId'] == playerId) {
        // Guest leaves, reset room
        await roomRef.update({
          'guestId': null,
          'guestName': null,
          'status': 'waiting',
        });
      }
    }
  }

  // Generate room code
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }
    return code;
  }
}

// Game Room model
class GameRoom {
  final String roomId;
  final String hostId;
  final String hostName;
  String? guestId;
  String? guestName;
  final int level;
  String status; // waiting, ready, playing, finished
  final DateTime createdAt;

  GameRoom({
    required this.roomId,
    required this.hostId,
    required this.hostName,
    this.guestId,
    this.guestName,
    required this.level,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'hostId': hostId,
        'hostName': hostName,
        'guestId': guestId,
        'guestName': guestName,
        'level': level,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory GameRoom.fromJson(Map<String, dynamic> json) => GameRoom(
        roomId: json['roomId'] as String,
        hostId: json['hostId'] as String,
        hostName: json['hostName'] as String,
        guestId: json['guestId'] as String?,
        guestName: json['guestName'] as String?,
        level: json['level'] as int,
        status: json['status'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );
}
