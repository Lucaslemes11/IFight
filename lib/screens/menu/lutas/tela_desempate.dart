import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaDesempate extends StatefulWidget {
  final String salaId;
  final List<String> lutadores;
  final double totalA;
  final double totalB;
  final Map<String, List<double>> notas;

  const TelaDesempate({
    super.key,
    required this.salaId,
    required this.lutadores,
    required this.totalA,
    required this.totalB,
    required this.notas,
  });

  @override
  State<TelaDesempate> createState() => _TelaDesempateState();
}

class _TelaDesempateState extends State<TelaDesempate> {
  bool _isSending = false;
  String? _usuarioVotou;
  bool _encerramentoEmAndamento = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _salaStream;
  StreamSubscription? _subscription;

  // 🔥 CORES DOS LUTADORES
  final List<Color> _coresLutadores = [Colors.red, Colors.blue];

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
          SnackBar(
            content: Text("Voto enviado: $vencedor"),
            backgroundColor: _getCorLutador(vencedor),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao enviar voto"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // 🔥 MÉTODO: Obter cor do lutador
  Color _getCorLutador(String lutador) {
    final index = widget.lutadores.indexOf(lutador);
    return index >= 0 && index < _coresLutadores.length 
        ? _coresLutadores[index] 
        : Colors.grey;
  }

  Future<void> _verificarEncerramento(
      DocumentSnapshot<Map<String, dynamic>> snap) async {
    if (!snap.exists) return;

    // 🔥 CORREÇÃO: Evitar múltiplos encerramentos simultâneos
    if (_encerramentoEmAndamento) return;
    
    final data = snap.data();
    if (data == null || data['desempate'] == null) return;

    final votos = Map<String, dynamic>.from(data['desempate']['votos'] ?? {});
    final juizes = List<String>.from(data['juizes'] ?? []);

    final todosVotaram = juizes.every((j) => votos.containsKey(j));
    if (!todosVotaram) return;

    // 🔥 CORREÇÃO: Marcar que o encerramento está em andamento
    _encerramentoEmAndamento = true;

    // Contagem dos votos
    final contagem = <String, int>{};
    votos.values.forEach((v) {
      contagem[v] = (contagem[v] ?? 0) + 1;
    });

    final vencedor =
        contagem.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // 🔥 CORREÇÃO CRÍTICA: Usar APENAS os dados que vieram como parâmetro
    // NÃO fazer nenhum cálculo adicional ou fallback
    final totalA = widget.totalA;
    final totalB = widget.totalB;
    final notasTotais = widget.notas;

    debugPrint('🎯 Dados recebidos como parâmetro:');
    debugPrint('📊 TotalA: $totalA');
    debugPrint('📊 TotalB: $totalB');
    debugPrint('📋 Notas: $notasTotais');

    // 🔥 CORREÇÃO: Salvar também os IDs dos lutadores para busca futura
    final lutador1Id = data['lutador1Id'];
    final lutador2Id = data['lutador2Id'];
    final vencedorId = vencedor == widget.lutadores[0] ? lutador1Id : 
                      vencedor == widget.lutadores[1] ? lutador2Id : null;

    // 🔥 CORREÇÃO: Salvar no histórico com os dados EXATOS que vieram
    await FirebaseFirestore.instance.collection("historico").doc(widget.salaId).set({
      "idSala": widget.salaId,
      "lutador1": widget.lutadores[0],
      "lutador2": widget.lutadores[1],
      "lutador1Id": lutador1Id,
      "lutador2Id": lutador2Id,
      "totalA": totalA, // USA EXATAMENTE o valor recebido
      "totalB": totalB, // USA EXATAMENTE o valor recebido
      "vencedor": vencedor,
      "vencedorId": vencedorId,
      "data": DateTime.now(),
      "notas": notasTotais, // USA EXATAMENTE as notas recebidas
      "juizes": juizes,
      "votosDesempate": votos,
      "vencedorDesempate": true,
      "vencedorKO": false,
    });

    debugPrint('✅ Histórico salvo com os dados reais da luta!');

    // Remove luta
    await FirebaseFirestore.instance
        .collection("lutas")
        .doc(widget.salaId)
        .delete();

    if (!mounted) return;

    // 🔥 CORREÇÃO: Usar um delay e Navigator.of(context).pop() seguro
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Desempate encerrado! Vencedor: $vencedor"),
          backgroundColor: _getCorLutador(vencedor),
          duration: const Duration(seconds: 3),
        ),
      );

      // 🔥 CORREÇÃO CRÍTICA: Navegação segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop('encerrada');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Desempate"),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: const Color(0xFF1B1B1B),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔥 HEADER INFORMATIVO
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  const Icon(
                    Icons.gavel,
                    size: 40,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "VOTO DE DESEMPATE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Empate detectado! Juízes devem votar no vencedor.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 🔥 MOSTRAR PONTUAÇÃO ATUAL REAL
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pontuação: ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${widget.totalA.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' - ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${widget.totalB.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Empate técnico - Voto de minerva',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_usuarioVotou != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        "Você já votou",
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 BOTÕES DE VOTO COM CORES
            Column(
              children: widget.lutadores.asMap().entries.map((entry) {
                final index = entry.key;
                final lutador = entry.value;
                final corLutador = _coresLutadores[index];
                final usuarioJaVotouNeste = _usuarioVotou == lutador;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: (_isSending || _usuarioVotou != null)
                          ? null
                          : () => enviarVoto(lutador),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: usuarioJaVotouNeste
                              ? corLutador.withOpacity(0.3)
                              : const Color.fromARGB(255, 29, 29, 29),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: usuarioJaVotouNeste
                                ? corLutador
                                : Colors.white12,
                            width: usuarioJaVotouNeste ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                lutador,
                                style: TextStyle(
                                  color: usuarioJaVotouNeste
                                      ? corLutador
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isSending && _usuarioVotou == null)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: corLutador,
                                ),
                              )
                            else if (usuarioJaVotouNeste)
                              Icon(
                                Icons.check_circle,
                                color: corLutador,
                                size: 24,
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: corLutador.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "VOTAR",
                                  style: TextStyle(
                                    color: corLutador,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 🔥 STATUS DO VOTO
            if (_usuarioVotou != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCorLutador(_usuarioVotou!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCorLutador(_usuarioVotou!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.how_to_vote,
                      color: _getCorLutador(_usuarioVotou!),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Seu voto: $_usuarioVotou",
                      style: TextStyle(
                        color: _getCorLutador(_usuarioVotou!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}