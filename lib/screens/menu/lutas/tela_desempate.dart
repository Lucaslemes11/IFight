import 'dart:async';

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

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _salaStream;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checarVotoAnterior();
    _salaStream = FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .snapshots();

    _subscription = _salaStream!.listen(_verificarEncerramento);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checarVotoAnterior() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .get();

    if (!snap.exists) return;

    final votos = snap.data()?['desempate']?['votos'] ?? {};

    if (votos is Map && votos.containsKey(usuario.uid)) {
      if (!mounted) return;
      setState(() => _usuarioVotou = votos[usuario.uid]);
    }
  }

  Future<void> enviarVoto(String vencedor) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    if (_usuarioVotou != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você já votou.")),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection("lutas")
          .doc(widget.salaId)
          .update({
        "desempate.votos.${usuario.uid}": vencedor,
      });

      if (mounted) {
        setState(() => _usuarioVotou = vencedor);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voto enviado: $vencedor")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar voto: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verificarEncerramento(
      DocumentSnapshot<Map<String, dynamic>> snap) async {
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null || data['desempate'] == null) return;

    final votos = Map<String, dynamic>.from(data['desempate']['votos'] ?? {});
    final juizes = List<String>.from(data['juizes'] ?? []);

    final todosVotaram = juizes.every((j) => votos.containsKey(j));
    if (!todosVotaram) return;

    // Contagem
    final contagem = <String, int>{};
    votos.values.forEach((v) {
      contagem[v] = (contagem[v] ?? 0) + 1;
    });

    final vencedor =
        contagem.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Notas totais
    final notasSnap = await FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .collection("notas")
        .get();

    final notasTotais = <String, List<double>>{};

    for (var doc in notasSnap.docs) {
      final d = doc.data();
      d.forEach((lutador, valores) {
        if (valores is Iterable) {
          notasTotais[lutador] =
              valores.map((n) => (n as num).toDouble()).toList();
        }
      });
    }

    final totalA = (notasTotais[widget.lutadores[0]] ?? [])
        .fold(0.0, (a, b) => a + b);
    final totalB = (notasTotais[widget.lutadores[1]] ?? [])
        .fold(0.0, (a, b) => a + b);

    // Salva histórico
    await FirebaseFirestore.instance.collection("historico").doc(widget.salaId).set({
      "lutador1": widget.lutadores[0],
      "lutador2": widget.lutadores[1],
      "totalA": totalA,
      "totalB": totalB,
      "vencedor": vencedor,
      "data": DateTime.now(),
      "notas": notasTotais,
      "juizes": juizes,
      "votosDesempate": votos,
      "vencedorDesempate": true,
    });

    // Remove luta
    await FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Desempate encerrado! Vencedor: $vencedor")),
    );

    Navigator.of(context).pop('encerrada');
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
                    (_isSending || _usuarioVotou != null)
                        ? null
                        : () => enviarVoto(lutador),
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
