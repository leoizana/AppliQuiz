import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key, required this.token, required this.onLogout});

  final String token;
  final Future<void> Function() onLogout;

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _loading = true;
  String? _error;

  String pseudo = '';
  String prenom = '';
  String nom = '';
  String email = '';
  int points = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl$apiMePath'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final json = jsonDecode(response.body);
      final data = json['data'] ?? {};

      setState(() {
        pseudo = data['username']?.toString() ?? '';
        prenom = data['firstname']?.toString() ?? '';
        nom = data['lastname']?.toString() ?? '';
        email = data['email']?.toString() ?? '';
        points = int.tryParse(data['score']?.toString() ?? '0') ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF1DDF4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            : Stack(
                children: [
                  // Contenu scrollable
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 140),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Center(
                          child: Image.asset(
                            'src/img/userprofil.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _InfoCard(label: 'Pseudo', value: pseudo),

                        const SizedBox(height: 28),

                        _InfoCard(label: 'Prénom', value: prenom),

                        const SizedBox(height: 28),

                        _InfoCard(label: 'Nom', value: nom),

                        const SizedBox(height: 28),

                        _InfoCard(label: 'Points', value: points.toString()),

                        const SizedBox(height: 28),

                        _InfoCard(label: 'Mail', value: email, multiline: true),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B2DE0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () async {
                              await widget.onLogout();
                            },
                            child: const Text(
                              'Se déconnecter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),

                  Positioned(
                    left: -20,
                    bottom: 90,
                    child: Image.asset(
                      'src/img/chibi_dodo.png',
                      width: 130,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$label :',
            style: const TextStyle(
              color: Color(0xFFC894F4),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7C23D9),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
