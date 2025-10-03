import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'menu_screen.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'inventory_screen.dart';
import 'leaderboard_screen.dart';
import 'game_modes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Card Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.amber,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/game') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => GameScreen(
              config: args['config'] as GameConfig,
            ),
          );
        } else if (settings.name == '/leaderboard') {
          final args = settings.arguments as Map<String, dynamic>? ?? {
            'gameMode': GameMode.classic,
            'level': 1,
            'currentPlayer': 'Guest'
          };
          return MaterialPageRoute(
            builder: (context) => LeaderboardScreen(
              gameMode: args['gameMode'] as GameMode,
              level: args['level'] as int,
              currentPlayer: args['currentPlayer'] as String,
            ),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const AuthScreen(),
        '/menu': (context) => const MenuScreen(),
        '/shop': (context) => const ShopScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/inventory': (context) => const InventoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
