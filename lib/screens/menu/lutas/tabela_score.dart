import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/menu_page.dart';

class ScoreTable extends StatefulWidget {
  final String salaId;

  const ScoreTable({super.key, required this.salaId});

  @override
  State<ScoreTable> createState() => _ScoreTableState();
}

class _ScoreTableState extends State<ScoreTable> {
  final _firestore = FirebaseFirestore.instance;
  bool _handledDeletion = false;

  void showTopSnackBar(String message, Color color) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2500))
        .then((_) => overlayEntry.remove());
  }

  Future<Map<String, String>> _fetchJuizNames(List<String> juizes) async {
    if (juizes.isEmpty) return {};
    try {
      final q = await _firestore
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: juizes)
          .get();
      final map = <String, String>{};
      for (var doc in q.docs) {
        final data = doc.data();
        map[doc.id] =
            (data['nome'] as String?) ?? (data['email'] as String?) ?? 'Juiz';
      }
      return map;
    } catch (e) {
      debugPrint('Erro ao buscar nomes dos juízes: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchJuizData(List<String> juizes) async {
    if (juizes.isEmpty) return {};
    try {
      final q = await _firestore
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: juizes)
          .get();
      final map = <String, Map<String, dynamic>>{};
      for (var doc in q.docs) {
        final data = doc.data();
        map[doc.id] = {
          'nome': (data['nome'] as String?) ?? (data['email'] as String?) ?? 'Juiz',
          'fotoBase64': data['fotoBase64'] as String?,
        };
      }
      return map;
    } catch (e) {
      debugPrint('Erro ao buscar dados dos juízes: $e');
      return {};
    }
  }

  Future<Map<String, String>> _fetchLutadorIds(String lutadorA, String lutadorB) async {
    final idsMap = <String, String>{};
    
    try {
      final lutadorASnapshot = await _firestore
          .collection('lutadores')
          .where('nome', isEqualTo: lutadorA)
          .limit(1)
          .get();
          
      if (lutadorASnapshot.docs.isNotEmpty) {
        idsMap[lutadorA] = lutadorASnapshot.docs.first.id;
      }

      final lutadorBSnapshot = await _firestore
          .collection('lutadores')
          .where('nome', isEqualTo: lutadorB)
          .limit(1)
          .get();
          
      if (lutadorBSnapshot.docs.isNotEmpty) {
        idsMap[lutadorB] = lutadorBSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('Erro ao buscar IDs dos lutadores: $e');
    }
    
    return idsMap;
  }

  Future<void> _navigateToMenuWithSnack(String message, {Color bg = Colors.blueGrey}) async {
    if (!mounted) return;
    showTopSnackBar(message, bg);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuPage()),
      (route) => false,
    );
  }

  Future<void> encerrarLuta(
    String lutadorA,
    String lutadorB,
    Map<String, List<double>> notasTotais,
    List<String> juizes,
  ) async {
    if (!mounted) return;

    for (var lutador in [lutadorA, lutadorB]) {
      if (!notasTotais.containsKey(lutador) || notasTotais[lutador]!.length < 3) {
        showTopSnackBar(
          "Todos os rounds devem estar preenchidos antes de encerrar.",
          Colors.redAccent,
        );
        return;
      }
    }

    try {
      final salaRef = _firestore.collection("lutas").doc(widget.salaId);
      final salaSnap = await salaRef.get();
      if (!salaSnap.exists) {
        if (!_handledDeletion) {
          _handledDeletion = true;
          await _navigateToMenuWithSnack('A luta foi encerrada.');
        }
        return;
      }

      double totalA = notasTotais[lutadorA]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
      double totalB = notasTotais[lutadorB]?.fold(0.0, (a, b) => a! + b) ?? 0.0;

      if (totalA == totalB) {
        await salaRef.update({
          "desempate": {
            "open": true,
            "lutadorA": lutadorA,
            "lutadorB": lutadorB,
            "votos": {},
          }
        });

        if (!mounted) return;
        showTopSnackBar("Empate! Juízes devem votar no desempate.", Colors.orangeAccent);
        return;
      }

      String vencedor = totalA > totalB ? lutadorA : lutadorB;

      final idsMap = await _fetchLutadorIds(lutadorA, lutadorB);
      final lutadorAId = idsMap[lutadorA] ?? '';
      final lutadorBId = idsMap[lutadorB] ?? '';
      final vencedorId = vencedor == lutadorA ? lutadorAId : lutadorBId;

      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "lutador1Id": lutadorAId,
        "lutador2Id": lutadorBId,
        "vencedor": vencedor,
        "vencedorId": vencedorId,
        "totalA": totalA,
        "totalB": totalB,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
        "idSala": widget.salaId,
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
        "Luta encerrada! Vencedor: $vencedor",
        bg: Colors.green,
      );
    } catch (e) {
      showTopSnackBar("Erro ao encerrar luta: $e", Colors.redAccent);
    }
  }

  Future<void> encerrarPorKO(
    String lutadorA,
    String lutadorB,
    Map<String, List<double>> notasTotais,
    List<String> juizes,
  ) async {
    if (!mounted) return;

    String? vencedorKO = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Escolha o vencedor por KO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_mma, size: 20),
              label: Text(lutadorA),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context, lutadorA),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_mma, size: 20),
              label: Text(lutadorB),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context, lutadorB),
            ),
          ],
        ),
      ),
    );

    if (vencedorKO == null) return;

    try {
      final salaRef = _firestore.collection("lutas").doc(widget.salaId);
      final salaSnap = await salaRef.get();
      if (!salaSnap.exists) {
        if (!_handledDeletion) {
          _handledDeletion = true;
          await _navigateToMenuWithSnack('A luta foi encerrada.');
        }
        return;
      }

      final idsMap = await _fetchLutadorIds(lutadorA, lutadorB);
      final lutadorAId = idsMap[lutadorA] ?? '';
      final lutadorBId = idsMap[lutadorB] ?? '';
      final vencedorId = vencedorKO == lutadorA ? lutadorAId : lutadorBId;

      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "lutador1Id": lutadorAId,
        "lutador2Id": lutadorBId,
        "vencedor": vencedorKO,
        "vencedorId": vencedorId,
        "totalA": notasTotais[lutadorA]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "totalB": notasTotais[lutadorB]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
        "vencedorKO": true,
        "idSala": widget.salaId,
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
        "Luta encerrada por KO: $vencedorKO",
        bg: Colors.redAccent,
      );
    } catch (e) {
      showTopSnackBar("Erro ao encerrar por KO: $e", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.salaId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B1B1B),
        body: Center(
          child: Text("ID da sala inválido", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text('Tabela de Pontuação'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("lutas").doc(widget.salaId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            if (!_handledDeletion) {
              _handledDeletion = true;
              Future.microtask(() => _navigateToMenuWithSnack('A luta foi encerrada.'));
            }
            return const SizedBox.shrink();
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>;
          final lutadorA = dados['lutador1'] ?? "Lutador A";
          final lutadorB = dados['lutador2'] ?? "Lutador B";
          final List<String> juizes = (dados['juizes'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

          final notasCollection =
              _firestore.collection("lutas").doc(widget.salaId).collection("notas");

          return StreamBuilder<QuerySnapshot>(
            stream: notasCollection.snapshots(),
            builder: (context, snapshotNotas) {
              if (snapshotNotas.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, List<double>> notasTotais = {};
              Set<String> juizesQueEnviaram = {};

              if (snapshotNotas.hasData) {
                for (var doc in snapshotNotas.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final juizUid = doc.id;
                  juizesQueEnviaram.add(juizUid);

                  final notasMap = Map<String, dynamic>.from(data['notas'] ?? {});
                  notasMap.forEach((lutador, lista) {
                    final listaDoubles = List<dynamic>.from(lista ?? [])
                        .map((n) => (n as num).toDouble())
                        .toList();

                    if (!notasTotais.containsKey(lutador)) {
                      notasTotais[lutador] = List<double>.from(listaDoubles);
                    } else {
                      for (int i = 0; i < listaDoubles.length; i++) {
                        if (i < notasTotais[lutador]!.length) {
                          notasTotais[lutador]![i] += listaDoubles[i];
                        } else {
                          notasTotais[lutador]!.add(listaDoubles[i]);
                        }
                      }
                    }
                  });
                }
              }

              double totalA = notasTotais[lutadorA]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
              double totalB = notasTotais[lutadorB]?.fold(0.0, (a, b) => a! + b) ?? 0.0;

              return FutureBuilder<Map<String, Map<String, dynamic>>>(
                future: _fetchJuizData(juizes),
                builder: (context, snapJuizData) {
                  final juizDataMap = snapJuizData.data ?? {};
                  return SafeArea(
                    child: Column(
                      children: [
                        // Header da luta (estilo igual ao Lobby)
                        _buildLutaHeader(dados, lutadorA, lutadorB),
                        
                        // Lista de juízes (estilo igual ao Lobby)
                        _buildJuizesSection(juizes, juizDataMap, juizesQueEnviaram),
                        
                        // Tabela de scores com design integrado
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Container da tabela com mesmo design
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 29, 29, 29),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        offset: const Offset(0, 3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header da tabela - REMOVIDO o contador de notas
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: Text(
                                          'Pontuação da Luta',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      
                                      // Tabela de scores
                                      _buildScoreTable(lutadorA, lutadorB, notasTotais, totalA, totalB),
                                    ],
                                  ),
                                ),
                                
                                // Botões de ação - AGORA FORA DO CONTAINER
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => encerrarLuta(lutadorA, lutadorB, notasTotais, juizes),
                                        icon: const Icon(Icons.flag, size: 20),
                                        label: const Text('Encerrar Luta', style: TextStyle(fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          backgroundColor: Colors.blueGrey,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => encerrarPorKO(lutadorA, lutadorB, notasTotais, juizes),
                                        icon: const Icon(Icons.flash_on, size: 20),
                                        label: const Text('Encerrar por KO', style: TextStyle(fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // =================== HEADER DA LUTA (estilo igual ao Lobby) ===================
  Widget _buildLutaHeader(Map<String, dynamic> dados, String lutadorA, String lutadorB) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 29, 29),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 2),
              color: Colors.white12,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.scoreboard,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$lutadorA  x  $lutadorB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      dados['idSala'] ?? '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== SEÇÃO DE JUÍZES (estilo igual ao Lobby) ===================
  Widget _buildJuizesSection(
    List<String> juizes,
    Map<String, Map<String, dynamic>> juizDataMap,
    Set<String> enviados,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 29, 29),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status dos Juízes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              // CORRIGIDO: Contagem correta - total de juizes na sala
              Text(
                '${juizes.length}/3',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          juizes.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum juiz conectado',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                )
              : Column(
                  children: juizes.map((uid) {
                    final data = juizDataMap[uid];
                    final nome = data?['nome'] ?? 
                        uid.substring(0, uid.length > 8 ? 8 : uid.length);
                    final fotoBase64 = data?['fotoBase64'] as String?;
                    final enviado = enviados.contains(uid);
                    
                    // CORRIGIDO: Avatar com foto real do usuário
                    ImageProvider? avatarImage;
                    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                      try {
                        final bytes = base64Decode(fotoBase64);
                        avatarImage = MemoryImage(bytes);
                      } catch (e) {
                        debugPrint('Erro ao decodificar foto do juiz: $e');
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Avatar com foto real do usuário
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarImage,
                            backgroundColor: Colors.grey[700],
                            child: avatarImage == null 
                                ? const Icon(Icons.person, color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: enviado ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              enviado ? "Enviado" : "Pendente",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // =================== TABELA DE SCORES (com cores de fundo modificadas) ===================
  Widget _buildScoreTable(
    String lutadorA,
    String lutadorB,
    Map<String, List<double>> notas,
    double totalA,
    double totalB,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 37, 37, 37),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.blueGrey.shade800, width: 0.6),
          ),
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A), // Cor mais escura para o header
              ),
              children: [
                _buildHeaderCell(lutadorA),
                _buildHeaderCell("Rodadas"),
                _buildHeaderCell(lutadorB),
              ],
            ),
            for (int i = 0; i < 3; i++)
              TableRow(
                decoration: BoxDecoration(
                  // Cores alternadas mais suaves
                  color: i.isOdd ? const Color(0xFF323232) : const Color(0xFF3A3A3A),
                ),
                children: [
                  _buildScoreCell(notas[lutadorA], i),
                  _buildRoundCell("Round ${i + 1}"),
                  _buildScoreCell(notas[lutadorB], i),
                ],
              ),
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A), // Cor mais escura para o footer
              ),
              children: [
                _buildTotalCell(totalA),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Total",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                _buildTotalCell(totalB),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _buildScoreCell(List<double>? notas, int i) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            notas != null && notas.length > i
                ? notas[i].toStringAsFixed(1)
                : '0.0',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildRoundCell(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text, style: const TextStyle(color: Colors.white70)),
        ),
      );

  Widget _buildTotalCell(double total) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            total.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
}