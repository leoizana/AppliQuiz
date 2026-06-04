import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _navPurple = Color(0xFF8D2AE5);
  static const Color _navSelected = Color(0xFFF7F0FF);
  static const Color _shadow = Color(0x33000000);

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, asset: 'src/img/home.png'),
    _NavItem(icon: Icons.menu_book_rounded, asset: 'src/img/quizz.png'),
    _NavItem(icon: Icons.attach_money_rounded, asset: 'src/img/money.png'),
    _NavItem(icon: Icons.person_outline_rounded, asset: 'src/img/user.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: _navPurple,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (i) {
              final sel = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: sel ? 52 : 42,
                      height: sel ? 52 : 42,
                      decoration: BoxDecoration(
                        color: sel ? _navSelected : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          _items[i].asset,
                          fit: BoxFit.contain,
                          color: sel ? _navPurple : Colors.white,
                          errorBuilder: (_, __, ___) => Icon(
                            _items[i].icon,
                            color: sel ? _navPurple : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.asset});
  final IconData icon;
  final String asset;
}
