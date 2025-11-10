import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

///quản lý nhạc nền và âm thanh hiệu ứng cho game
class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  /// Khởi tạo service và tải cài đặt
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;

      // Cấu hình các AudioPlayer
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _sfxPlayer.setVolume(_sfxVolume);

      print('✅ AudioService initialized successfully');
      print(
        '🎵 Music: ${_musicEnabled ? "ON" : "OFF"} (Volume: ${(_musicVolume * 100).toInt()}%)',
      );
      print(
        '🔊 SFX: ${_sfxEnabled ? "ON" : "OFF"} (Volume: ${(_sfxVolume * 100).toInt()}%)',
      );
    } catch (e) {
      print('⚠️ Lỗi khởi tạo AudioService: $e');
    }
  }

  /// Phát nhạc nền
  Future<void> playBackgroundMusic(String fileName) async {
    if (!_musicEnabled) return;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(fileName));
    } catch (e) {
      print('⚠️ Cảnh báo: Không thể phát nhạc nền "$fileName"');
      print('💡 Hãy thêm file MP3 vào thư mục assets/ để nghe nhạc');
      print('❌ Chi tiết lỗi: $e');
    }
  }

  /// Dừng nhạc nền
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  /// Tạm dừng nhạc nền
  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  /// Tiếp tục nhạc nền
  Future<void> resumeBackgroundMusic() async {
    if (_musicEnabled) {
      await _musicPlayer.resume();
    }
  }

  /// Phát âm thanh hiệu ứng (SFX)
  Future<void> playSoundEffect(String fileName) async {
    if (!_sfxEnabled) return;

    try {
      await _sfxPlayer.play(AssetSource(fileName));
    } catch (e) {
      print('⚠️ Cảnh báo: Không thể phát hiệu ứng âm thanh "$fileName"');
      print('💡 Hãy thêm file MP3 vào thư mục assets/ để nghe âm thanh');
      print('❌ Chi tiết lỗi: $e');
    }
  }

  /// Bật/Tắt nhạc nền
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);

    if (enabled) {
      await resumeBackgroundMusic();
      print('🎵 Bật nhạc nền');
    } else {
      await pauseBackgroundMusic();
      print('🎵 Tắt nhạc nền');
    }
  }

  /// Bật/Tắt âm thanh hiệu ứng
  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', enabled);

    if (enabled) {
      print('🔊 Bật âm thanh hiệu ứng');
    } else {
      print('🔊 Tắt âm thanh hiệu ứng');
    }
  }

  /// Thiết lập âm lượng nhạc nền (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
  }

  /// Thiết lập âm lượng hiệu ứng âm thanh (0.0 - 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
  }

  /// Lấy trạng thái nhạc nền
  bool get isMusicEnabled => _musicEnabled;

  /// Lấy trạng thái âm thanh hiệu ứng
  bool get isSfxEnabled => _sfxEnabled;

  /// Lấy âm lượng nhạc nền
  double get musicVolume => _musicVolume;

  /// Lấy âm lượng hiệu ứng âm thanh
  double get sfxVolume => _sfxVolume;

  /// Dọn dẹp tài nguyên
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
