import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/lista_lutas_controller.dart';
import 'package:flutter_application_1/screens/menu/confirmacoes/entrar_confirmacao.dart';
import 'package:intl/intl.dart';

class ListaDeLutas extends StatefulWidget {
  final String? initialSnackMessage;

  const ListaDeLutas({super.key, this.initialSnackMessage});

  @override
  State<ListaDeLutas> createState() => _ListaDeLutasState();
}

class _ListaDeLutasState extends State<ListaDeLutas> {
  final LutaController controller = LutaController();
  String filtroPesquisa = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialSnackMessage != null && widget.initialSnackMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialSnackMessage!),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  DateTime? _parseDateTime(Map<String, dynamic> dados) {
    DateTime? dt;
    final rawDate = dados['data'];
    final rawTime = dados['horario'];

    if (rawDate != null) {
      if (rawDate is Timestamp) dt = rawDate.toDate();
      else if (rawDate is DateTime) dt = rawDate;
      else if (rawDate is String) {
        dt = DateTime.tryParse(rawDate);
        if (dt == null) {
          final parts = rawDate.split('/');
          if (parts.length == 3) {
            final d = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (d != null && m != null && y != null) dt = DateTime(y, m, d);
          }
        }
      }
    }

    if (dt != null && rawTime != null) {
      int hour = 0;
      int minute = 0;

      if (rawTime is Timestamp) {
        final t = rawTime.toDate();
        hour = t.hour;
        minute = t.minute;
      } else if (rawTime is DateTime) {
        hour = rawTime.hour;
        minute = rawTime.minute;
      } else if (rawTime is String) {
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(rawTime);
        if (match != null) {
          hour = int.tryParse(match.group(1)!) ?? 0;
          minute = int.tryParse(match.group(2)!) ?? 0;
        }
      }

      dt = DateTime(dt.year, dt.month, dt.day, hour, minute);
    }

    return dt;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    else if (raw is DateTime) dt = raw;
    else if (raw is String) {
      dt = DateTime.tryParse(raw);
      if (dt == null) {
        final parts = raw.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) dt = DateTime(y, m, d);
        }
      }
    }
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : raw.toString();
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    if (raw is Timestamp) return DateFormat('HH:mm').format(raw.toDate());
    if (raw is DateTime) return DateFormat('HH:mm').format(raw);
    if (raw is String) {
      final timeRegex = RegExp(r'^\d{1,2}:\d{2}$');
      if (timeRegex.hasMatch(raw.trim())) return raw.trim();
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return DateFormat('HH:mm').format(parsed);
      final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw);
      if (match != null) return match.group(0)!;
      return '';
    }
    return raw.toString();
  }

  bool _filtrarLuta(Map<String, dynamic> dados) {
    final termo = filtroPesquisa.toLowerCase();
    final idSala = (dados['idSala'] ?? '').toString().toLowerCase();
    final lutador1 = (dados['lutador1'] ?? '').toString().toLowerCase();
    final lutador2 = (dados['lutador2'] ?? '').toString().toLowerCase();
    final data = _formatDate(dados['data']).toLowerCase();
    final horario = _formatTime(dados['horario']).toLowerCase();

    return idSala.contains(termo) ||
        lutador1.contains(termo) ||
        lutador2.contains(termo) ||
        data.contains(termo) ||
        horario.contains(termo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      appBar: AppBar(
        title: const Text('Lista de Lutas'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Pesquisar por ID, Lutadores, Data ou Horário...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color.fromARGB(255, 37, 37, 37),
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
              stream: FirebaseFirestore.instance.collection('lutas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma luta cadastrada', style: TextStyle(color: Colors.white70)),
                  );
                }

                final agora = DateTime.now();

                List<QueryDocumentSnapshot> lutas = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final dataLuta = _parseDateTime(dados);
                  final futuraOuHoje = dataLuta != null &&
                      !dataLuta.isBefore(DateTime(agora.year, agora.month, agora.day));
                  return _filtrarLuta(dados) && futuraOuHoje;
                }).toList();

                lutas.sort((a, b) {
                  final dataA = _parseDateTime(a.data() as Map<String, dynamic>) ?? DateTime(2100);
                  final dataB = _parseDateTime(b.data() as Map<String, dynamic>) ?? DateTime(2100);
                  return dataA.compareTo(dataB);
                });

                if (filtroPesquisa.isEmpty && lutas.length > 5) {
                  lutas = lutas.take(5).toList();
                }

                if (lutas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma luta encontrada', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  itemCount: lutas.length,
                  itemBuilder: (context, index) {
                    final lutaDoc = lutas[index];
                    final dados = lutaDoc.data() as Map<String, dynamic>;
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final criadorId = (dados['criadorId'] ?? '').toString();
                    final lutador1 = (dados['lutador1'] ?? 'Lutador 1').toString();
                    final lutador2 = (dados['lutador2'] ?? 'Lutador 2').toString();
                    final formattedDate = _formatDate(dados['data']);
                    final formattedTime = _formatTime(dados['horario']);
                    final displayDateTime = (formattedDate.isEmpty && formattedTime.isEmpty)
                        ? 'Sem data'
                        : (formattedDate.isEmpty
                            ? formattedTime
                            : (formattedTime.isEmpty
                                ? formattedDate
                                : '$formattedDate  •  $formattedTime'));

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ConfirmacaoEntrada(
                            idSala: lutaDoc.id,
                            criadorId: criadorId,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 37, 37, 37), Color.fromARGB(255, 37, 37, 37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(2, 4))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                currentUserId == criadorId ? Icons.gavel_sharp : Icons.sports_mma,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$lutador1  x  $lutador2",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          displayDateTime,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.vpn_key, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          (dados['idSala'] ?? lutaDoc.id).toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Botão de remover, só para o criador
                            if (currentUserId == criadorId)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text('Deseja realmente excluir esta luta?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('lutas').doc(lutaDoc.id).delete();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Luta removida com sucesso'), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                              ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => controller.novaSala(context),
              icon: const Icon(Icons.add),
              label: const Text('Criar Luta'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
