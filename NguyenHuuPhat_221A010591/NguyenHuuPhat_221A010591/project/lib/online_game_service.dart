import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'auth_service.dart';
import 'time_sync_service.dart';
import 'chat_message.dart';

enum RoomStatus { waiting, playing, finished }

class PlayerData {
  final String uid;
  final String name;
  final int score;

  PlayerData({required this.uid, required this.name, required this.score});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'score': score};
  }

  factory PlayerData.fromMap(Map<String, dynamic> map) {
    return PlayerData(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      score: map['score'] ?? 0,
    );
  }
}

class GameCard {
  final int id;
  final String image;
  bool flipped;
  bool matched;

  GameCard({
    required this.id,
    required this.image,
    this.flipped = false,
    this.matched = false,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'image': image, 'flipped': flipped, 'matched': matched};
  }

  factory GameCard.fromMap(Map<String, dynamic> map) {
    return GameCard(
      id: map['id'] ?? 0,
      image: map['image'] ?? '',
      flipped: map['flipped'] ?? false,
      matched: map['matched'] ?? false,
    );
  }
}

class OnlineGameRoom {
  final String roomId;
  PlayerData? p1;
  PlayerData? p2;
  String currentTurn; // "p1" or "p2"
  List<GameCard> cards;
  RoomStatus status;
  DateTime createdAt;
  DateTime? startTime;
  int timeLimit;
  Map<String, bool> rematchRequests; // { "p1": true/false, "p2": true/false }

  OnlineGameRoom({
    required this.roomId,
    this.p1,
    this.p2,
    this.currentTurn = 'p1',
    this.cards = const [],
    this.status = RoomStatus.waiting,
    required this.createdAt,
    this.startTime,
    this.timeLimit = 90,
    this.rematchRequests = const {},
  });

  // Helper getters for backward compatibility
  String get hostId => p1?.uid ?? '';
  String get hostName => p1?.name ?? 'Host';
  String? get guestId => p2?.uid;
  String? get guestName => p2?.name;
  int get hostScore => p1?.score ?? 0;
  int get guestScore => p2?.score ?? 0;

  //  Tính thời gian còn lại (đồng bộ giữa 2 người) - SỬ DỤNG TimeSyncService
  int getRemainingTime() {
    if (startTime == null) return timeLimit;
    return TimeSyncService().calculateRemainingTime(
      startTime: startTime!,
      durationSeconds: timeLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'players': {'p1': p1?.toMap(), 'p2': p2?.toMap()},
      'currentTurn': currentTurn,
      'cards': cards.map((card) => card.toMap()).toList(),
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startTime': startTime?.millisecondsSinceEpoch,
      'timeLimit': timeLimit,
      'rematchRequests': rematchRequests,
    };
  }

  factory OnlineGameRoom.fromMap(String roomId, Map<String, dynamic> map) {
    final playersMap = map['players'] as Map<String, dynamic>? ?? {};

    // ⭐ Parse startTime - có thể là Timestamp hoặc int
    DateTime? parsedStartTime;
    final startTimeValue = map['startTime'];
    if (startTimeValue != null) {
      if (startTimeValue is Timestamp) {
        parsedStartTime = startTimeValue.toDate();
      } else if (startTimeValue is int) {
        parsedStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeValue);
      }
    }

    // Parse rematchRequests - { "p1": bool, "p2": bool }
    final rematchRequests = <String, bool>{};
    final rematchData = map['rematchRequests'] as Map<String, dynamic>? ?? {};
    for (var key in rematchData.keys) {
      rematchRequests[key] = rematchData[key] ?? false;
    }

    return OnlineGameRoom(
      roomId: roomId,
      p1: playersMap['p1'] != null
          ? PlayerData.fromMap(playersMap['p1'])
          : null,
      p2: playersMap['p2'] != null
          ? PlayerData.fromMap(playersMap['p2'])
          : null,
      currentTurn: map['currentTurn'] ?? 'p1',
      cards:
          (map['cards'] as List<dynamic>?)
              ?.map((card) => GameCard.fromMap(card as Map<String, dynamic>))
              .toList() ??
          [],
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoomStatus.waiting,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      startTime: parsedStartTime,
      timeLimit: map['timeLimit'] ?? 90,
      rematchRequests: rematchRequests,
    );
  }
}

class OnlineGameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  // Tạo phòng chơi mới
  Future<OnlineGameRoom> createRoom({
    required String playerName,
    int numberOfPairs = 8,
    int timeLimit = 90,
  }) async {
    try {
      //  Sử dụng Firebase Auth UID thật
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'guest_${Random().nextInt(10000)}';

      //  Lấy display name từ AuthService
      final displayName = await _authService.getDisplayName();

      print('Creating room for user: $userId, name: $displayName');

      final roomId = _generateRoomId();
      final cards = _generateCards(numberOfPairs);

      print('Generated roomId: $roomId with ${cards.length} cards');

      final room = OnlineGameRoom(
        roomId: roomId,
        p1: PlayerData(uid: userId, name: displayName, score: 0),
        p2: null,
        currentTurn: 'p1',
        cards: cards,
        status: RoomStatus.waiting,
        createdAt: DateTime.now(),
        timeLimit: timeLimit,
      );

      print('Saving room to Firestore...');
      await _firestore.collection('rooms').doc(roomId).set(room.toMap());
      print('Room created successfully: $roomId');

      return room;
    } catch (e, stackTrace) {
      print('ERROR creating room: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Tham gia phòng chơi
  Future<bool> joinRoom(String roomId, String playerName) async {
    //  Sử dụng Firebase Auth UID thật
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'guest_${Random().nextInt(10000)}';
    final displayName = await _authService.getDisplayName();

    try {
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);

        if (!roomDoc.exists) {
          print('Room $roomId does not exist');
          return false;
        }

        final roomData = roomDoc.data()!;
        final playersMap = roomData['players'] as Map<String, dynamic>? ?? {};

        //  Kiểm tra không cho host tham gia phòng của chính mình
        final p1Uid = playersMap['p1']?['uid'];
        if (p1Uid == userId) {
          print('Cannot join your own room');
          return false;
        }

        // Kiểm tra phòng đã đầy chưa
        if (playersMap['p2'] != null) {
          print('Room $roomId is full');
          return false;
        }

        final status = roomData['status'] as String?;
        if (status != 'waiting') {
          print('Room $roomId is not waiting (status: $status)');
          return false;
        }

        //  Cập nhật phòng với transaction
        transaction.update(roomRef, {
          'players.p2': {'uid': userId, 'name': displayName, 'score': 0},
          'status': 'playing',
          'startTime': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (result) {
        print('Successfully joined room $roomId');
      }
      return result;
    } catch (e) {
      print('Error joining room: $e');
      return false;
    }
  }

  // Tìm phòng ngẫu nhiên hoặc tạo mới
  Future<OnlineGameRoom?> findRandomRoom(String playerName) async {
    try {
      print('🔍 Finding random room for: $playerName');

      final querySnapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();

      print('Found ${querySnapshot.docs.length} waiting rooms');

      // Tìm phòng chưa có p2
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final playersMap = data['players'] as Map<String, dynamic>? ?? {};

        print(
          'Checking room ${doc.id}: p1=${playersMap['p1']?['name']}, p2=${playersMap['p2']}',
        );

        if (playersMap['p2'] == null) {
          final roomId = doc.id;
          print('Attempting to join room: $roomId');
          final joined = await joinRoom(roomId, playerName);

          if (joined) {
            print('Successfully joined room: $roomId');
            final updatedDoc = await _firestore
                .collection('rooms')
                .doc(roomId)
                .get();
            return OnlineGameRoom.fromMap(roomId, updatedDoc.data()!);
          }
        }
      }

      // Không tìm thấy phòng, tạo phòng mới
      print('No available rooms found, creating new room...');
      return await createRoom(playerName: playerName, numberOfPairs: 8);
    } catch (e, stackTrace) {
      print('Error finding room: $e');
      print('Stack trace: $stackTrace');

      // Nếu lỗi, vẫn cố tạo phòng mới
      try {
        print('Attempting to create new room after error...');
        return await createRoom(playerName: playerName, numberOfPairs: 8);
      } catch (createError) {
        print('Error creating room: $createError');
        return null;
      }
    }
  }

  // Lật bài - Logic chính của game
  Future<void> flipCard(String roomId, int cardIndex, String playerId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = OnlineGameRoom.fromMap(roomId, roomDoc.data()!);

      // Kiểm tra có phải lượt mình không
      final isP1 = room.p1?.uid == playerId;
      final isP2 = room.p2?.uid == playerId;
      final myTurn =
          (isP1 && room.currentTurn == 'p1') ||
          (isP2 && room.currentTurn == 'p2');

      if (!myTurn) {
        print('Not your turn!');
        return;
      }

      // Kiểm tra card có hợp lệ không
      if (cardIndex < 0 || cardIndex >= room.cards.length) return;
      final card = room.cards[cardIndex];

      if (card.flipped || card.matched) {
        print('Card already flipped or matched');
        return;
      }

      // Đếm số lá đã lật (chưa matched)
      final flippedCards = room.cards
          .where((c) => c.flipped && !c.matched)
          .toList();

      if (flippedCards.length >= 2) {
        print('Already have 2 cards flipped');
        return;
      }

      // Lật card
      room.cards[cardIndex].flipped = true;
      await _firestore.collection('rooms').doc(roomId).update({
        'cards': room.cards.map((c) => c.toMap()).toList(),
      });

      // Nếu đã có 2 lá được lật, kiểm tra match
      final nowFlipped = room.cards
          .where((c) => c.flipped && !c.matched)
          .toList();
      if (nowFlipped.length == 2) {
        // Chờ 1.5 giây để người chơi nhìn thấy
        await Future.delayed(Duration(milliseconds: 1500));
        await _checkMatch(roomId, playerId);
      }
    } catch (e) {
      print('Error flipping card: $e');
    }
  }

  // Kiểm tra 2 lá có match không
  Future<void> _checkMatch(String roomId, String playerId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = OnlineGameRoom.fromMap(roomId, roomDoc.data()!);
      final flippedCards = room.cards
          .where((c) => c.flipped && !c.matched)
          .toList();

      if (flippedCards.length != 2) return;

      final card1 = flippedCards[0];
      final card2 = flippedCards[1];

      if (card1.image == card2.image) {
        // MATCH! - Đánh dấu matched và cộng điểm
        final isP1 = room.p1?.uid == playerId;

        for (var card in room.cards) {
          if (card.id == card1.id || card.id == card2.id) {
            card.matched = true;
            card.flipped = false; // Reset flipped sau khi matched
          }
        }

        // Cộng điểm cho người chơi hiện tại
        final newP1Score = isP1 ? (room.p1!.score + 10) : room.p1!.score;
        final newP2Score = !isP1 ? (room.p2!.score + 10) : room.p2!.score;

        final updateData = {
          'cards': room.cards.map((c) => c.toMap()).toList(),
          'players.p1.score': newP1Score,
        };

        if (room.p2 != null) {
          updateData['players.p2.score'] = newP2Score;
        }

        // Giữ lượt khi match (không đổi currentTurn)

        await _firestore.collection('rooms').doc(roomId).update(updateData);

        // Kiểm tra xem tất cả các lá đã matched chưa
        final allMatched = room.cards.every((c) => c.matched);
        if (allMatched) {
          await endGame(roomId);
        }
      } else {
        // KHÔNG MATCH - Úp lại và đổi lượt
        for (var card in room.cards) {
          if (card.id == card1.id || card.id == card2.id) {
            card.flipped = false;
          }
        }

        final nextTurn = room.currentTurn == 'p1' ? 'p2' : 'p1';

        await _firestore.collection('rooms').doc(roomId).update({
          'cards': room.cards.map((c) => c.toMap()).toList(),
          'currentTurn': nextTurn,
        });
      }
    } catch (e) {
      print('Error checking match: $e');
    }
  }

  // Kết thúc game
  Future<void> endGame(String roomId) async {
    try {
      print('🏁 Ending game for room: $roomId');
      await _firestore.collection('rooms').doc(roomId).update({
        'status': 'finished',
      });
      print('Game ended successfully');
    } catch (e) {
      print('Error ending game: $e');
    }
  }

  // Lắng nghe thay đổi phòng
  Stream<OnlineGameRoom?> watchRoom(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return OnlineGameRoom.fromMap(roomId, snapshot.data()!);
    });
  }

  // Lấy danh sách phòng đang chờ
  Stream<List<OnlineGameRoom>> getAvailableRooms() {
    try {
      print('📡 Starting to listen for available rooms...');
      return _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .limit(20)
          .snapshots()
          .map((snapshot) {
            print('📦 Received ${snapshot.docs.length} rooms from Firestore');
            final rooms = snapshot.docs.map((doc) {
              print('Room: ${doc.id}, Status: ${doc.data()['status']}');
              return OnlineGameRoom.fromMap(doc.id, doc.data());
            }).toList();

            // Sort locally instead of in Firestore
            rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return rooms;
          });
    } catch (e) {
      print('Error in getAvailableRooms: $e');
      return Stream.value([]);
    }
  }

  // Xóa phòng
  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  // Đề nghị chơi lại
  Future<void> requestRematch(String roomId, String playerId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = OnlineGameRoom.fromMap(roomId, roomDoc.data()!);

      // Determine which player is requesting
      final isP1 = room.p1?.uid == playerId;
      final playerKey = isP1 ? 'p1' : 'p2';

      await _firestore.collection('rooms').doc(roomId).update({
        'rematchRequests.$playerKey': true,
      });
      print('✅ Rematch requested by $playerKey');
    } catch (e) {
      print('Error requesting rematch: $e');
    }
  }

  // Hủy đề nghị chơi lại
  Future<void> cancelRematchRequest(String roomId, String playerId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = OnlineGameRoom.fromMap(roomId, roomDoc.data()!);

      // Determine which player is cancelling
      final isP1 = room.p1?.uid == playerId;
      final playerKey = isP1 ? 'p1' : 'p2';

      await _firestore.collection('rooms').doc(roomId).update({
        'rematchRequests.$playerKey': false,
      });
      print('❌ Rematch cancelled by $playerKey');
    } catch (e) {
      print('Error cancelling rematch: $e');
    }
  }

  // Reset phòng cho ván chơi mới
  Future<void> resetForRematch(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      // Reset bài
      final newCards = _generateCards(8);

      // Update Firestore directly
      await _firestore.collection('rooms').doc(roomId).update({
        'cards': newCards.map((c) => c.toMap()).toList(),
        'players.p1.score': 0,
        'players.p2.score': 0,
        'currentTurn': 'p1',
        'status': 'playing',
        'startTime': FieldValue.serverTimestamp(),
        'rematchRequests': {'p1': false, 'p2': false},
      });

      print('🔄 Room reset for rematch');
    } catch (e) {
      print('Error resetting room for rematch: $e');
    }
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  List<GameCard> _generateCards(int numberOfPairs) {
    final images = [
      'hinh1.jpg',
      'hinh2.jpg',
      'hinh3.jpg',
      'hinh4.jpg',
      'hinh5.jpg',
      'hinh6.jpg',
      'hinh7.jpg',
      'hinh8.jpg',
      'hinh9.jpg',
      'hinh10.jpg',
      'hinh11.jpg',
      'hinh12.jpg',
    ];

    // Lấy numberOfPairs hình đầu tiên
    final selectedImages = images.take(numberOfPairs).toList();

    // Tạo cặp (mỗi hình 2 lần)
    final cardImages = <String>[];
    for (var img in selectedImages) {
      cardImages.add(img);
      cardImages.add(img);
    }

    // Shuffle ngẫu nhiên
    cardImages.shuffle(Random());

    // Tạo GameCard objects
    return List.generate(
      cardImages.length,
      (index) => GameCard(
        id: index,
        image: cardImages[index],
        flipped: false,
        matched: false,
      ),
    );
  }

  // Gửi tin nhắn chat
  Future<void> sendChatMessage(
    String roomId,
    String senderId,
    String senderName,
    String message,
  ) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final chatMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('chat')
          .doc(messageId)
          .set(chatMessage.toMap());

      print('💬 Tin nhắn đã gửi: $message');
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
    }
  }

  // Nghe tin nhắn chat
  Stream<List<ChatMessage>> watchChatMessages(String roomId) {
    try {
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('chat')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ChatMessage.fromMap(doc.data()))
                .toList(),
          );
    } catch (e) {
      print('Lỗi nghe tin nhắn: $e');
      return Stream.value([]);
    }
  }
}
