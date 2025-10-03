import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_theme.dart';
import 'bottom_navigation.dart';
import 'shared_preferences_helper.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBalance = 1250; // Default value, will be updated from SharedPreferences
  int _selectedTabIndex = 0;

  final List<String> _tabs = [
    'Vật phẩm',
    'Tùy chỉnh',
    'Gói đặc biệt',
  ];

  final List<ShopItem> _items = [
    ShopItem(
      name: 'Gợi ý',
      description: 'Gợi ý một cặp thẻ phù hợp',
      price: 500,
      icon: Icons.lightbulb,
      color: Colors.amber,
    ),
    ShopItem(
      name: 'Đóng băng TG',
      description: 'Tạm dừng thời gian trong 10 giây',
      price: 750,
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
    ),
    ShopItem(
      name: 'Thêm TG x2',
      description: 'Thêm thời gian chơi',
      price: 750,
      icon: Icons.timer,
      color: Colors.purple,
    ),
    ShopItem(
      name: 'Xáo trộn x5',
      description: 'Xáo trộn vị trí các thẻ',
      price: 600,
      icon: Icons.shuffle,
      color: Colors.green,
    ),
    ShopItem(
      name: 'Nhân đôi XP',
      description: 'Nhân đôi điểm kinh nghiệm',
      price: 1000,
      icon: Icons.star,
      color: Colors.amber,
    ),
    ShopItem(
      name: 'Bảo vệ Streak',
      description: 'Bảo vệ chuỗi thắng khi thua',
      price: 800,
      icon: Icons.shield,
      color: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await SharedPreferencesHelper.getBalance();
    setState(() {
      _currentBalance = balance;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePurchase(ShopItem item) {
    if (_currentBalance >= item.price) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: GameThemeData.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xác nhận mua',
            style: GameThemeData.titleTextStyle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có muốn mua "${item.name}" với giá ${item.price} vàng?',
                style: GameThemeData.bodyTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Số dư hiện tại: $_currentBalance vàng',
                style: GameThemeData.bodyTextStyle.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: GameThemeData.bodyTextStyle.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: GameThemeData.primaryButtonStyle,
              onPressed: () {
                setState(() {
                  _currentBalance -= item.price;
                });
                SharedPreferencesHelper.setBalance(_currentBalance);
                Navigator.pop(context);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã mua thành công ${item.name}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Text('Mua'),
            ),
          ],
        ),
      );
    } else {
      // Show insufficient funds message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không đủ vàng để mua vật phẩm này!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameThemeData.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Shop title and balance
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();  // This will pop back to previous screen
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cửa Hàng',
                      style: GameThemeData.titleTextStyle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_currentBalance',
                            style: GameThemeData.bodyTextStyle.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: GameThemeData.primaryColor.withOpacity(0.3),
                  ),
                  labelColor: GameThemeData.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: _tabs
                      .map((tab) => Tab(
                            text: tab,
                            height: 48,
                          ))
                      .toList(),
                ),
              ),

              // Shop items grid
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Items tab
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ShopItemCard(
                          item: item,
                          onTap: () => _handlePurchase(item),
                        );
                      },
                    ),
                    // Customization tab (placeholder)
                    const Center(child: Text('Tùy chỉnh - Đang phát triển')),
                    // Special packs tab (placeholder)
                    const Center(child: Text('Gói đặc biệt - Đang phát triển')),
                  ],
                ),
              ),

              // Bottom navigation
              GameBottomNavigation(
                currentIndex: 2,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/menu');
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(context, '/leaderboard');
                      break;
                    case 2:
                      // Already in shop
                      break;
                    case 3:
                      Navigator.pushReplacementNamed(context, '/profile');
                      break;
                    case 4:
                      Navigator.pushReplacementNamed(context, '/inventory');
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopItem {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  ShopItem({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}

class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onTap;

  const ShopItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GameThemeData.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 40,
                color: item.color,
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              item.name,
              style: GameThemeData.bodyTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.description,
                style: GameThemeData.bodyTextStyle.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price}',
                    style: GameThemeData.bodyTextStyle.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
