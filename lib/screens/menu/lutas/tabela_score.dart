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
<<<<<<< HEAD
=======

>>>>>>> origin/master
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

  Future<void> _navigateToMenuWithSnack(
    String message, {
<<<<<<< HEAD
    Color bg = Colors.blueGrey,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg),
    );
=======
    Color bg = Colors.green,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
>>>>>>> origin/master
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
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Todos os rounds devem estar preenchidos antes de encerrar."),
=======
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Todos os rounds devem estar preenchidos antes de encerrar a luta.",
            ),
>>>>>>> origin/master
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
<<<<<<< HEAD
          await _navigateToMenuWithSnack('A luta foi encerrada.');
=======
          await _navigateToMenuWithSnack(
            'A luta foi encerrada.',
            bg: Colors.green,
          );
>>>>>>> origin/master
        }
        return;
      }

      double totalA = notasTotais[lutadorA]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
      double totalB = notasTotais[lutadorB]?.fold(0.0, (a, b) => a! + b) ?? 0.0;

<<<<<<< HEAD
      String vencedor;
      bool desempate = false;

      if (totalA == totalB) {
        // Empate, abrir votação dos juízes
        String? vencedorDesempate =
            await _votacaoEmpate(lutadorA, lutadorB, juizes);
        if (vencedorDesempate == null) {
          vencedor = "Empate";
        } else {
          vencedor = vencedorDesempate;
          desempate = true;
        }
      } else {
        vencedor = totalA > totalB ? lutadorA : lutadorB;
      }
=======
      String vencedor = totalA > totalB
          ? lutadorA
          : (totalB > totalA ? lutadorB : "Empate");
>>>>>>> origin/master

      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "totalA": totalA,
        "totalB": totalB,
        "vencedor": vencedor,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
<<<<<<< HEAD
        "desempate": desempate,
=======
>>>>>>> origin/master
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
<<<<<<< HEAD
        desempate
            ? "Empate decidido pelos juízes: $vencedor"
            : "Luta encerrada e salva no histórico.",
        bg: Colors.blueGrey,
      );
    } catch (e) {
=======
        "A luta foi encerrada e salva no histórico.",
        bg: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
>>>>>>> origin/master
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao encerrar luta: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

<<<<<<< HEAD
  Future<String?> _votacaoEmpate(
      String lutadorA, String lutadorB, List<String> juizes) async {
    Map<String, String> votos = {};

    for (var juiz in juizes) {
      String? voto = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 37, 37, 37),
          title: Text("Juiz $juiz: escolha o vencedor do empate",
              style: const TextStyle(color: Colors.white)),
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

      if (voto == null) return null;
      votos[juiz] = voto;
    }

    int votosA = votos.values.where((v) => v == lutadorA).length;
    int votosB = votos.values.where((v) => v == lutadorB).length;

    if (votosA > votosB) return lutadorA;
    if (votosB > votosA) return lutadorB;
    return null;
  }

=======
>>>>>>> origin/master
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
<<<<<<< HEAD
        backgroundColor: const Color.fromARGB(255, 37, 37, 37),
=======
        backgroundColor: const Color(0xFF1B1B1D),
