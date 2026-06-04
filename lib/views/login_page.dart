import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp1/main.dart';
import 'package:tp1/app_config.dart';
import 'package:tp1/views/inscription_page.dart';

const String tokenStorageKey = 'auth_token';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString(tokenStorageKey);
      _loading = false;
    });
  }

  Future<void> _onLoginSuccess(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenStorageKey, token);
    setState(() {
      _token = token;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenStorageKey);
    setState(() {
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_token == null) {
      return LoginPage(onLoginSuccess: _onLoginSuccess);
    }
    return AppShell(token: _token!, onLogout: _logout);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});

  final Future<void> Function(String token) onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  static const Color _softLilac = Color(0xFFDCC8F7);
  static const Color _lightPink = Color(0xFFF1BAFF);
  static const Color _buttonPurple = Color(0xFF8A2BE2);
  static const Color _shadowColor = Color(0x55000000);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password are required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.parse('$apiBaseUrl$apiLoginPath');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Login failed: HTTP ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      final token = _extractToken(decoded);
      if (token == null || token.isEmpty) {
        throw Exception('No token found in API response.');
      }

      await widget.onLoginSuccess(token);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _extractToken(dynamic json) {
    if (json is Map<String, dynamic>) {
      final direct = json['token'] ?? json['access_token'] ?? json['jwt'];
      if (direct is String) return direct;
      final nested = json['data'];
      if (nested is Map<String, dynamic>) {
        final nestedToken =
            nested['token'] ?? nested['access_token'] ?? nested['jwt'];
        if (nestedToken is String) return nestedToken;
      }
    }
    return null;
  }

  Future<void> _openInscriptionPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const InscriptionPage()));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required bool obscureText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: _softLilac,
        borderRadius: BorderRadius.circular(42),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 12, offset: Offset(0, 7)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: _buttonPurple),
            const SizedBox(width: 18),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: _buttonPurple,
                style: const TextStyle(
                  color: Color(0xFF9B9B9B),
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
                decoration:
                    const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ).copyWith(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Color(0xFF9B9B9B),
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF9B9B9B),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required double height,
    required double fontSize,
    required VoidCallback? onPressed,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    double radius = 38,
    double? width,
  }) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: backgroundColor,
          elevation: 6,
          shadowColor: _shadowColor,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onPressed,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final contentWidth = width.clamp(320.0, 420.0);
          final titleSize = width < 380 ? 42.0 : 50.0;
          final subtitleSize = width < 380 ? 24.0 : 28.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'src/img/fond_connexion.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'CONNEXION',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'VAS-Y BG',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFEBD8FF),
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'mail@mail.fr',
                              obscureText: false,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: '• • • • • • • • • • • •',
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            _buildRoundedButton(
                              text: _loading ? '...' : 'SE CONNECTER',
                              backgroundColor: Colors.white,
                              textColor: _buttonPurple,
                              height: 82,
                              width: double.infinity,
                              fontSize: width < 380 ? 24 : 28,
                              onPressed: _loading ? null : _login,
                              radius: 38,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 34),
                            _buildRoundedButton(
                              text: 'PAS DE COMPTE ?',
                              backgroundColor: _lightPink,
                              textColor: Colors.white,
                              height: 54,
                              width: width < 380 ? 220 : 250,
                              fontSize: width < 380 ? 15 : 18,
                              onPressed: _loading ? null : _openInscriptionPage,
                              radius: 27,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
