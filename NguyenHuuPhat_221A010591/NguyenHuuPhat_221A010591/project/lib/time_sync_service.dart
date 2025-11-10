import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Service để đồng bộ thời gian với Firebase Server
class TimeSyncService {
  static final TimeSyncService _instance = TimeSyncService._internal();
  factory TimeSyncService() => _instance;
  TimeSyncService._internal();

  int _serverOffset = 0; // milliseconds offset
  bool _initialized = false;
  final _controller = StreamController<int>.broadcast();

  /// Stream để lắng nghe thay đổi offset
  Stream<int> get offsetStream => _controller.stream;

  /// Đồng bộ thời gian với Firebase Server bằng cách so sánh với server timestamp
  Future<void> syncWithServer() async {
    try {
      // Ghi timestamp lên Firebase và lấy server timestamp
      final beforeLocal = DateTime.now().millisecondsSinceEpoch;

      final ref = FirebaseDatabase.instance.ref('time_sync_test');
      await ref.set(ServerValue.timestamp);

      final snapshot = await ref.get();
      final afterLocal = DateTime.now().millisecondsSinceEpoch;

      if (snapshot.exists && snapshot.value != null) {
        final serverTime = snapshot.value as int;

        // Tính latency và điều chỉnh
        final latency = (afterLocal - beforeLocal) ~/ 2;
        final adjustedServerTime = serverTime + latency;

        // Tính offset
        _serverOffset = adjustedServerTime - afterLocal;
        _initialized = true;
        _controller.add(_serverOffset);

        print(
          '🕐 Server time synced! Offset: ${_serverOffset}ms (Latency: ${latency}ms)',
        );
        print(
          '   Local time: ${DateTime.fromMillisecondsSinceEpoch(afterLocal)}',
        );
        print(
          '   Server time: ${DateTime.fromMillisecondsSinceEpoch(adjustedServerTime)}',
        );

        // Xóa test data
        await ref.remove();
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
      // Đồng bộ lại sau một khoảng thời gian
      await syncWithServer();
      return;
    }

    await syncWithServer();

    // Tự động đồng bộ lại mỗi 5 phút để giữ độ chính xác
    Timer.periodic(const Duration(minutes: 5), (timer) {
      syncWithServer();
    });
  }

  /// Kiểm tra xem đã khởi tạo chưa
  bool get isInitialized => _initialized;

  /// Lấy offset hiện tại (milliseconds)
  int get currentOffset => _serverOffset;

  void dispose() {
    _controller.close();
  }
}