>>>>>>> origin/master
        title: const Text(
          "Escolha o vencedor por KO",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
<<<<<<< HEAD
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
=======
>>>>>>> origin/master
              onPressed: () => Navigator.pop(context, lutadorA),
              child: Text(lutadorA),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
<<<<<<< HEAD
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
=======
>>>>>>> origin/master
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
<<<<<<< HEAD
          await _navigateToMenuWithSnack('A luta foi encerrada.');
=======
          await _navigateToMenuWithSnack(
            'A luta foi encerrada.',
            bg: Colors.green,
          );
>>>>>>> origin/master
        }
        return;
      }

      await _firestore.collection("historico").doc(widget.salaId).set({
        "lutador1": lutadorA,
        "lutador2": lutadorB,
        "totalA": notasTotais[lutadorA]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "totalB": notasTotais[lutadorB]?.fold(0.0, (a, b) => a + b) ?? 0.0,
        "vencedor": vencedorKO,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizes,
        "vencedorKO": true,
      });

      await salaRef.delete();
      _handledDeletion = true;
      await _navigateToMenuWithSnack(
        "Luta encerrada por KO: $vencedorKO",
<<<<<<< HEAD
        bg: Colors.redAccent,
      );
    } catch (e) {
=======
        bg: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
>>>>>>> origin/master
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
<<<<<<< HEAD
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
        body: Center(
          child: Text("ID da sala inválido", style: TextStyle(color: Colors.white)),
=======
      return Scaffold(
        backgroundColor: const Color(0xFF1B1B1D),
        body: const Center(
          child: Text(
            "ID da sala inválido",
            style: TextStyle(color: Colors.white),
          ),
>>>>>>> origin/master
        ),
      );
    }

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      appBar: AppBar(
        title: const Text("Score da Luta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
=======
      backgroundColor: const Color(0xFF1B1B1D),
      appBar: AppBar(
        title: const Text(
          "Score da Luta",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C2F34),
>>>>>>> origin/master
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
<<<<<<< HEAD
              Future.microtask(() => _navigateToMenuWithSnack('A luta foi encerrada.'));
=======
              Future.microtask(
                () => _navigateToMenuWithSnack(
                  'A luta foi encerrada.',
                  bg: Colors.green,
                ),
              );
>>>>>>> origin/master
            }
            return const SizedBox.shrink();
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>;
          final lutadorA = dados['lutador1'] ?? "Lutador A";
          final lutadorB = dados['lutador2'] ?? "Lutador B";
          final List<String> juizes = (dados['juizes'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

<<<<<<< HEAD
          final notasCollection =
              _firestore.collection("lutas").doc(widget.salaId).collection("notas");
=======
          final notasCollection = _firestore
              .collection("lutas")
              .doc(widget.salaId)
              .collection("notas");
>>>>>>> origin/master

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

<<<<<<< HEAD
                  final notasMap = Map<String, dynamic>.from(data['notas'] ?? {});
                  notasMap.forEach((lutador, lista) {
                    final listaDoubles = List<dynamic>.from(lista ?? [])
                        .map((n) => (n as num).toDouble())
                        .toList();
=======
                  final notasMap = Map<String, dynamic>.from(
                    data['notas'] ?? {},
                  );
                  notasMap.forEach((lutador, lista) {
                    final listaDoubles = List<dynamic>.from(
                      lista ?? [],
                    ).map((n) => (n as num).toDouble()).toList();
>>>>>>> origin/master

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

<<<<<<< HEAD
              double totalA = notasTotais[lutadorA]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
              double totalB = notasTotais[lutadorB]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
=======
              double totalA =
                  notasTotais[lutadorA]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
              double totalB =
                  notasTotais[lutadorB]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
>>>>>>> origin/master

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
<<<<<<< HEAD
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
=======
                          lutadorA,
                          lutadorB,
                          notasTotais,
                          totalA,
                          totalB,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => encerrarLuta(
                            lutadorA,
                            lutadorB,
                            notasTotais,
                            juizes,
                          ),
                          icon: const Icon(Icons.flag, color: Colors.white),
                          label: const Text("Encerrar luta"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A6D8C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => encerrarPorKO(
                            lutadorA,
                            lutadorB,
                            notasTotais,
                            juizes,
                          ),
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          label: const Text("KO"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3A6D8C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
>>>>>>> origin/master
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
<<<<<<< HEAD
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 37, 37, 37),
=======
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F34),
>>>>>>> origin/master
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: juizes.map((uid) {
          final nome =
<<<<<<< HEAD
              nomesMap[uid] ?? uid.substring(0, uid.length > 8 ? 8 : uid.length);
=======
              nomesMap[uid] ??
              uid.substring(0, uid.length > 8 ? 8 : uid.length);
>>>>>>> origin/master
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
<<<<<<< HEAD
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  enviado ? "Enviado" : "Pendente",
                  style: TextStyle(
                    color: enviado ? Colors.lightGreenAccent : Colors.orangeAccent,
=======
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  enviado ? "Enviado" : "Pendente",
                  style: TextStyle(
                    color: enviado ? Colors.greenAccent : Colors.orangeAccent,
>>>>>>> origin/master
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
<<<<<<< HEAD
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
=======
          colors: [Color(0xFF2C2F34), Color(0xFF3A3F47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey.shade800, width: 0.6),
>>>>>>> origin/master
          ),
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          children: [
            TableRow(
<<<<<<< HEAD
              decoration: const BoxDecoration(color: Colors.blueGrey),
=======
              decoration: const BoxDecoration(color: Color(0xFF22252A)),
>>>>>>> origin/master
              children: [
                _buildHeaderCell(lutadorA),
                _buildHeaderCell("Rodadas"),
                _buildHeaderCell(lutadorB),
              ],
            ),
            for (int i = 0; i < 3; i++)
              TableRow(
                decoration: BoxDecoration(
<<<<<<< HEAD
                  color:
                      i.isOdd ? const Color(0xFF303030) : const Color(0xFF383838),
=======
                  color: i.isOdd
                      ? const Color(0xFF2F3238)
                      : const Color(0xFF3C4048),
>>>>>>> origin/master
                ),
                children: [
                  _buildScoreCell(notas[lutadorA], i),
                  _buildRoundCell("Round ${i + 1}"),
                  _buildScoreCell(notas[lutadorB], i),
                ],
              ),
            TableRow(
<<<<<<< HEAD
              decoration: const BoxDecoration(color: Colors.blueGrey),
=======
              decoration: const BoxDecoration(color: Color(0xFF2C2F34)),
>>>>>>> origin/master
              children: [
                _buildTotalCell(totalA),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Total",
                      style: TextStyle(
<<<<<<< HEAD
                          color: Colors.white, fontWeight: FontWeight.bold),
=======
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
>>>>>>> origin/master
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
<<<<<<< HEAD
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
=======
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildScoreCell(List<double>? notas, int i) => Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        notas != null && notas.length > i ? notas[i].toStringAsFixed(1) : '0',
        style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildRoundCell(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(color: Colors.white60)),
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
>>>>>>> origin/master
}
