import 'dart:async';
import 'package:flutter/material.dart';
import 'game_theme.dart';

class GameBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GameBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                isSelected: currentIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.emoji_events_rounded,
                label: 'Bảng xếp hạng',
                isSelected: currentIndex == 1,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'Hồ sơ',
                isSelected: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? GameThemeData.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: GameThemeData.primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? GameThemeData.primaryColor
                  : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? GameThemeData.primaryColor
                    : Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Event/News Banner Card
class EventBannerCard extends StatefulWidget {
  const EventBannerCard({Key? key}) : super(key: key);

  @override
  State<EventBannerCard> createState() => _EventBannerCardState();
}

class _EventBannerCardState extends State<EventBannerCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<EventBanner> _banners = [
    EventBanner(
      title: 'Sự kiện mới: x2 XP cuối tuần!',
      description: 'Nhận gấp đôi điểm kinh nghiệm khi chơi game',
      icon: Icons.stars_rounded,
      color: GameThemeData.secondaryColor,
      actionText: 'Tìm hiểu thêm >>',
    ),
    EventBanner(
      title: 'Nhiệm vụ hàng ngày',
      description: 'Hoàn thành 3/5 nhiệm vụ hôm nay',
      icon: Icons.task_rounded,
      color: GameThemeData.accentColor,
      actionText: 'Xem chi tiết >>',
    ),
    EventBanner(
      title: 'Thử thách tuần',
      description: 'Thắng 10 ván để nhận phần thưởng đặc biệt',
      icon: Icons.military_tech_rounded,
      color: GameThemeData.primaryColor,
      actionText: 'Tham gia ngay >>',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto scroll banners
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          return _buildBannerCard(_banners[index]);
        },
      ),
    );
  }

  Widget _buildBannerCard(EventBanner banner) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            banner.color.withOpacity(0.15),
            banner.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: banner.color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: banner.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: banner.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(banner.icon, color: banner.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: GameThemeData.statusTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    banner.description,
                    style: GameThemeData.statusTextStyle.copyWith(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _handleBannerTap(banner),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: banner.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: banner.color.withOpacity(0.3)),
                ),
                child: Text(
                  banner.actionText,
                  style: TextStyle(
                    color: banner.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBannerTap(EventBanner banner) {
    
    print('Banner tapped: ${banner.title}');
    // You can add navigation logic here
  }
}

class EventBanner {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String actionText;

  EventBanner({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.actionText,
  });
}
