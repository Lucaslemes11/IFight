import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_desempate.dart';


class TelaNotas extends StatefulWidget {
  final String salaId; // id da luta no Firestore

  const TelaNotas({super.key, required this.salaId});

  @override
  State<TelaNotas> createState() => _TelaNotasState();
}

class _TelaNotasState extends State<TelaNotas> {
  List<String> lutadores = [];
  Map<String, List<double>> notasPorRound = {};
  int roundAtual = 0;
  bool _loading = true;
  bool _isSending = false;
  bool _notaEnviada = false; // impede múltiplos envios
  bool _navegouDesempate = false; // evita abrir duas vezes
  User? usuarioLogado;

  @override
  void initState() {
    super.initState();
    usuarioLogado = FirebaseAuth.instance.currentUser;

    if (widget.salaId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnack('ID da sala inválido!', error: true);
        Navigator.pop(context);
      });
      return;
    }

    _carregarDadosSala();
    _ouvirSala();
  }

  Future<void> _carregarDadosSala() async {
    try {
      final salaDoc = await FirebaseFirestore.instance
          .collection('lutas')
          .doc(widget.salaId)
          .get();

      if (!salaDoc.exists) {
        _showSnack('Sala não encontrada', error: true);
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = salaDoc.data()!;
      final lutador1 = data['lutador1'] ?? 'Lutador 1';
      final lutador2 = data['lutador2'] ?? 'Lutador 2';

      // verifica se o juiz já enviou as notas
      if (usuarioLogado != null) {
        final notasRef = await salaDoc.reference
            .collection('notas')
            .doc(usuarioLogado!.uid)
            .get();
        if (notasRef.exists) _notaEnviada = true;
      }

      if (!mounted) return;
      setState(() {
        lutadores = [lutador1, lutador2];
        notasPorRound = {
          lutador1: [7.0, 7.0, 7.0],
          lutador2: [7.0, 7.0, 7.0],
        };
        _loading = false;
      });
    } catch (e) {
      _showSnack('Erro ao carregar sala: $e', error: true);
      if (mounted) Navigator.pop(context);
    }
  }

  /// 🔥 Escuta alterações da sala: finalização ou desempate
  void _ouvirSala() {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    FirebaseFirestore.instance
        .collection('lutas')
        .doc(widget.salaId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final dados = snapshot.data();
      if (dados == null) return;

      // 1️⃣ Desempate
      final desempate = dados['desempate'];
      if (!_navegouDesempate &&
          desempate != null &&
          desempate['open'] == true &&
          !(desempate['votos'] ?? {}).containsKey(usuario.uid)) {
        _navegouDesempate = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TelaDesempate(
                salaId: widget.salaId,
                lutadores: [desempate['lutadorA'], desempate['lutadorB']],
              ),
            ),
          );
        });
        return;
      }

      // 2️⃣ Luta finalizada sem desempate
      if (dados['finalizada'] == true && !_navegouDesempate) {
        _navegouDesempate = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pop(context, 'luta_finalizada');
        });
      }
    });
  }

  void _showSnack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.redAccent : Colors.blueGrey,
      ),
    );
  }

  Future<void> enviarNotas() async {
    if (_notaEnviada || usuarioLogado == null || lutadores.isEmpty) return;

    final Map<String, List<double>> notasParaSalvar = {};
    notasPorRound.forEach((key, list) {
      notasParaSalvar[key] =
          list.map((v) => double.parse(v.toStringAsFixed(1))).toList();
    });

    try {
      setState(() => _isSending = true);
      final docRef = FirebaseFirestore.instance
          .collection("lutas")
          .doc(widget.salaId)
          .collection("notas")
          .doc(usuarioLogado!.uid);

      final existing = await docRef.get();
      if (!existing.exists) {
        await docRef.set({
          "juiz": usuarioLogado!.email ?? "desconhecido",
          "juizId": usuarioLogado!.uid,
          "notas": notasParaSalvar,
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      setState(() => _notaEnviada = true);
      _showSnack("Notas enviadas com sucesso!");
    } catch (e) {
      _showSnack("Erro ao enviar notas: $e", error: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 27, 27),
        appBar: AppBar(
          title: Text("Lançar Notas - Round ${roundAtual + 1}"),
          backgroundColor: Colors.black87,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: lutadores.map((lutador) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lutador,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    min: 7,
                    max: 10,
                    divisions: 3,
                    value: notasPorRound[lutador]![roundAtual],
                    label: notasPorRound[lutador]![roundAtual].toStringAsFixed(1),
                    activeColor: Colors.blueGrey,
                    inactiveColor: Colors.grey,
                    onChanged: _notaEnviada
                        ? null
                        : (value) {
                            setState(() {
                              notasPorRound[lutador]![roundAtual] =
                                  value.roundToDouble();
                            });
                          },
                  ),
                  Text(
                    "Nota: ${notasPorRound[lutador]![roundAtual].toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: roundAtual > 0 ? () => setState(() => roundAtual--) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Anterior"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : roundAtual < 2
                            ? () => setState(() => roundAtual++)
                            : (_notaEnviada ? null : enviarNotas),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _notaEnviada ? Colors.grey : Colors.blueGrey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(roundAtual < 2 ? "Próximo" : (_notaEnviada ? "Notas enviadas" : "Enviar")),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
