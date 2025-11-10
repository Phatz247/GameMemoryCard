import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để đồng bộ thời gian với Firebase Server
class TimeSyncService {
  static final TimeSyncService _instance = TimeSyncService._internal();
  factory TimeSyncService() => _instance;
  TimeSyncService._internal();

  int _serverOffset = 0; // milliseconds offset
  bool _initialized = false;
  final _controller = StreamController<int>.broadcast();
  Timer? _resyncTimer;

  /// Stream để lắng nghe thay đổi offset
  Stream<int> get offsetStream => _controller.stream;

  /// Đồng bộ thời gian với Firebase Server bằng cách so sánh với server timestamp
  /// Sử dụng Firestore ServerTimestamp để độ chính xác cao hơn
  Future<void> syncWithServer() async {
    try {
      final beforeLocal = DateTime.now().millisecondsSinceEpoch;

      // Tạo reference tới Firestore document
      final docRef = FirebaseFirestore.instance
          .collection('_sync')
          .doc('_time_${DateTime.now().millisecondsSinceEpoch}');

      // Ghi ServerTimestamp lên Firestore
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      // Đọc lại để lấy server timestamp
      final snapshot = await docRef.get();
      final afterLocal = DateTime.now().millisecondsSinceEpoch;

      if (snapshot.exists && snapshot['timestamp'] != null) {
        final serverTimestamp = snapshot['timestamp'] as Timestamp;
        final serverTime =
            serverTimestamp.millisecondsSinceEpoch; // Lấy từ Firestore server

        // Tính latency chính xác hơn
        final latency = (afterLocal - beforeLocal) ~/ 2;

        // Tính offset: chênh lệch giữa server time và local time
        // Server time đã được điều chỉnh với latency
        _serverOffset = (serverTime - beforeLocal - latency);
        _initialized = true;
        _controller.add(_serverOffset);

        print(
          '🕐 Server time synced! Offset: ${_serverOffset}ms (Latency: ${latency}ms)',
        );
        print(
          '   Before Local: ${DateTime.fromMillisecondsSinceEpoch(beforeLocal)}',
        );
        print(
          '   Server Time: ${DateTime.fromMillisecondsSinceEpoch(serverTime)}',
        );
        print(
          '   After Local: ${DateTime.fromMillisecondsSinceEpoch(afterLocal)}',
        );

        // Xóa document sync
        await docRef.delete();
      }
    } catch (e) {
      print('❌ Error syncing with server: $e');
      _serverOffset = 0;
    }
  }

  /// Lấy thời gian server hiện tại (milliseconds since epoch)
  int getServerTimeMillis() {
    return DateTime.now().millisecondsSinceEpoch + _serverOffset;
  }

  /// Lấy thời gian server hiện tại (DateTime)
  DateTime getServerTime() {
    return DateTime.fromMillisecondsSinceEpoch(getServerTimeMillis());
  }

  /// Tính thời gian còn lại (giây) dựa trên startTime và duration
  int calculateRemainingTime({
    required DateTime startTime,
    required int durationSeconds,
  }) {
    final serverNow = getServerTimeMillis();
    final endTime = startTime.millisecondsSinceEpoch + (durationSeconds * 1000);
    final remaining = ((endTime - serverNow) / 1000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  /// Tính thời gian còn lại từ milliseconds
  int calculateRemainingTimeFromMillis({
    required int startTimeMillis,
    required int durationSeconds,
  }) {
    final serverNow = getServerTimeMillis();
    final endTime = startTimeMillis + (durationSeconds * 1000);
    final remaining = ((endTime - serverNow) / 1000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  Future<void> initialize() async {
    if (_initialized) {
      // Đồng bộ lại để cập nhật offset
      await syncWithServer();
      return;
    }

    await syncWithServer();

    // Tự động đồng bộ lại mỗi 2 phút để giữ độ chính xác
    // (Giảm từ 5 phút xuống 2 phút để cập nhật thường xuyên hơn)
    _resyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      syncWithServer();
    });
  }

  /// Kiểm tra xem đã khởi tạo chưa
  bool get isInitialized => _initialized;

  /// Lấy offset hiện tại (milliseconds)
  int get currentOffset => _serverOffset;

  void dispose() {
    _resyncTimer?.cancel();
    _controller.close();
  }
}
