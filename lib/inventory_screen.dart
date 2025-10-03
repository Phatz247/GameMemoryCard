import 'package:flutter/material.dart';
import 'game_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start with "Tùy chỉnh" tab
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
    _tabController.dispose();
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
                _buildTabBar(),
                Expanded(child: _buildTabBarView()),
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
                  '🎒 Túi Đồ',
                  style: GameThemeData.titleTextStyle.copyWith(fontSize: 24),
                ),
                Text(
                  'Quản lý vật phẩm và tùy chỉnh',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [GameThemeData.primaryColor, GameThemeData.accentColor],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Vật phẩm'),
          Tab(text: 'Tùy chỉnh'),
          Tab(text: 'Mảnh ghép'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildItemsTab(),
        _buildCustomizationTab(),
        _buildFragmentsTab(),
      ],
    );
  }

  Widget _buildItemsTab() {
    final items = [
      InventoryItem(
        id: 'hint_x5',
        name: 'Gợi ý x5',
        description: '5 lượt sử dụng gợi ý',
        icon: Icons.lightbulb_rounded,
        quantity: 12,
        rarity: ItemRarity.common,
        color: Colors.yellow,
      ),
      InventoryItem(
        id: 'shuffle_x3',
        name: 'Xáo trộn x3',
        description: '3 lượt xáo trộn thẻ',
        icon: Icons.shuffle_rounded,
        quantity: 8,
        rarity: ItemRarity.common,
        color: Colors.purple,
      ),
      InventoryItem(
        id: 'freeze_x2',
        name: 'Đóng băng x2',
        description: '2 lượt đóng băng thời gian',
        icon: Icons.ac_unit_rounded,
        quantity: 3,
        rarity: ItemRarity.rare,
        color: Colors.blue,
      ),
      InventoryItem(
        id: 'double_xp',
        name: 'x2 XP (30p)',
        description: 'Gấp đôi XP trong 30 phút',
        icon: Icons.trending_up_rounded,
        quantity: 2,
        rarity: ItemRarity.epic,
        color: Colors.amber,
      ),
    ];

    return _buildItemGrid(items);
  }

  Widget _buildCustomizationTab() {
    final customizations = [
      InventoryItem(
        id: 'avatar_wolf',
        name: 'Avatar Sói',
        description: 'Avatar sói xanh huyền bí',
        icon: Icons.pets_rounded,
        quantity: 1,
        rarity: ItemRarity.rare,
        color: Colors.blue,
        isEquipped: true,
      ),
      InventoryItem(
        id: 'avatar_astronaut',
        name: 'Phi hành gia',
        description: 'Avatar phi hành gia không gian',
        icon: Icons.rocket_launch_rounded,
        quantity: 1,
        rarity: ItemRarity.epic,
        color: Colors.cyan,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'frame_silver',
        name: 'Khung Bạc',
        description: 'Khung avatar màu bạc',
        icon: Icons.crop_square_rounded,
        quantity: 1,
        rarity: ItemRarity.common,
        color: Colors.grey,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'frame_gold',
        name: 'Khung Vàng',
        description: 'Khung avatar màu vàng cao cấp',
        icon: Icons.crop_square_rounded,
        quantity: 1,
        rarity: ItemRarity.rare,
        color: Colors.amber,
        isEquipped: true,
      ),
      InventoryItem(
        id: 'effect_fire',
        name: 'Hiệu ứng Lửa',
        description: 'Hiệu ứng lửa cháy xung quanh',
        icon: Icons.local_fire_department_rounded,
        quantity: 1,
        rarity: ItemRarity.epic,
        color: Colors.red,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'theme_space',
        name: 'Chủ đề Không gian',
        description: 'Background galaxy và sao',
        icon: Icons.public_rounded,
        quantity: 1,
        rarity: ItemRarity.legendary,
        color: Colors.indigo,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'card_lightning',
        name: 'Chủ thẻ Không gian',
        description: 'Mặt sau thẻ với hiệu ứng sét',
        icon: Icons.flash_on_rounded,
        quantity: 1,
        rarity: ItemRarity.rare,
        color: Colors.blue,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'effect_set',
        name: 'Hiệu ứng Set',
        description: 'Hiệu ứng đặc biệt khi thắng',
        icon: Icons.auto_awesome_rounded,
        quantity: 1,
        rarity: ItemRarity.epic,
        color: Colors.cyan,
        isEquipped: false,
      ),
      InventoryItem(
        id: 'frame_dragon',
        name: 'Khung Rồng',
        description: 'Khung avatar hình rồng huyền thoại',
        icon: Icons.shield_rounded, // Thay thế dragon_rounded bằng shield_rounded
        quantity: 1,
        rarity: ItemRarity.legendary,
        color: Colors.red,
        isEquipped: false,
      ),
    ];

    return _buildItemGrid(customizations);
  }

  Widget _buildFragmentsTab() {
    final fragments = [
      InventoryItem(
        id: 'dragon_fragment',
        name: 'Mảnh Rồng',
        description: 'Mảnh ghép để tạo Avatar Rồng',
        icon: Icons.pentagon_rounded,
        quantity: 15,
        maxQuantity: 50,
        rarity: ItemRarity.legendary,
        color: Colors.red,
      ),
      InventoryItem(
        id: 'phoenix_fragment',
        name: 'Mảnh Phượng',
        description: 'Mảnh ghép để tạo Avatar Phượng Hoàng',
        icon: Icons.pentagon_rounded,
        quantity: 8,
        maxQuantity: 30,
        rarity: ItemRarity.epic,
        color: Colors.orange,
      ),
      InventoryItem(
        id: 'crystal_fragment',
        name: 'Mảnh Pha lê',
        description: 'Mảnh ghép để tạo Khung Pha lê',
        icon: Icons.pentagon_rounded,
        quantity: 23,
        maxQuantity: 25,
        rarity: ItemRarity.rare,
        color: Colors.purple,
      ),
    ];

    return _buildItemGrid(fragments);
  }

  Widget _buildItemGrid(List<InventoryItem> items) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildInventoryItemCard(items[index]),
      ),
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withOpacity(0.2),
              item.color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isEquipped == true
                ? GameThemeData.accentColor
                : item.color.withOpacity(0.4),
            width: item.isEquipped == true ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rarity indicator
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getRarityColor(item.rarity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getRarityColor(item.rarity).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 24,
                ),
              ),

              // Name
              Text(
                item.name,
                style: GameThemeData.statusTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Quantity or progress
              if (item.maxQuantity != null)
                Column(
                  children: [
                    Text(
                      '${item.quantity}/${item.maxQuantity}',
                      style: GameThemeData.statusTextStyle.copyWith(
                        fontSize: 10,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: item.quantity / item.maxQuantity!,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      borderRadius: BorderRadius.circular(2),
                      minHeight: 3,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.isEquipped == true)
                      Icon(
                        Icons.check_circle,
                        color: GameThemeData.accentColor,
                        size: 12,
                      )
                    else
                      Text(
                        'x${item.quantity}',
                        style: GameThemeData.statusTextStyle.copyWith(
                          fontSize: 10,
                          color: item.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.legendary:
        return Colors.orange;
    }
  }

  void _showItemDetails(InventoryItem item) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: GameThemeData.titleTextStyle.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: GameThemeData.statusTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Độ hiếm: ${_getRarityText(item.rarity)}',
                style: GameThemeData.statusTextStyle.copyWith(
                  color: _getRarityColor(item.rarity),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (item.isEquipped != null && !item.isEquipped!) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _equipItem(item);
                        },
                        style: GameThemeData.primaryButtonStyle,
                        child: const Text('Trang bị'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: GameThemeData.secondaryButtonStyle,
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRarityText(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return 'Thường';
      case ItemRarity.rare:
        return 'Hiếm';
      case ItemRarity.epic:
        return 'Sử thi';
      case ItemRarity.legendary:
        return 'Huyền thoại';
    }
  }

  void _equipItem(InventoryItem item) {
    setState(() {
      item.isEquipped = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã trang bị "${item.name}"!'),
        backgroundColor: GameThemeData.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

class InventoryItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int quantity;
  final int? maxQuantity;
  final ItemRarity rarity;
  final Color color;
  bool? isEquipped;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.quantity,
    this.maxQuantity,
    required this.rarity,
    required this.color,
    this.isEquipped,
  });
}
