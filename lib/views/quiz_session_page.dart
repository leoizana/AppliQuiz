import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tp1/app_config.dart';

class QuizSessionPage extends StatefulWidget {
  const QuizSessionPage({
    super.key,
    required this.token,
    this.themeId,
    this.themeLabel,
    this.questionLimit = 10,
  });

  final String token;
  final int? themeId;
  final String? themeLabel;
  final int questionLimit;

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  static const Color _bg = Color(0xFFEEDBEF);
  static const Color _purple = Color(0xFF982EF0);
  static const Color _purpleLight = Color(0xFFBC6AF3);
  static const Color _white = Colors.white;
  static const Color _red = Color(0xFFFF1200);
  static const Color _shadow = Color(0x2A000000);
  static const Color _brownDots = Color(0xFF6B3B1E);
  static const Color _green = Color(0xFF18D300);
  static const Color _wrongText = Color(0xFFFF6B57);
  static const Color _buttonLilac = Color(0xFFB86AEF);

  static const String _chibiQuestionAsset = 'src/img/chibi_question.png';
  static const String _chibiQuitAsset = 'src/img/chibi_choquer.png';
  static const String _chibiSuccessAsset = 'src/img/chibi_content.png';
  static const String _chibiFailureAsset = 'src/img/chibi_enerver.png';
  static const String _chibiEndAsset = 'src/img/chibi_content.png';

  bool _loading = true;
  bool _submitting = false;
  bool _transitionLocked = false;
  String? _error;

  int? _quizId;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl$apiQuizStartPath'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'theme_id': widget.themeId,
          'question_limit': widget.questionLimit,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erreur start quiz: HTTP ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data =
          (decoded is Map<String, dynamic> &&
              decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;

      final quizId = data['id'] as int?;
      final questionsRaw = (data['questions'] as List<dynamic>? ?? const []);

      final questions = questionsRaw
          .whereType<Map>()
          .map((q) => QuizQuestion.fromJson(q.cast<String, dynamic>()))
          .toList();

      if (!mounted) return;

      setState(() {
        _quizId = quizId;
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleAnswerTap(String answer) async {
    if (_transitionLocked || _submitting || _questions.isEmpty) return;

    final question = _questions[_currentIndex];
    final isCorrect =
        answer.trim().toLowerCase() == question.answer.trim().toLowerCase();

    setState(() {
      _transitionLocked = true;
      _answers[question.id] = answer;
      if (isCorrect) {
        _score++;
      }
    });

    if (isCorrect) {
      await _showCorrectDialog();
    } else {
      await _showWrongDialog(correctAnswer: question.answer);
    }

    if (!mounted) return;

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _transitionLocked = false;
      });
    } else {
      await _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    if (_quizId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final body = {
        'answers': _questions.map((q) {
          return {'question_id': q.id, 'user_answer': _answers[q.id] ?? ''};
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl$apiQuizSubmitBasePath/$_quizId/submit'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erreur submit quiz: HTTP ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      int finalScore = _score;
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic> && data['final_score'] is int) {
          finalScore = data['final_score'] as int;
        }
      }

      if (!mounted) return;

      setState(() {
        _score = finalScore;
        _submitting = false;
      });

      await _showEndDialog(score: finalScore);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
        _transitionLocked = false;
      });
    }
  }

