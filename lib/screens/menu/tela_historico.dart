import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/score_details.dart' show ScoreDetails;
import 'package:firebase_auth/firebase_auth.dart';

class Historico extends StatefulWidget {
  const Historico({super.key});

  @override
  State<Historico> createState() => _HistoricoState();
}

class _HistoricoState extends State<Historico> {
  String filtroPesquisa = "";

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    else if (raw is DateTime) dt = raw;
    else if (raw is String) dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '';
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    else if (raw is DateTime) dt = raw;
    else if (raw is String) dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('HH:mm').format(dt) : '';
  }

  Map<String, List<double>> _parseNotas(dynamic rawNotas) {
    if (rawNotas is Map) {
      return rawNotas.map((key, value) {
        final list = (value as List?)?.map((e) => (e as num).toDouble()).toList() ?? <double>[];
        return MapEntry(key.toString(), list);
      });
    }
    return {};
  }

  Future<void> _removerHistorico(String docId) async {
    final senhaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text("Remover Luta", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Digite sua senha para confirmar a remoção desta luta:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Senha",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Remover"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: senhaController.text.trim(),
        );
        try {
          await user.reauthenticateWithCredential(cred);
          await FirebaseFirestore.instance.collection('historico').doc(docId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Luta removida do histórico!")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Senha incorreta!")),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text('Histórico de Lutas'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Pesquisar por ID da sala ou vencedor...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) => setState(() => filtroPesquisa = valor.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('historico')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma luta finalizada ainda.', style: TextStyle(color: Colors.white70)),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final idSala = (dados['idSala'] ?? '').toString().toLowerCase();
                  final vencedor = (dados['vencedor'] ?? '').toString().toLowerCase();
                  final lutador1 = (dados['lutador1'] ?? '').toString().trim();
                  final lutador2 = (dados['lutador2'] ?? '').toString().trim();

                  if (lutador1.isEmpty || lutador2.isEmpty) return false;
                  return idSala.contains(filtroPesquisa) || vencedor.contains(filtroPesquisa);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma luta encontrada', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final lutaDoc = docs[index];
                    final luta = lutaDoc.data() as Map<String, dynamic>;
                    final lutador1 = luta['lutador1'] ?? 'Lutador 1';
                    final lutador2 = luta['lutador2'] ?? 'Lutador 2';
                    final vencedor = luta['vencedor'] ?? 'Empate';
                    final rawData = luta['data'];
                    final data = _formatDate(rawData);
                    final hora = _formatTime(rawData);
                    final dataHora = [data, hora].where((e) => e.isNotEmpty).join(' • ');

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScoreDetails(
                              lutador1: lutador1,
                              lutador2: lutador2,
                              notasTotais: _parseNotas(luta['notas']),
                              vencedor: vencedor,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.history, color: Colors.white, size: 36),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$lutador1  x  $lutador2',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(dataHora,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.emoji_events, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text('Vencedor: $vencedor',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _removerHistorico(lutaDoc.id),
                                ),
                                const SizedBox(height: 6),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
