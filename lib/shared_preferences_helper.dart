import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _balanceKey = 'user_balance';
  static const String _currentUserKey = 'current_user';

  // Get user balance
  static Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_currentUserKey) ?? 'Unknown';
    return prefs.getInt('${_balanceKey}_$username') ?? 1250; // Default starting balance
  }

  // Set user balance
  static Future<void> setBalance(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_currentUserKey) ?? 'Unknown';
    await prefs.setInt('${_balanceKey}_$username', amount);
  }

  // Add to balance
  static Future<void> addToBalance(int amount) async {
    final currentBalance = await getBalance();
    await setBalance(currentBalance + amount);
  }

  // Subtract from balance
  static Future<void> subtractFromBalance(int amount) async {
    final currentBalance = await getBalance();
    await setBalance(currentBalance - amount);
  }

  // Check if user can afford purchase
  static Future<bool> canAffordPurchase(int cost) async {
    final currentBalance = await getBalance();
    return currentBalance >= cost;
  }
}
