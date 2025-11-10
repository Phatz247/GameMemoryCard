import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_screen.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _isLogin = true;
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF1a1a2e),
      end: const Color(0xFF16213e),
    ).animate(_backgroundController);

    _checkLoggedIn();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _checkLoggedIn() async {
    final savedUser = await _authService.getSavedUser();

    if (savedUser != null && mounted) {
      // Allow both regular users and guest users to proceed
      if (savedUser['isGuest'] == true || _authService.currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
        return;
      }
    }

    setState(() {
      _loading = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    _colorAnimation.value ?? const Color(0xFF1a1a2e),
                    const Color(0xFF0f0f23),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: _rotateAnimation.value * 2 * 3.14159,
                      child: const Icon(
                        Icons.extension,
                        size: 60,
                        color: Color(0xFF64ffda),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      color: Color(0xFF64ffda),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _animationController,
          _backgroundController,
        ]),
        builder: (context, child) {
          return Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5 + _rotateAnimation.value * 0.3, -0.8),
                radius: 1.5,
                colors: [
                  _colorAnimation.value != null
                      ? _colorAnimation.value!.withAlpha(204)
                      : const Color(0xFF1a1a2e).withAlpha(204),
                  const Color(0xFF16213e),
                  const Color(0xFF0f0f23),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -1),
                                      end: Offset.zero,
                                    ).animate(_slideAnimation),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF64ffda),
                                                Color(0xFF1de9b6),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF64ffda,
                                                ).withAlpha(128),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Transform.rotate(
                                            angle: _rotateAnimation.value * 0.5,
                                            child: const Icon(
                                              Icons.extension,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFF64ffda),
                                                ],
                                              ).createShader(bounds),
                                          child: Text(
                                            'Memory Game',
                                            style: GoogleFonts.poppins(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color: Colors.white.withAlpha(26),
                                            border: Border.all(
                                              color: Colors.white.withAlpha(51),
                                            ),
                                          ),
                                          child: Text(
                                            '🧠 Thử thách trí nhớ của bạn',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 1),
                                    end: Offset.zero,
                                  ).animate(_slideAnimation),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF1a1a2e).withAlpha(77),
                                          const Color(0xFF16213e).withAlpha(51),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(26),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(102),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  color: Colors.black.withAlpha(
                                                    77,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () => setState(
                                                          () => _isLogin = true,
                                                        ),
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            gradient: _isLogin
                                                                ? const LinearGradient(
                                                                    colors: [
                                                                      Color(
                                                                        0xFF64ffda,
                                                                      ),
                                                                      Color(
                                                                        0xFF1de9b6,
                                                                      ),
                                                                    ],
                                                                  )
                                                                : null,
                                                            boxShadow: _isLogin
                                                                ? [
                                                                    BoxShadow(
                                                                      color: const Color(
                                                                        0xFF64ffda,
                                                                      ).withAlpha(77),
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            2,
                                                                          ),
                                                                    ),
                                                                  ]
                                                                : null,
                                                          ),
                                                          child: Text(
                                                            'Đăng Nhập',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: _isLogin
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .white70,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () => setState(
                                                          () =>
                                                              _isLogin = false,
                                                        ),
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            gradient: !_isLogin
                                                                ? const LinearGradient(
                                                                    colors: [
                                                                      Color(
                                                                        0xFF64ffda,
                                                                      ),
                                                                      Color(
                                                                        0xFF1de9b6,
                                                                      ),
                                                                    ],
                                                                  )
                                                                : null,
                                                            boxShadow: !_isLogin
                                                                ? [
                                                                    BoxShadow(
                                                                      color: const Color(
                                                                        0xFF64ffda,
                                                                      ).withAlpha(77),
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            2,
                                                                          ),
                                                                    ),
                                                                  ]
                                                                : null,
                                                          ),
                                                          child: Text(
                                                            'Đăng Ký',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: !_isLogin
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .white70,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                transitionBuilder:
                                                    (child, animation) {
                                                      return SlideTransition(
                                                        position: Tween<Offset>(
                                                          begin: const Offset(
                                                            0.3,
                                                            0,
                                                          ),
                                                          end: Offset.zero,
                                                        ).animate(animation),
                                                        child: FadeTransition(
                                                          opacity: animation,
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                child: _isLogin
                                                    ? LoginForm(
                                                        key: const ValueKey(
                                                          'login',
                                                        ),
                                                        authService:
                                                            _authService,
                                                        onSuccess:
                                                            _onAuthSuccess,
                                                      )
                                                    : RegisterForm(
                                                        key: const ValueKey(
                                                          'register',
                                                        ),
                                                        authService:
                                                            _authService,
                                                        onSuccess:
                                                            _onAuthSuccess,
                                                      ),
                                              ),

                                              const SizedBox(height: 20),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  final result =
                                                      await _authService
                                                          .signInAnonymously();
                                                  if (result['success'] &&
                                                      mounted) {
                                                    _onAuthSuccess(
                                                      result['displayName'],
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.person_outline,
                                                  color: Colors.white60,
                                                ),
                                                label: Text(
                                                  'Chơi với tư cách khách',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _onAuthSuccess(String username) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final AuthService authService;
  final void Function(String username) onSuccess;

  const LoginForm({
    required this.authService,
    required this.onSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _obscurePassword = true;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shakeForm() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      if (result['success']) {
        final displayName = await widget.authService.getDisplayName();
        final uid = widget.authService.currentUser?.uid ?? '';

        // Hiển thị dialog để hỏi có muốn lưu thông tin tài khoản không
        if (mounted) {
          _showSaveAccountDialog(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: displayName,
            uid: uid,
            onSaved: () {
              widget.onSuccess(displayName);
            },
          );
        }
      } else {
        setState(() {
          _error = result['message'];
          _submitting = false;
        });
        _shakeForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã có lỗi xảy ra: $e';
        _submitting = false;
      });
      _shakeForm();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a1a2e).withOpacity(0.2),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        enabled: !_submitting,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: hasToggle
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF64ffda), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10 * _shakeController.value * (1 - _shakeController.value),
            0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passCtrl,
                  label: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  hasToggle: true,
                  onToggle: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Vui lòng nhập mật khẩu'
                      : null,
                  onSubmitted: _submit,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64ffda), Color(0xFF1de9b6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64ffda).withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _submitting ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _submitting
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Text(
                                'Đăng Nhập',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveAccountDialog({
    required String email,
    required String password,
    required String displayName,
    required String uid,
    required VoidCallback onSaved,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: Text(
            'Lưu tài khoản',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Bạn có muốn lưu thông tin tài khoản này để có thể đăng nhập nhanh trên các thiết bị khác không?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onSaved();
              },
              child: Text(
                'Không',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Lưu thông tin tài khoản
                await widget.authService.saveAccountCredentials(
                  email: email,
                  password: password,
                  displayName: displayName,
                  uid: uid,
                );
                onSaved();
              },
              child: Text(
                'Có',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64ffda),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class RegisterForm extends StatefulWidget {
  final AuthService authService;
  final void Function(String username) onSuccess;

  const RegisterForm({
    required this.authService,
    required this.onSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shakeForm() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() {
        _error = 'Mật khẩu xác nhận không khớp';
      });
      _shakeForm();
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.authService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        final displayName = _nameCtrl.text.trim();
        final uid = widget.authService.currentUser?.uid ?? '';

        // Hiển thị dialog để hỏi có muốn lưu thông tin tài khoản không
        if (mounted) {
          _showSaveAccountDialog(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: displayName,
            uid: uid,
            onSaved: () {
              widget.onSuccess(displayName);
            },
          );
        }
      } else {
        setState(() {
          _error = result['message'];
          _submitting = false;
        });
        _shakeForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã có lỗi xảy ra: $e';
        _submitting = false;
      });
      _shakeForm();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
    TextInputAction? textInputAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a1a2e).withOpacity(0.2),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        enabled: !_submitting,
        textInputAction: textInputAction,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: hasToggle
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF64ffda), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10 * _shakeController.value * (1 - _shakeController.value),
            0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Tên hiển thị',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập tên'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passCtrl,
                  label: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  hasToggle: true,
                  onToggle: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPassCtrl,
                  label: 'Xác nhận mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  hasToggle: true,
                  onToggle: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Vui lòng xác nhận mật khẩu'
                      : null,
                  textInputAction: TextInputAction.done,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64ffda), Color(0xFF1de9b6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64ffda).withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _submitting ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _submitting
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Text(
                                'Đăng Ký',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveAccountDialog({
    required String email,
    required String password,
    required String displayName,
    required String uid,
    required VoidCallback onSaved,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: Text(
            'Lưu tài khoản',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Bạn có muốn lưu thông tin tài khoản này để có thể đăng nhập nhanh trên các thiết bị khác không?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onSaved();
              },
              child: Text(
                'Không',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Lưu thông tin tài khoản
                await widget.authService.saveAccountCredentials(
                  email: email,
                  password: password,
                  displayName: displayName,
                  uid: uid,
                );
                onSaved();
              },
              child: Text(
                'Có',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64ffda),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
