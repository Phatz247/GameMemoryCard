import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //  Kiểm tra Firebase Auth có hoạt động không
  Future<bool> _isFirebaseAuthAvailable() async {
    try {
      await _auth.fetchSignInMethodsForEmail('test@test.com');
      return true;
    } catch (e) {
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        print('⚠️ Firebase Auth chưa được cấu hình!');
        return false;
      }
      return true; // Lỗi khác (network, etc.) vẫn coi là available
    }
  }

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 Signing up user: $email');

      // ⭐ Check Firebase Auth availability
      final isAvailable = await _isFirebaseAuthAvailable();
      if (!isAvailable) {
        return {
          'success': false,
          'message':
              'Firebase Authentication chưa được cấu hình.\n\nVui lòng:\n1. Vào Firebase Console\n2. Enable Authentication\n3. Enable Email/Password',
        };
      }

      // Tạo tài khoản Firebase
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      // Lưu thông tin vào SharedPreferences
      await _saveUserLocally(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
      );

      print('✅ Sign up successful: ${userCredential.user!.uid}');

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Đăng ký thành công!',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Sign up error: ${e.code}');

      String message = 'Đăng ký thất bại';
      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
          break;
        case 'email-already-in-use':
          message = 'Email này đã được đăng ký';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'configuration-not-found':
          message =
              'Firebase chưa được cấu hình.\nVui lòng enable Authentication trên Firebase Console';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Signing in user: $email');

      // ⭐ Check Firebase Auth availability
      final isAvailable = await _isFirebaseAuthAvailable();
      if (!isAvailable) {
        return {
          'success': false,
          'message':
              'Firebase Authentication chưa được cấu hình.\n\nVui lòng:\n1. Vào Firebase Console\n2. Enable Authentication\n3. Enable Email/Password',
        };
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Lưu thông tin vào SharedPreferences
      await _saveUserLocally(
        uid: userCredential.user!.uid,
        email: email,
        displayName: userCredential.user?.displayName ?? email.split('@')[0],
      );

      print('✅ Sign in successful: ${userCredential.user!.uid}');

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Đăng nhập thành công!',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.code}');

      String message = 'Đăng nhập thất bại';
      switch (e.code) {
        case 'user-not-found':
          message = 'Email chưa được đăng ký';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'invalid-credential':
          message = 'Email hoặc mật khẩu không đúng';
          break;
        case 'configuration-not-found':
          message =
              'Firebase chưa được cấu hình.\nVui lòng enable Authentication trên Firebase Console';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }

  // Đăng nhập ẩn danh (cho guest)
  Future<Map<String, dynamic>> signInAnonymously() async {
    try {
      print('👤 Signing in anonymously...');

      // ⭐ Check Firebase Auth availability
      final isAvailable = await _isFirebaseAuthAvailable();
      if (!isAvailable) {
        // Fallback: Tạo guest user local
        final guestName =
            'Guest${DateTime.now().millisecondsSinceEpoch % 10000}';
        await _saveUserLocally(
          uid: 'local_guest_${DateTime.now().millisecondsSinceEpoch}',
          email: '',
          displayName: guestName,
          isGuest: true,
        );

        return {
          'success': true,
          'user': null,
          'displayName': guestName,
          'message': 'Chơi với tư cách khách (offline)',
        };
      }

      final UserCredential userCredential = await _auth.signInAnonymously();

      final displayName =
          'Guest${DateTime.now().millisecondsSinceEpoch % 10000}';

      // Lưu thông tin guest
      await _saveUserLocally(
        uid: userCredential.user!.uid,
        email: '',
        displayName: displayName,
        isGuest: true,
      );

      print('✅ Anonymous sign in successful: ${userCredential.user!.uid}');

      return {
        'success': true,
        'user': userCredential.user,
        'displayName': displayName,
        'message': 'Đăng nhập với tư cách khách',
      };
    } catch (e) {
      print('❌ Anonymous sign in error: $e');

      // Fallback: Tạo guest user local
      final guestName = 'Guest${DateTime.now().millisecondsSinceEpoch % 10000}';
      await _saveUserLocally(
        uid: 'local_guest_${DateTime.now().millisecondsSinceEpoch}',
        email: '',
        displayName: guestName,
        isGuest: true,
      );

      return {
        'success': true,
        'displayName': guestName,
        'message': 'Chơi với tư cách khách (offline)',
      };
    }
  }

  Future<void> signOut() async {
    try {
      print('👋 Signing out...');

      await _auth.signOut();

      // Xóa thông tin local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
      await prefs.remove('is_guest');

      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  Future<void> _saveUserLocally({
    required String uid,
    required String email,
    required String displayName,
    bool isGuest = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final userData = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isGuest': isGuest,
      'lastLogin': DateTime.now().millisecondsSinceEpoch,
    };

    await prefs.setString('current_user', json.encode(userData));
    await prefs.setString('user_email', email);
    await prefs.setString('user_display_name', displayName);
    await prefs.setBool('is_guest', isGuest);

    print('💾 User data saved locally: $displayName');
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('current_user');

      if (userString == null) return null;

      final userData = json.decode(userString) as Map<String, dynamic>;
      print('📖 Retrieved saved user: ${userData['displayName']}');

      return userData;
    } catch (e) {
      print('❌ Error retrieving saved user: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    // Kiểm tra Firebase Auth
    if (_auth.currentUser != null) {
      return true;
    }
    final savedUser = await getSavedUser();
    return savedUser != null;
  }

  Future<String> getDisplayName() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.displayName ??
          _auth.currentUser!.email?.split('@')[0] ??
          'Player';
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_display_name') ?? 'Player';
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return {'success': true, 'message': 'Email đặt lại mật khẩu đã được gửi'};
    } on FirebaseAuthException catch (e) {
      String message = 'Không thể gửi email';

      switch (e.code) {
        case 'user-not-found':
          message = 'Email chưa được đăng ký';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
      }

      return {'success': false, 'message': message};
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload();

      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('current_user');

      if (userString != null) {
        final userData = json.decode(userString) as Map<String, dynamic>;
        userData['displayName'] = newName;
        await prefs.setString('current_user', json.encode(userData));
        await prefs.setString('user_display_name', newName);
      }

      return true;
    } catch (e) {
      print('❌ Error updating display name: $e');
      return false;
    }
  }

  // Kiểm tra có tài khoản đã lưu không và tự động đăng nhập
  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔄 Changing password...');

      // Kiểm tra người dùng đã đăng nhập chưa
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập để đổi mật khẩu',
        };
      }

      // Kiểm tra email có tồn tại không (trường hợp đăng nhập ẩn danh)
      final email = user.email;
      if (email == null || email.isEmpty) {
        return {
          'success': false,
          'message': 'Tài khoản không có email. Không thể đổi mật khẩu.',
        };
      }

      // Tạo credential để xác thực lại người dùng với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      try {
        // Xác thực lại người dùng
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Xử lý lỗi khi xác thực
        String message = 'Xác thực thất bại';
        switch (e.code) {
          case 'wrong-password':
            message = 'Mật khẩu hiện tại không chính xác';
            break;
          case 'too-many-requests':
            message = 'Quá nhiều lần thử. Vui lòng thử lại sau.';
            break;
          case 'user-not-found':
            message = 'Tài khoản không tồn tại';
            break;
          default:
            message = 'Lỗi xác thực: ${e.message}';
        }
        return {'success': false, 'message': message};
      }

      // Đổi mật khẩu
      try {
        await user.updatePassword(newPassword);
        print('✅ Password changed successfully');
        return {'success': true, 'message': 'Đổi mật khẩu thành công'};
      } on FirebaseAuthException catch (e) {
        // Xử lý lỗi khi đổi mật khẩu
        String message = 'Không thể đổi mật khẩu';
        switch (e.code) {
          case 'weak-password':
            message = 'Mật khẩu mới quá yếu (tối thiểu 6 ký tự)';
            break;
          case 'requires-recent-login':
            message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
            break;
          default:
            message = 'Lỗi: ${e.message}';
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('❌ Unexpected error changing password: $e');
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }

  // Lưu thông tin đăng nhập tài khoản để sử dụng trên nhiều thiết bị
  Future<bool> saveAccountCredentials({
    required String email,
    required String password,
    required String displayName,
    required String uid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy danh sách tài khoản đã lưu
      final savedAccountsString = prefs.getString('saved_accounts') ?? '[]';
      final List<dynamic> savedAccounts =
          json.decode(savedAccountsString) as List;

      // Kiểm tra tài khoản đã tồn tại chưa, nếu có thì cập nhật
      final existingIndex = savedAccounts.indexWhere(
        (acc) => acc['email'] == email,
      );

      final accountData = {
        'email': email,
        'password': _encodePassword(password), // Mã hóa đơn giản
        'displayName': displayName,
        'uid': uid,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
      };

      if (existingIndex >= 0) {
        // Cập nhật tài khoản hiện có
        savedAccounts[existingIndex] = accountData;
      } else {
        // Thêm tài khoản mới
        savedAccounts.add(accountData);
      }

      await prefs.setString('saved_accounts', json.encode(savedAccounts));
      print('💾 Account credentials saved: $email');
      return true;
    } catch (e) {
      print('❌ Error saving account credentials: $e');
      return false;
    }
  }

  // Tải danh sách tất cả tài khoản đã lưu
  Future<List<Map<String, dynamic>>> loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsString = prefs.getString('saved_accounts') ?? '[]';
      final List<dynamic> savedAccounts =
          json.decode(savedAccountsString) as List;

      return savedAccounts.map((acc) {
        return Map<String, dynamic>.from(acc as Map);
      }).toList();
    } catch (e) {
      print('❌ Error loading saved accounts: $e');
      return [];
    }
  }

  // Xóa một tài khoản đã lưu
  Future<bool> removeSavedAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsString = prefs.getString('saved_accounts') ?? '[]';
      final List<dynamic> savedAccounts =
          json.decode(savedAccountsString) as List;

      savedAccounts.removeWhere((acc) => acc['email'] == email);

      await prefs.setString('saved_accounts', json.encode(savedAccounts));
      print('🗑️ Account removed: $email');
      return true;
    } catch (e) {
      print('❌ Error removing account: $e');
      return false;
    }
  }

  // Đăng nhập từ tài khoản đã lưu
  Future<Map<String, dynamic>> autoLoginFromSaved({
    required String email,
    required String savedPassword,
  }) async {
    try {
      // Giải mã mật khẩu
      final decodedPassword = _decodePassword(savedPassword);

      // Đăng nhập bằng Firebase
      final result = await signIn(email: email, password: decodedPassword);

      if (result['success']) {
        // Cập nhật thời gian sử dụng cuối cùng
        final prefs = await SharedPreferences.getInstance();
        final savedAccountsString = prefs.getString('saved_accounts') ?? '[]';
        final List<dynamic> savedAccounts =
            json.decode(savedAccountsString) as List;

        final accountIndex = savedAccounts.indexWhere(
          (acc) => acc['email'] == email,
        );

        if (accountIndex >= 0) {
          savedAccounts[accountIndex]['lastUsed'] =
              DateTime.now().millisecondsSinceEpoch;
          await prefs.setString('saved_accounts', json.encode(savedAccounts));
        }
      }

      return result;
    } catch (e) {
      print('❌ Error auto-login from saved account: $e');
      return {'success': false, 'message': 'Lỗi đăng nhập tự động: $e'};
    }
  }

  // Hàm mã hóa mật khẩu đơn giản (Base64)
  String _encodePassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  // Hàm giải mã mật khẩu đơn giản (Base64)
  String _decodePassword(String encodedPassword) {
    try {
      return utf8.decode(base64Decode(encodedPassword));
    } catch (e) {
      print('❌ Error decoding password: $e');
      return '';
    }
  }

  // Kiểm tra xem có tài khoản đã lưu không
  Future<bool> hasSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccountsString = prefs.getString('saved_accounts') ?? '[]';
      final List<dynamic> savedAccounts =
          json.decode(savedAccountsString) as List;
      return savedAccounts.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
