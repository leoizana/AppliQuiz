import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:tp1/app_config.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  static const Color _softLilac = Color(0xFFE1C8F7);
  static const Color _lightPink = Color(0xFFF1BAFF);
  static const Color _buttonPurple = Color(0xFF8A2BE2);
  static const Color _accentPurple = Color(0xFF7A26DE);
  static const Color _shadowColor = Color(0x55000000);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstname = _firstNameController.text.trim();
    final lastname = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;

    if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty) {
      setState(() {
        _error = 'Tous les champs sont obligatoires.';
        _success = null;
      });
      return;
    }

    if (password != passwordConfirmation) {
      setState(() {
        _error = 'Les mots de passe ne correspondent pas.';
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final url = Uri.parse('$apiBaseUrl$apiRegisterPath');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'role': 'learner',
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Registration failed: HTTP ${response.statusCode}');
      }

      setState(() {
        _success = 'Compte créé. Vous pouvez maintenant vous connecter.';
      });

      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop();
      }
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
                  color: Color(0xFFF8F2FF),
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFFF8F2FF),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFF8F2FF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required double height,
    required double width,
    required double fontSize,
    required VoidCallback? onPressed,
    double radius = 38,
  }) {
    return SizedBox(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width.clamp(320.0, 420.0);
            final titleSize = width < 380 ? 40.0 : 46.0;
            final subtitleSize = width < 380 ? 22.0 : 26.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'src/img/fond_inscription.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
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
                              'INSCRIPTION',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _accentPurple,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'REJOINS-NOUS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _accentPurple,
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.7,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildInputField(
                              controller: _firstNameController,
                              icon: Icons.person_outline_rounded,
                              hintText: 'prénom',
                              obscureText: false,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              controller: _lastNameController,
                              icon: Icons.person_outline_rounded,
                              hintText: 'nom',
                              obscureText: false,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'mail@mail.fr',
                              obscureText: false,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: '• • • • • • • • • • • •',
                              obscureText: true,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              controller: _passwordConfirmationController,
                              icon: Icons.lock_outline_rounded,
                              hintText: '• • • • • • • • • • • •',
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            _buildButton(
                              text: _loading ? '...' : 'S’INSCRIRE',
                              backgroundColor: _buttonPurple,
                              textColor: Colors.white,
                              height: 82,
                              width: double.infinity,
                              fontSize: width < 380 ? 24 : 28,
                              onPressed: _loading ? null : _register,
                              radius: 38,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF5B1AB8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_success != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _success!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF5B1AB8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _buildButton(
                              text: 'DÉJÀ UN COMPTE ?',
                              backgroundColor: _lightPink,
                              textColor: Colors.white,
                              height: 54,
                              width: width < 380 ? 240 : 250,
                              fontSize: width < 380 ? 14 : 16,
                              onPressed: () => Navigator.of(context).pop(),
                              radius: 27,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
