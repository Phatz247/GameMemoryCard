import 'package:flutter/material.dart';
import 'game_theme.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<GameEvent> _events = [
    GameEvent(
      id: 1,
      title: 'Sự kiện x2 XP cuối tuần!',
      description: 'Nhận gấp đôi điểm kinh nghiệm khi chơi game vào cuối tuần. Áp dụng cho tất cả các chế độ game.',
      icon: Icons.stars_rounded,
      color: GameThemeData.secondaryColor,
      startDate: DateTime(2025, 10, 4),
      endDate: DateTime(2025, 10, 6),
      isActive: true,
      rewards: ['2x XP', '100 Gold'],
    ),
    GameEvent(
      id: 2,
      title: 'Nhiệm vụ hàng ngày',
      description: 'Hoàn thành các nhiệm vụ hàng ngày để nhận phần thưởng hấp dẫn. Nhiệm vụ reset mỗi ngày lúc 0h.',
      icon: Icons.task_rounded,
      color: GameThemeData.accentColor,
      startDate: DateTime(2025, 10, 1),
      endDate: DateTime(2025, 10, 31),
      isActive: true,
      progress: 0.6,
      maxProgress: 5,
      currentProgress: 3,
      rewards: ['50 Gold', 'Power-up Card'],
    ),
    GameEvent(
      id: 3,
      title: 'Thử thách tuần',
      description: 'Thắng 10 ván trong tuần này để nhận phần thưởng đặc biệt. Thử thách reset mỗi thứ 2.',
      icon: Icons.military_tech_rounded,
      color: GameThemeData.primaryColor,
      startDate: DateTime(2025, 9, 30),
      endDate: DateTime(2025, 10, 7),
      isActive: true,
      progress: 0.4,
      maxProgress: 10,
      currentProgress: 4,
      rewards: ['Exclusive Avatar', '200 Gold', 'Special Badge'],
    ),
    GameEvent(
      id: 4,
      title: 'Halloween Challenge 2025',
      description: 'Sự kiện đặc biệt Halloween với theme cards ma quái và phần thưởng giới hạn.',
      icon: Icons.celebration_rounded,
      color: Colors.orange,
      startDate: DateTime(2025, 10, 25),
      endDate: DateTime(2025, 11, 2),
      isActive: false,
      rewards: ['Halloween Avatar', 'Spooky Card Back', '500 Gold'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameThemeData.darkGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(_events[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎪 Sự kiện & Thử thách',
                  style: GameThemeData.titleTextStyle.copyWith(fontSize: 24),
                ),
                Text(
                  'Tham gia để nhận phần thưởng hấp dẫn',
                  style: GameThemeData.statusTextStyle.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(GameEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            event.color.withOpacity(0.15),
            event.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: event.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventHeader(event),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: GameThemeData.statusTextStyle.copyWith(
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildEventProgress(event),
            const SizedBox(height: 16),
            _buildEventRewards(event),
            const SizedBox(height: 16),
            _buildEventActions(event),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader(GameEvent event) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            event.icon,
            color: event.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: GameThemeData.statusTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isActive ? GameThemeData.accentColor : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.isActive ? 'Đang diễn ra' : 'Sắp diễn ra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatEventDate(event),
                style: GameThemeData.statusTextStyle.copyWith(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventProgress(GameEvent event) {
    if (event.progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ',
              style: GameThemeData.statusTextStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${event.currentProgress}/${event.maxProgress}',
              style: GameThemeData.statusTextStyle.copyWith(
                color: event.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: event.progress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(event.color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildEventRewards(GameEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phần thưởng',
          style: GameThemeData.statusTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: event.rewards.map((reward) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: event.color.withOpacity(0.3),
                ),
              ),
              child: Text(
                reward,
                style: TextStyle(
                  color: event.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventActions(GameEvent event) {
    return Row(
      children: [
        if (event.isActive) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _participateInEvent(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: event.color,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tham gia ngay'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sắp diễn ra',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => _showEventDetails(event),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: event.color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Chi tiết',
            style: TextStyle(color: event.color),
          ),
        ),
      ],
    );
  }

  String _formatEventDate(GameEvent event) {
    final now = DateTime.now();
    if (event.isActive) {
      final remaining = event.endDate.difference(now).inDays;
      return 'Còn $remaining ngày';
    } else {
      final daysUntilStart = event.startDate.difference(now).inDays;
      return 'Bắt đầu sau $daysUntilStart ngày';
    }
  }

  void _participateInEvent(GameEvent event) {
    // Navigate back to game or show participation dialog
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tham gia sự kiện: ${event.title}'),
        backgroundColor: event.color,
      ),
    );
  }

  void _showEventDetails(GameEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: GameThemeData.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                event.icon,
                color: event.color,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                event.title,
                style: GameThemeData.titleTextStyle.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                style: GameThemeData.statusTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: GameThemeData.primaryButtonStyle,
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameEvent {
  final int id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double? progress;
  final int? maxProgress;
  final int? currentProgress;
  final List<String> rewards;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.progress,
    this.maxProgress,
    this.currentProgress,
    required this.rewards,
  });
}
