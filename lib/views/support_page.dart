import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const Color _headerPurple = Color(0xFF9327EC);
  static const Color _pageBg = Color(0xFFF1DDF4);
  static const Color _titlePurple = Color(0xFF7C23D9);
  static const Color _shadow = Color(0x22000000);
  static const Color _green = Color(0xFF39D400);

  static const String _popupChibi = 'src/img/chibi_coucou.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          const _SupportHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avancée de la cagnotte',
                      style: TextStyle(
                        color: _titlePurple,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3F7),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: _shadow,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                            child: Column(
                              children: const [
                                _MoneyRow(label: 'Total :', value: '13221€'),
                                SizedBox(height: 18),
                                _MoneyRow(
                                  label: 'Somme attendue :',
                                  value: '12000€',
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 44,
                            decoration: const BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(28),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Moyen de paiement :',
                      style: TextStyle(
                        color: _titlePurple,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 26),

                    _PaypalCard(onTap: () => _showPaypalPopup(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaypalPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF982EF0), Color(0xFFBC6AF3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Non, c’est que du bénévolat évidemment.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    _popupChibi,
                    width: 78,
                    height: 78,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 78, height: 78),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB86AEF),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  static const String _headerChibi = 'src/img/chibi_calin.png';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: const Color(0xFF9327EC),
      padding: EdgeInsets.fromLTRB(28, topPadding + 26, 22, 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Nous soutenir !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Image.asset(
                _headerChibi,
                width: 126,
                height: 126,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 126, height: 126),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 4, color: const Color(0xFF35C8FF)),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC894F4),
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF7C23D9),
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaypalCard extends StatelessWidget {
  const _PaypalCard({required this.onTap});

  final VoidCallback onTap;

  static const String _paypalLogo = 'src/img/paypal.png';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset(
          _paypalLogo,
          width: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'PayPal',
            style: TextStyle(
              color: Color(0xFF1E4FA3),
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
