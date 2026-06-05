import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _headerPurple = Color(0xFF8F28E6);
  static const Color _bodyLilac = Color(0xFFF5DBFF);
  static const Color _bodyLilacDeep = Color(0xFFF9E4FF);
  static const Color _titlePurple = Color(0xFF7E2DE1);
  static const Color _cardBg = Colors.white;
  static const Color _labelPurple = Color(0xFF8D25E5);
  static const Color _notePurple = Color(0xFF9B59B6);
  static const Color _challengeText = Color(0xFF6A0DAD);
  static const Color _btnPurple = Color(0xFF8B2DE0);
  static const Color _shadow = Color(0x22000000);

  // ── Assets ────────────────────────────────────────────────────────────────
  static const String _chibiAsset = 'src/img/chibi_curieux.png';
  static const String _flameAsset = 'src/img/flammex2.png';

  // ── Catégories ────────────────────────────────────────────────────────────
  static const List<_Category> _categories = [
    _Category(label: 'Français', asset: 'src/img/francais.png'),
    _Category(label: 'Manga', asset: 'src/img/manga.png'),
    _Category(label: 'Anglais', asset: 'src/img/anglais.png'),
    _Category(label: 'Maths', asset: 'src/img/maths.png'),
    _Category(label: 'Dev', asset: 'src/img/dev.png'),
  ];

  final Set<int> _selected = {};

  void _toggleCategory(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _fallbackImg(double size) => Container(
    width: size,
    height: size,
    color: const Color(0xFFE8D0FF),
    child: const Icon(
      Icons.image_not_supported_rounded,
      color: Color(0xFF9B59B6),
    ),
  );

  Widget _asset(
    String path, {
    double? w,
    double? h,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      path,
      width: w,
      height: h,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallbackImg(w ?? h ?? 48),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(double width) {
    final titleSize = width < 390 ? 28.0 : 32.0;
    final chibiSize = width < 390 ? 90.0 : 100.0;
    return Container(
      width: double.infinity,
      color: _headerPurple,
      padding: const EdgeInsets.fromLTRB(24, 56, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Qu\'est ce qu\'on\ntest ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
          _asset(_chibiAsset, w: chibiSize, h: chibiSize, fit: BoxFit.contain),
        ],
      ),
    );
  }

  // ── Carte catégorie ───────────────────────────────────────────────────────
  Widget _buildCategoryCard(int index, double cardWidth) {
    final cat = _categories[index];
    final isSelected = _selected.contains(index);

    return GestureDetector(
      onTap: () => _toggleCategory(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: cardWidth,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: _labelPurple, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _labelPurple.withOpacity(0.28) : _shadow,
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: _asset(cat.asset, fit: BoxFit.cover),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _labelPurple,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                cat.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Catégories : scroll une par une ──────────────────────────────────────
  Widget _buildCategoriesScroll(double width) {
    const hPad = 24.0;
    const gap = 12.0;
    const cols = 3;
    final cardWidth = (width - hPad * 2 - gap * (cols - 1)) / cols;
    final listHeight = cardWidth + 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (context, index) =>
                _buildCategoryCard(index, cardWidth),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cols / _categories.length,
              minHeight: 4,
              backgroundColor: _labelPurple.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_labelPurple),
            ),
          ),
        ),
      ],
    );
  }

  // ── Note ──────────────────────────────────────────────────────────────────
  Widget _buildNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Text(
        'Note : Les catégories choisies ne rapportent qu\'un point par bonne réponse.',
        style: TextStyle(color: _notePurple, fontSize: 12.5, height: 1.4),
      ),
    );
  }

  // ── Challenge block ───────────────────────────────────────────────────────
  Widget _buildChallenge(double width) {
    const flameSize = 70.0;
    const flameTopSpace = 72.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge ta culture général\nen passant le quizz aléatoire.',
            style: TextStyle(
              color: _challengeText,
              fontSize: width < 390 ? 17 : 19,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: flameTopSpace),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: lancer le quizz aléatoire
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: _btnPurple,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Lancer le quizz\naléatoire',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 0,
                child: _asset(
                  _flameAsset,
                  w: flameSize,
                  h: flameSize,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bodyLilac,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_bodyLilac, _bodyLilacDeep],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(width),
                      const SizedBox(height: 22),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
                        child: Text(
                          'Catégories :',
                          style: TextStyle(
                            color: _titlePurple,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildCategoriesScroll(width),
                      _buildNote(),
                      _buildChallenge(width),
                      const SizedBox(height: 120),
                    ],
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

// ── Data class ──────────────────────────────────────────────────────────────
class _Category {
  const _Category({required this.label, required this.asset});

  final String label;
  final String asset;
}
