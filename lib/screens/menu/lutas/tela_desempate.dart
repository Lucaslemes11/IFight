import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaDesempate extends StatefulWidget {
  final String salaId;
  final List<String> lutadores;

  const TelaDesempate({
    super.key,
    required this.salaId,
    required this.lutadores,
  });

  @override
  State<TelaDesempate> createState() => _TelaDesempateState();
}

class _TelaDesempateState extends State<TelaDesempate> {
  bool _isSending = false;
  String? _usuarioVotou;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _salaStream;

  @override
  void initState() {
    super.initState();
    _checarVotoAnterior();
    _salaStream = FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .snapshots();

    _salaStream.listen(_verificarEncerramento);
  }

  Future<void> _checarVotoAnterior() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final salaRef =
        FirebaseFirestore.instance.collection("lutas").doc(widget.salaId);
    final snap = await salaRef.get();

    if (snap.exists) {
      final data = snap.data();
      final votos =
          data?['desempate']?['votos'] as Map<String, dynamic>? ?? {};
      if (votos.containsKey(usuario.uid)) {
        setState(() => _usuarioVotou = votos[usuario.uid]);
      }
    }
  }

  Future<void> enviarVoto(String vencedor) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    if (_usuarioVotou != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Você já votou.")),
      );
      return;
    }

    setState(() => _isSending = true);

    final salaRef =
        FirebaseFirestore.instance.collection("lutas").doc(widget.salaId);

    try {
      await salaRef.update({
        "desempate.votos.${usuario.uid}": vencedor,
      });

      setState(() => _usuarioVotou = vencedor);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Voto enviado: $vencedor")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar voto: $e")),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _verificarEncerramento(DocumentSnapshot<Map<String, dynamic>> snap) async {
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null || data['desempate'] == null) return;

    final votos = Map<String, dynamic>.from(data['desempate']['votos'] ?? {});
    final juizesEsperados = List<String>.from(data['juizes'] ?? []);

    final todosVotaram = juizesEsperados.every((j) => votos.containsKey(j));

    if (todosVotaram) {
      Map<String, int> contagem = {};
      votos.values.forEach((v) {
        contagem[v] = (contagem[v] ?? 0) + 1;
      });

      String vencedor = contagem.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      // Busca notas totais da luta
      final notasSnap = await FirebaseFirestore.instance
          .collection("lutas")
          .doc(widget.salaId)
          .collection("notas")
          .get();

      Map<String, List<double>> notasTotais = {};

      for (var doc in notasSnap.docs) {
        final data = doc.data();
        data.forEach((lutador, lista) {
          List<double> listaDoubles = [];
          if (lista is Iterable) {
            listaDoubles = lista.map((n) => (n as num?)?.toDouble() ?? 0.0).toList();
          } else if (lista is num) {
            listaDoubles = [lista.toDouble()];
          } else {
            listaDoubles = [];
          }
          notasTotais[lutador] = listaDoubles;
        });
      }

      double totalA = (notasTotais[widget.lutadores[0]] ?? []).fold(0.0, (a, b) => a + b);
      double totalB = (notasTotais[widget.lutadores[1]] ?? []).fold(0.0, (a, b) => a + b);

      // Salva no histórico
      await FirebaseFirestore.instance
          .collection("historico")
          .doc(widget.salaId)
          .set({
        "lutador1": widget.lutadores[0],
        "lutador2": widget.lutadores[1],
        "totalA": totalA,
        "totalB": totalB,
        "vencedor": vencedor,
        "data": DateTime.now(),
        "notas": notasTotais,
        "juizes": juizesEsperados,
        "votosDesempate": votos,
        "vencedorDesempate": true,
      });

      // Remove a luta ativa
      await FirebaseFirestore.instance
          .collection("lutas")
          .doc(widget.salaId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Desempate encerrado! Vencedor: $vencedor")),
        );
        Navigator.maybePop(context, 'encerrada');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Desempate"),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.lutadores.map((lutador) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed:
                    (_isSending || _usuarioVotou != null) ? null : () => enviarVoto(lutador),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.blueGrey,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        lutador,
                        style: TextStyle(
                          fontSize: 18,
                          color: _usuarioVotou == lutador
                              ? Colors.lightGreenAccent
                              : Colors.white,
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
