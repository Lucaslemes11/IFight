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

  // 🔹 NOVO MÉTODO: Buscar IDs dos lutadores pelo nome
  Future<Map<String, String>> _fetchLutadorIds(String lutadorA, String lutadorB) async {
    final idsMap = <String, String>{};
    
    try {
      // Busca o ID do lutador A
      final lutadorASnapshot = await _firestore
          .collection('lutadores')
          .where('nome', isEqualTo: lutadorA)
          .limit(1)
          .get();
          
      if (lutadorASnapshot.docs.isNotEmpty) {
        idsMap[lutadorA] = lutadorASnapshot.docs.first.id;
      }

      // Busca o ID do lutador B
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

  Future<void> _navigateToMenuWithSnack(
    String message, {
    Color bg = Colors.blueGrey,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg),
    );
    await Future.delayed(const Duration(milliseconds: 300));
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
      if (!notasTotais.containsKey(lutador) ||
          notasTotais[lutador]!.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Todos os rounds devem estar preenchidos antes de encerrar."),
            backgroundColor: Colors.redAccent,
          ),
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
        // Empate -> abrir tela de desempate para juízes
        await salaRef.update({
          "desempate": {
            "open": true,
            "lutadorA": lutadorA,
            "lutadorB": lutadorB,
            "votos": {},
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Empate! Juízes devem votar no desempate."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      String vencedor = totalA > totalB ? lutadorA : lutadorB;

      // 🔹 BUSCAR IDs DOS LUTADORES
      final idsMap = await _fetchLutadorIds(lutadorA, lutadorB);
      final lutadorAId = idsMap[lutadorA] ?? '';
      final lutadorBId = idsMap[lutadorB] ?? '';
      final vencedorId = vencedor == lutadorA ? lutadorAId : 
                        vencedor == lutadorB ? lutadorBId : '';

      // 🔹 SALVAR NO HISTÓRICO COM IDs
      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "lutador1Id": lutadorAId,      // 🔹 NOVO
        "lutador2Id": lutadorBId,      // 🔹 NOVO
        "vencedor": vencedor,
        "vencedorId": vencedorId,      // 🔹 NOVO
        "totalA": totalA,
        "totalB": totalB,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
        "idSala": widget.salaId,       // 🔹 ADICIONADO para pesquisa
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
        "Luta encerrada e salva no histórico. Vencedor: $vencedor",
        bg: Colors.blueGrey,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao encerrar luta: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        backgroundColor: const Color.fromARGB(255, 37, 37, 37),
        title: const Text(
          "Escolha o vencedor por KO",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () => Navigator.pop(context, lutadorA),
              child: Text(lutadorA),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () => Navigator.pop(context, lutadorB),
              child: Text(lutadorB),
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

      // 🔹 BUSCAR IDs DOS LUTADORES
      final idsMap = await _fetchLutadorIds(lutadorA, lutadorB);
      final lutadorAId = idsMap[lutadorA] ?? '';
      final lutadorBId = idsMap[lutadorB] ?? '';
      final vencedorId = vencedorKO == lutadorA ? lutadorAId : 
                        vencedorKO == lutadorB ? lutadorBId : '';

      // 🔹 SALVAR NO HISTÓRICO COM IDs
      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "lutador1Id": lutadorAId,      // 🔹 NOVO
        "lutador2Id": lutadorBId,      // 🔹 NOVO
        "vencedor": vencedorKO,
        "vencedorId": vencedorId,      // 🔹 NOVO
        "totalA": notasTotais[lutadorA]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "totalB": notasTotais[lutadorB]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
        "vencedorKO": true,
        "idSala": widget.salaId,       // 🔹 ADICIONADO para pesquisa
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
        "Luta encerrada por KO: $vencedorKO",
        bg: Colors.redAccent,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao encerrar por KO: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.salaId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
        body: Center(
          child: Text("ID da sala inválido", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      appBar: AppBar(
        title: const Text("Score da Luta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
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

              return FutureBuilder<Map<String, String>>(
                future: _fetchJuizNames(juizes),
                builder: (context, snapNomes) {
                  final nomesMap = snapNomes.data ?? {};
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildJuizesList(juizes, nomesMap, juizesQueEnviaram),
                        const SizedBox(height: 16),
                        _buildScoreTable(
                            lutadorA, lutadorB, notasTotais, totalA, totalB),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => encerrarLuta(
                              lutadorA, lutadorB, notasTotais, juizes),
                          icon: const Icon(Icons.flag, color: Colors.white),
                          label: const Text("Encerrar Luta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => encerrarPorKO(
                              lutadorA, lutadorB, notasTotais, juizes),
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          label: const Text("Encerrar por KO"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildJuizesList(
    List<String> juizes,
    Map<String, String> nomesMap,
    Set<String> enviados,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 37, 37, 37),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: juizes.map((uid) {
          final nome =
              nomesMap[uid] ?? uid.substring(0, uid.length > 8 ? 8 : uid.length);
          final enviado = enviados.contains(uid);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  enviado ? "Enviado" : "Pendente",
                  style: TextStyle(
                    color: enviado ? Colors.lightGreenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreTable(
    String lutadorA,
    String lutadorB,
    Map<String, List<double>> notas,
    double totalA,
    double totalB,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 37, 37, 37),
            Color.fromARGB(255, 47, 47, 47)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              decoration: const BoxDecoration(color: Color.fromARGB(255, 37, 37, 37)),
              children: [
                _buildHeaderCell(lutadorA),
                _buildHeaderCell("Rodadas"),
                _buildHeaderCell(lutadorB),
              ],
            ),
            for (int i = 0; i < 3; i++)
              TableRow(
                decoration: BoxDecoration(
                  color:
                      i.isOdd ? const Color(0xFF303030) : const Color(0xFF383838),
                ),
                children: [
                  _buildScoreCell(notas[lutadorA], i),
                  _buildRoundCell("Round ${i + 1}"),
                  _buildScoreCell(notas[lutadorB], i),
                ],
              ),
            TableRow(
              decoration: const BoxDecoration(color: Color.fromARGB(255, 37, 37, 37)),
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