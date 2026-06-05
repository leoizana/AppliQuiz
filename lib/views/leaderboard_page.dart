import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:tp1/app_config.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({
    super.key,
    required this.token,
    required this.onLogout,
  });

  final String token;
  final Future<void> Function() onLogout;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const Duration _requestTimeout = Duration(seconds: 12);

  static const Color _bodyLilac = Color(0xFFF5DBFF);
  static const Color _headerPurple = Color(0xFF8F28E6);
  static const Color _bodyTextPurple = Color(0xFF7E2DE1);
  static const Color _podiumPurple = Color(0xFF8D25E5);
  static const Color _podiumPurpleDeep = Color(0xFF7F1EDC);
  static const Color _podiumLilacLight = Color(0xFFC65EFF);
  static const Color _podiumLilacPale = Color(0xFFB35AF6);
  static const Color _textYellow = Color(0xFFFFEF65);
  static const Color _shadow = Color(0x33000000);

  static const String _mascotAsset = 'src/img/chibi_coucou.png';
  static const String _goldAsset = 'src/img/1.png';
  static const String _silverAsset = 'src/img/2.png';
  static const String _bronzeAsset = 'src/img/3.png';

  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  List<LeaderboardEntry> _entries = const [];
  Map<String, String> _claims = const {};
  Map<String, dynamic>? _currentUserRaw;
  LeaderboardEntry? _currentUserEntry;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  TextStyle _uiText({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserFuture = _fetchCurrentUser();
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl$apiLeaderboardPath'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Leaderboard fetch failed: HTTP ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final claims = _decodeTokenClaims(widget.token);
      final currentUserRaw = await currentUserFuture;
      final rawEntries = _extractEntries(decoded);

      final entries = rawEntries
          .whereType<Map>()
          .map(
            (rawEntry) => LeaderboardEntry.fromJson(
              rawEntry.cast<String, dynamic>(),
              claims: claims,
              currentUserRaw: currentUserRaw,
            ),
          )
          .toList(growable: false);

      entries.sort(_compareEntries);

      final currentUserEntry = _findCurrentUserEntry(
        entries,
        claims,
        currentUserRaw,
      );

      if (!mounted) return;

      setState(() {
        _claims = claims;
        _currentUserRaw = currentUserRaw;
        _entries = entries.take(20).toList(growable: false);
        _currentUserEntry = currentUserEntry;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _entries = const [];
        _currentUserEntry = null;
        _loading = false;
      });
    }
  }

  List<dynamic> _extractEntries(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'leaderboard',
        'users',
        'results',
        'items',
        'payload',
      ]) {
        final found = _findFirstList(decoded[key]);
        if (found != null) return found;
      }
    }
    return const [];
  }

  List<dynamic>? _findFirstList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final entry in value.entries) {
        final found = _findFirstList(entry.value);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchCurrentUser() async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl$apiMePath'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, String> _decodeTokenClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }

  int _compareEntries(LeaderboardEntry left, LeaderboardEntry right) {
    final leftRank = left.rank;
    final rightRank = right.rank;
    if (leftRank != null && rightRank != null && leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }
    if (leftRank != null && rightRank == null) return -1;
    if (leftRank == null && rightRank != null) return 1;
    if (left.points != right.points) return right.points.compareTo(left.points);
    return left.displayName.toLowerCase().compareTo(
      right.displayName.toLowerCase(),
    );
  }

  LeaderboardEntry? _findCurrentUserEntry(
    List<LeaderboardEntry> entries,
    Map<String, String> claims,
    Map<String, dynamic>? currentUserRaw,
  ) {
    for (final entry in entries) {
      if (entry.isCurrentUser) return entry;
    }

    final currentName = _extractDisplayName(currentUserRaw ?? {});
    final currentId = _extractIdentifier(currentUserRaw ?? {});

    for (final entry in entries) {
      if (_sameIdentity(entry.displayName, currentName) ||
          _sameIdentity(entry.id, currentId)) {
        return entry;
      }
    }

    final claimCandidates = <String>{
      claims['pseudo'] ?? '',
      claims['username'] ?? '',
      claims['name'] ?? '',
      claims['display_name'] ?? '',
      claims['firstname'] ?? '',
      claims['first_name'] ?? '',
      claims['lastname'] ?? '',
      claims['last_name'] ?? '',
      claims['full_name'] ?? '',
      claims['sub'] ?? '',
      claims['id'] ?? '',
      claims['user_id'] ?? '',
    }.where((v) => v.trim().isNotEmpty).toList();

    for (final entry in entries) {
      if (claimCandidates.any((c) => _sameIdentity(entry.displayName, c)) ||
          claimCandidates.any((c) => _sameIdentity(entry.id, c))) {
        return entry;
      }
    }

    return null;
  }

  String _extractDisplayName(Map<String, dynamic> data) {
    final candidates = <String?>[
      _asString(data['pseudo']),
      _asString(data['username']),
      _asString(data['display_name']),
      _asString(data['displayName']),
      _asString(data['name']),
      _asString(data['firstname']),
      _asString(data['first_name']),
      data['firstname'] != null && data['lastname'] != null
          ? '${data['firstname']} ${data['lastname']}'.trim()
          : null,
      data['first_name'] != null && data['last_name'] != null
          ? '${data['first_name']} ${data['last_name']}'.trim()
          : null,
      _asString(data['full_name']),
      _asString(data['fullName']),
      _asString(data['email']),
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return 'Joueur X';
  }

  String _extractIdentifier(Map<String, dynamic> data) {
    final candidates = <String?>[
      _asString(data['id']),
      _asString(data['user_id']),
      _asString(data['uuid']),
      _asString(data['member_id']),
      _asString(data['student_id']),
      _asString(data['sub']),
      _asString(data['email']),
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return _extractDisplayName(data);
  }

  bool _sameIdentity(String? left, String? right) {
    if (left == null || right == null) return false;
    return _normalize(left) == _normalize(right);
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  Widget _assetImage(
    String assetPath, {
    required double width,
    required double height,
    required Widget fallback,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildFallbackMascot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0C2FF),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Color(0xFF6E2EE6), size: 44),
      ),
    );
  }

  Widget _buildFallbackMedal(int rank) {
    final gradient = switch (rank) {
      1 => const [Color(0xFFFFE28C), Color(0xFFBD8A1F)],
      2 => const [Color(0xFFD7D7D7), Color(0xFF8B8B8B)],
      _ => const [Color(0xFFD79662), Color(0xFF8C4D20)],
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradient),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: _uiText(
                size: 20,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(width: 10, height: 30, color: const Color(0xFFFF1E1E)),
      ],
    );
  }

  Widget _buildPodiumMedal(int rank) {
    final assetPath = switch (rank) {
      1 => _goldAsset,
      2 => _silverAsset,
      _ => _bronzeAsset,
    };

    return _assetImage(
      assetPath,
      width: 72,
      height: 72,
      fallback: _buildFallbackMedal(rank),
    );
  }

  String _ordinalLabel(int rank) => rank == 1 ? '1er' : '${rank}e';

  Widget _buildHeader(double width, double headerHeight) {
    final titleSize = width < 390 ? 30.0 : 34.0;
    final subtitleSize = width < 390 ? 16.0 : 18.0;
    final mascotSize = width < 390 ? 92.0 : 102.0;
    final greetingName = _extractDisplayName(_currentUserRaw ?? {});

    return SizedBox(
      height: headerHeight,
      child: Container(
        width: double.infinity,
        color: _headerPurple,
        child: Stack(
          children: [
            Positioned(
              left: 28,
              top: headerHeight * 0.38,
              right: 128,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coucou,\n${greetingName == 'Joueur X' ? (_claims['firstname'] ?? 'toi') : greetingName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _uiText(
                      size: titleSize,
                      weight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Prêt à péter les scores ?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _uiText(
                      size: subtitleSize,
                      weight: FontWeight.w400,
                      color: const Color(0xFFF2E7FF),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              top: 16,
              child: _assetImage(
                _mascotAsset,
                width: mascotSize,
                height: mascotSize,
                fallback: _buildFallbackMascot(mascotSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPoints(double width) {
    final currentScore = _currentUserRaw == null
        ? null
        : _extractPoints(_currentUserRaw!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Text(
        'Tu as actuellement ${currentScore ?? _currentUserEntry?.points ?? 0} points',
        style: _uiText(
          size: 24,
          weight: FontWeight.w400,
          color: _bodyTextPurple,
        ),
      ),
    );
  }

  Widget _buildPodiumCard(
    LeaderboardEntry? entry, {
    required int rank,
    required double cardWidth,
    required double cardHeight,
    required Color color,
  }) {
    final isCurrentUser = entry?.isCurrentUser ?? false;
    final points = entry?.points ?? 0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: isCurrentUser ? Border.all(color: _textYellow, width: 3) : null,
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 22,
            child: Text(
              '$points',
              style: _uiText(
                size: 28,
                weight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(bottom: 26, child: _buildPodiumMedal(rank)),
        ],
      ),
    );
  }

  Widget _buildPodium(double width) {
    final first = _entries.isNotEmpty ? _entries[0] : null;
    final second = _entries.length > 1 ? _entries[1] : null;
    final third = _entries.length > 2 ? _entries[2] : null;

    final leftHeight = width < 390 ? 192.0 : 204.0;
    final centerHeight = width < 390 ? 278.0 : 292.0;
    final rightHeight = width < 390 ? 168.0 : 178.0;
    final leftWidth = width * 0.23;
    final centerWidth = width * 0.34;
    final rightWidth = width * 0.23;
    const double nameGap = 8.0;
    final slotSpacing = width < 390 ? 10.0 : 14.0;

    Widget slot({
      required LeaderboardEntry? entry,
      required int rank,
      required double cardWidth,
      required double cardHeight,
      required Color color,
      required double fontSize,
      required FontWeight nameWeight,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: cardWidth,
            child: Text(
              entry?.displayName ?? 'Joueur X',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _uiText(
                size: fontSize,
                weight: nameWeight,
                color: const Color.fromARGB(255, 65, 0, 98),
              ),
            ),
          ),
          const SizedBox(height: nameGap),
          _buildPodiumCard(
            entry,
            rank: rank,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            color: color,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: slot(
              entry: second,
              rank: 2,
              cardWidth: leftWidth,
              cardHeight: leftHeight,
              color: _podiumLilacPale,
              fontSize: width < 390 ? 14 : 16,
              nameWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: slotSpacing),
          Expanded(
            child: slot(
              entry: first,
              rank: 1,
              cardWidth: centerWidth,
              cardHeight: centerHeight,
              color: _podiumPurpleDeep,
              fontSize: width < 390 ? 16 : 18,
              nameWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: slotSpacing),
          Expanded(
            child: slot(
              entry: third,
              rank: 3,
              cardWidth: rightWidth,
              cardHeight: rightHeight,
              color: _podiumLilacLight,
              fontSize: width < 390 ? 14 : 16,
              nameWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, double width) {
    final isCurrentUser = entry.isCurrentUser;
    final rankLabel = entry.rank != null
        ? _ordinalLabel(entry.rank!)
        : _ordinalLabel(_entries.indexOf(entry) + 4);

    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFC88BF7),
        borderRadius: BorderRadius.circular(34),
        border: isCurrentUser
            ? Border.all(color: _textYellow, width: 2.5)
            : null,
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: width * 0.18,
            child: Center(
              child: Text(
                entry.points.toString(),
                style: _uiText(
                  size: width < 390 ? 22 : 24,
                  weight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
          SizedBox(
            width: width * 0.14,
            child: Container(
              color: _podiumPurple,
              alignment: Alignment.center,
              child: Text(
                rankLabel,
                style: _uiText(
                  size: width < 390 ? 22 : 24,
                  weight: FontWeight.w400,
                  color: _textYellow,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _uiText(
                  size: width < 390 ? 22 : 24,
                  weight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double width, double height) {
    final headerHeight = (height * 0.24).clamp(210.0, 250.0);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _podiumPurple),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Impossible de charger le leaderboard.',
                    textAlign: TextAlign.center,
                    style: _uiText(
                      size: 20,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: _uiText(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(0xFFF6E2FF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _loadLeaderboard,
                    child: const Text('Réessayer'),
                  ),
                  TextButton(
                    onPressed: widget.onLogout,
                    child: Text(
                      'Se déconnecter',
                      style: _uiText(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _podiumPurple,
      onRefresh: _loadLeaderboard,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(width, headerHeight),
            _buildCurrentPoints(width),
            const SizedBox(height: 4),
            _buildPodium(width),
            Builder(
              builder: (context) {
                final afterPodium = _entries
                    .skip(3)
                    .take(17)
                    .toList(growable: false);

                if (afterPodium.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.fromLTRB(28, 20, 28, safeBottom + 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Top 20',
                        style: _uiText(
                          size: 18,
                          weight: FontWeight.w700,
                          color: _bodyTextPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final entry in afterPodium)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildLeaderboardRow(entry, width),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bodyLilac,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_bodyLilac, Color(0xFFF9E4FF)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: _buildContent(
                  context,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.points,
    required this.rank,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    required Map<String, String> claims,
    required Map<String, dynamic>? currentUserRaw,
  }) {
    return LeaderboardEntry(
      id: _extractIdentifier(json),
      displayName: _extractDisplayName(json),
      points: _extractPoints(json),
      rank: _extractRank(json),
      isCurrentUser: _matchesCurrentUser(json, claims, currentUserRaw),
    );
  }

  final String id;
  final String displayName;
  final int points;
  final int? rank;
  final bool isCurrentUser;
}

int _extractPoints(Map<String, dynamic> data) {
  for (final key in [
    'points',
    'score',
    'xp',
    'total_points',
    'totalPoints',
    'total_score',
    'totalScore',
  ]) {
    final v = data[key];
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
  }
  return 0;
}

int? _extractRank(Map<String, dynamic> data) {
  for (final key in ['rank', 'position', 'place', 'order', 'ranking']) {
    final v = data[key];
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
  }
  return null;
}

String _extractDisplayName(Map<String, dynamic> data) {
  final candidates = <String?>[
    _asString(data['pseudo']),
    _asString(data['username']),
    _asString(data['display_name']),
    _asString(data['displayName']),
    _asString(data['name']),
    _asString(data['firstname']),
    _asString(data['first_name']),
    data['firstname'] != null && data['lastname'] != null
        ? '${data['firstname']} ${data['lastname']}'.trim()
        : null,
    data['first_name'] != null && data['last_name'] != null
        ? '${data['first_name']} ${data['last_name']}'.trim()
        : null,
    _asString(data['full_name']),
    _asString(data['fullName']),
    _asString(data['email']),
  ];
  for (final c in candidates) {
    if (c != null && c.trim().isNotEmpty) return c.trim();
  }
  return 'Joueur X';
}

String _extractIdentifier(Map<String, dynamic> data) {
  final candidates = <String?>[
    _asString(data['id']),
    _asString(data['user_id']),
    _asString(data['uuid']),
    _asString(data['member_id']),
    _asString(data['student_id']),
    _asString(data['sub']),
    _asString(data['email']),
  ];
  for (final c in candidates) {
    if (c != null && c.trim().isNotEmpty) return c.trim();
  }
  return _extractDisplayName(data);
}

bool _sameIdentity(String? l, String? r) {
  if (l == null || r == null) return false;
  return _normalize(l) == _normalize(r);
}

String _normalize(String v) =>
    v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v.trim();
  return v.toString().trim();
}

bool _matchesCurrentUser(
  Map<String, dynamic> entry,
  Map<String, String> claims,
  Map<String, dynamic>? currentUserRaw,
) {
  final entryName = _extractDisplayName(entry);
  final entryId = _extractIdentifier(entry);

  if (currentUserRaw != null) {
    if (_sameIdentity(entryName, _extractDisplayName(currentUserRaw)) ||
        _sameIdentity(entryId, _extractIdentifier(currentUserRaw))) {
      return true;
    }
  }

  final candidates = <String?>[
    claims['pseudo'],
    claims['username'],
    claims['name'],
    claims['display_name'],
    claims['firstname'],
    claims['first_name'],
    claims['lastname'],
    claims['last_name'],
    claims['full_name'],
    claims['sub'],
    claims['id'],
    claims['user_id'],
  ].whereType<String>().where((v) => v.trim().isNotEmpty);

  return candidates.any(
    (c) => _sameIdentity(entryName, c) || _sameIdentity(entryId, c),
  );
}
