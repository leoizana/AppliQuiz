import 'package:flutter/material.dart';
import 'package:tp1/views/login_page.dart';
import 'package:tp1/views/leaderboard_page.dart';
import 'package:tp1/views/quiz_page.dart';
import 'package:tp1/widgets/navbar.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.token, required this.onLogout});

  final String token;
  final Future<void> Function() onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LeaderboardPage(token: widget.token, onLogout: widget.onLogout),
      const QuizPage(),
      const _PlaceholderPage(label: 'Scores'),
      const _PlaceholderPage(label: 'Profil'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppNavBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

// Page temporaire pour les onglets pas encore créés
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DBFF),
      body: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7E2DE1),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