  Future<void> _showQuitDialog() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _QuizPopup(
        title: 'Es-tu bien certain\nde vouloir quitter ?',
        imageAsset: _chibiQuitAsset,
        titleColor: Colors.white,
        firstButtonLabel: 'Non',
        firstButtonColor: _green,
        secondButtonLabel: 'Oui',
        secondButtonColor: _red,
        onFirstPressed: () => Navigator.pop(context, false),
        onSecondPressed: () => Navigator.pop(context, true),
      ),
    );

    if (shouldQuit == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showCorrectDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizPopup(
        title: 'Bravo ! Continue\ncomme ça',
        imageAsset: _chibiSuccessAsset,
        titleColor: _green,
        titleShadowColor: const Color(0xAA5E006C),
        singleButtonLabel: 'Continuer',
        singleButtonColor: _buttonLilac,
        onSinglePressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _showWrongDialog({required String correctAnswer}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizPopup(
        title: 'Désolé, la bonne\nréponse était\n\n$correctAnswer',
        imageAsset: _chibiFailureAsset,
        titleColor: _wrongText,
        titleShadowColor: const Color(0xAA7D1B3A),
        singleButtonLabel: 'Continuer',
        singleButtonColor: _buttonLilac,
        onSinglePressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _showEndDialog({required int score}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizPopup(
        title: 'Tu as obtenu un\nscore de $score.',
        imageAsset: _chibiEndAsset,
        titleColor: Colors.white,
        singleButtonLabel: 'Continuer',
        singleButtonColor: _buttonLilac,
        onSinglePressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildQuestionCard({
    required QuizQuestion question,
    required double cardHeight,
    required double width,
  }) {
    final domeWidth = width * 0.42;
    final domeHeight = cardHeight * 0.34;

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: cardHeight,
          padding: EdgeInsets.fromLTRB(20, cardHeight * 0.26, 20, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_purple, _purpleLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Center(
            child: Text(
              question.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: cardHeight * 0.145,
                fontWeight: FontWeight.w500,
                height: 1.24,
              ),
            ),
          ),
        ),
        Positioned(
          top: -domeHeight * 0.30,
          child: Container(
            width: domeWidth,
            height: domeHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purple, _purpleLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(domeHeight),
                topRight: Radius.circular(domeHeight),
                bottomLeft: Radius.circular(domeHeight * 0.28),
                bottomRight: Radius.circular(domeHeight * 0.28),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              (_currentIndex + 1).toString().padLeft(2, '0'),
              style: TextStyle(
                color: Colors.white,
                fontSize: domeHeight * 0.40,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required String letter,
    required String value,
    required bool selected,
    required double height,
  }) {
    return GestureDetector(
      onTap: () => _handleAnswerTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_purpleLight, _purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: _shadow, blurRadius: 9, offset: Offset(0, 5)),
          ],
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Row(
          children: [
            SizedBox(width: height * 0.18),
            Container(
              width: height * 0.52,
              height: height * 0.52,
              decoration: const BoxDecoration(
                color: _white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  color: _purple,
                  fontSize: height * 0.24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: height * 0.20),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * 0.20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: height * 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required double height,
    required int current,
    required int total,
  }) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0F4),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              '$current/$total',
              style: const TextStyle(
                color: _purple,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Text(
                    '• • • •',
                    style: TextStyle(
                      color: _brownDots,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Flexible(
                  child: Image.asset(
                    _chibiQuestionAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _purple,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;

            final horizontalPad = w * 0.045;
            final closeSize = w * 0.15;
            final questionCardHeight = h * 0.225;
            final answerHeight = h * 0.102;
            final answersGap = h * 0.018;
            final bottomAreaHeight = h * 0.082;

            final question = _questions.isNotEmpty
                ? _questions[_currentIndex]
                : null;
            final currentAnswer = question == null
                ? null
                : _answers[question.id];

            if (_loading) {
              return const Center(
                child: CircularProgressIndicator(color: _purple),
              );
            }

            if (_error != null && _questions.isEmpty) {
              return _buildErrorState();
            }

            if (question == null) {
              return const Center(
                child: Text(
                  'Aucune question trouvée.',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                h * 0.008,
                horizontalPad,
                h * 0.008,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _showQuitDialog,
                      child: Container(
                        width: closeSize,
                        height: closeSize,
                        decoration: const BoxDecoration(
                          color: _red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _shadow,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: closeSize * 0.54,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.014),
                  _buildQuestionCard(
                    question: question,
                    cardHeight: questionCardHeight,
                    width: w - (horizontalPad * 2),
                  ),
                  SizedBox(height: h * 0.025),
                  Expanded(
                    child: Column(
                      children: [
                        ...List.generate(question.proposals.length, (i) {
                          final value = question.proposals[i];
                          final letter = String.fromCharCode(65 + i);

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == question.proposals.length - 1
                                  ? 0
                                  : answersGap,
                            ),
                            child: _buildAnswerButton(
                              letter: letter,
                              value: value,
                              selected: currentAnswer == value,
                              height: answerHeight,
                            ),
                          );
                        }),
                        const Spacer(),
                        if (_submitting)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: _purple,
                              ),
                            ),
                          ),
                        if (_error != null && !_submitting)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        _buildBottomBar(
                          height: bottomAreaHeight,
                          current: _currentIndex + 1,
                          total: _questions.length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.label,
    required this.proposals,
    required this.answer,
    this.themeId,
    this.theme,
  });

  final int id;
  final String label;
  final List<String> proposals;
  final String answer;
  final int? themeId;
  final String? theme;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int,
      label: (json['label'] ?? '') as String,
      proposals: (json['proposals'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      answer: (json['answer'] ?? '') as String,
      themeId: json['theme_id'] as int?,
      theme: json['theme']?.toString(),
    );
  }
}

class _QuizPopup extends StatelessWidget {
  const _QuizPopup({
    required this.title,
    required this.imageAsset,
    this.titleColor = Colors.white,
    this.titleShadowColor,
    this.singleButtonLabel,
    this.singleButtonColor,
    this.onSinglePressed,
    this.firstButtonLabel,
    this.firstButtonColor,
    this.secondButtonLabel,
    this.secondButtonColor,
    this.onFirstPressed,
    this.onSecondPressed,
  });

  final String title;
  final String imageAsset;
  final Color titleColor;
  final Color? titleShadowColor;

  final String? singleButtonLabel;
  final Color? singleButtonColor;
  final VoidCallback? onSinglePressed;

  final String? firstButtonLabel;
  final Color? firstButtonColor;
  final String? secondButtonLabel;
  final Color? secondButtonColor;
  final VoidCallback? onFirstPressed;
  final VoidCallback? onSecondPressed;

  @override
  Widget build(BuildContext context) {
    final hasTwoButtons = firstButtonLabel != null && secondButtonLabel != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      shadows: titleShadowColor != null
                          ? [
                              Shadow(
                                color: titleShadowColor!,
                                offset: const Offset(1, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  imageAsset,
                  width: 74,
                  height: 74,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 74, height: 74),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (hasTwoButtons)
              Row(
                children: [
                  Expanded(
                    child: _PopupButton(
                      label: firstButtonLabel!,
                      color: firstButtonColor!,
                      onTap: onFirstPressed!,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _PopupButton(
                      label: secondButtonLabel!,
                      color: secondButtonColor!,
                      onTap: onSecondPressed!,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: _PopupButton(
                  label: singleButtonLabel ?? 'Continuer',
                  color: singleButtonColor ?? const Color(0xFFB86AEF),
                  onTap: onSinglePressed ?? () => Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
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
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
