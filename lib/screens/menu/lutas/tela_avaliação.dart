// Código completo reescrito conforme solicitado
// Slider agora inicia no valor 10, em ordem decrescente (10, 9, 8, 7)
// O knob do slider começa à direita
// Mantida a estrutura geral, apenas corrigido e reorganizado

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_desempate.dart';

class TelaNotas extends StatefulWidget {
  final String salaId;

  const TelaNotas({super.key, required this.salaId});

  @override
  State<TelaNotas> createState() => _TelaNotasState();
}

class _LutadorLocal {
  final String? id;
  final String nome;
  final String? fotoBase64;

  _LutadorLocal({this.id, required this.nome, this.fotoBase64});
}

class _TelaNotasState extends State<TelaNotas> {
  List<_LutadorLocal> lutadores = [];
  Map<String, List<double>> notasPorRound = {};
  int roundAtual = 0;
  bool _loading = true;
  bool _isSending = false;
  bool _notaEnviada = false;
  bool _navegouDesempate = false;
  User? usuarioLogado;

  final Color bg = const Color(0xFF1B1B1B);
  final Color cardBg = const Color.fromARGB(255, 29, 29, 29);
  final Color accent = Colors.blueGrey;

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

  Future<_LutadorLocal> _carregarLutadorFromField(String fieldValue) async {
    try {
      if (fieldValue.isEmpty) {
        return _LutadorLocal(id: null, nome: "Lutador", fotoBase64: null);
      }

      final doc = await FirebaseFirestore.instance
          .collection('lutadores')
          .doc(fieldValue)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return _LutadorLocal(
          id: doc.id,
          nome: (data['nome'] ?? fieldValue).toString(),
          fotoBase64: data['fotoBase64'] as String?,
        );
      }

      final query = await FirebaseFirestore.instance
          .collection('lutadores')
          .where('nome', isEqualTo: fieldValue)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return _LutadorLocal(
          id: query.docs.first.id,
          nome: (data['nome'] ?? fieldValue).toString(),
          fotoBase64: data['fotoBase64'] as String?,
        );
      }

      return _LutadorLocal(id: null, nome: fieldValue, fotoBase64: null);
    } catch (_) {
      return _LutadorLocal(id: null, nome: fieldValue, fotoBase64: null);
    }
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
      final rawL1 = (data['lutador1'] ?? 'Lutador 1').toString();
      final rawL2 = (data['lutador2'] ?? 'Lutador 2').toString();

      if (usuarioLogado != null) {
        final notasRef = await salaDoc.reference
            .collection('notas')
            .doc(usuarioLogado!.uid)
            .get();
        if (notasRef.exists) _notaEnviada = true;
      }

      final lut1 = await _carregarLutadorFromField(rawL1);
      final lut2 = await _carregarLutadorFromField(rawL2);

      if (!mounted) return;
      setState(() {
        lutadores = [lut1, lut2];

        // agora iniciando em 10 (slider começa na direita)
        notasPorRound = {
          lutadores[0].nome: [10.0, 10.0, 10.0],
          lutadores[1].nome: [10.0, 10.0, 10.0],
        };

        _loading = false;
      });
    } catch (e) {
      _showSnack('Erro ao carregar sala: $e', error: true);
      if (mounted) Navigator.pop(context);
    }
  }

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

          final desempate = dados['desempate'];
          if (!_navegouDesempate &&
              desempate != null &&
              desempate['open'] == true &&
              !(desempate['votos'] ?? {}).containsKey(usuario.uid)) {
            _navegouDesempate = true;
            
            // 🔥 CALCULAR NOTAS TOTAIS ANTES DE IR PARA O DESEMPATE
            final notasTotais = _calcularNotasTotais();
            final totalA = _calcularTotalLutador(lutadores[0].nome, notasTotais);
            final totalB = _calcularTotalLutador(lutadores[1].nome, notasTotais);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaDesempate(
                    salaId: widget.salaId,
                    lutadores: [lutadores[0].nome, lutadores[1].nome],
                    totalA: totalA,
                    totalB: totalB,
                    notas: notasTotais,
                  ),
                ),
              );
            });
            return;
          }

          if (dados['finalizada'] == true && !_navegouDesempate) {
            _navegouDesempate = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pop(context, 'luta_finalizada');
            });
          }
        });
  }

  // 🔥 MÉTODO: Calcular notas totais
  Map<String, List<double>> _calcularNotasTotais() {
    final notasTotais = <String, List<double>>{};
    
    for (var lutador in lutadores) {
      notasTotais[lutador.nome] = List.from(notasPorRound[lutador.nome]!);
    }
    
    return notasTotais;
  }

  // 🔥 MÉTODO: Calcular total de um lutador
  double _calcularTotalLutador(String nomeLutador, Map<String, List<double>> notas) {
    final notasLutador = notas[nomeLutador];
    if (notasLutador == null || notasLutador.isEmpty) return 0.0;
    return notasLutador.reduce((a, b) => a + b);
  }

  // 🔥 MÉTODO: Verificar se há pelo menos uma nota 10 em todos os rounds
  bool _validarNota10Obrigatoria() {
    for (int round = 0; round < 3; round++) {
      bool temNota10 = false;
      
      for (var lutador in lutadores) {
        if (notasPorRound[lutador.nome]![round] == 10.0) {
          temNota10 = true;
          break;
        }
      }
      
      if (!temNota10) {
        return false;
      }
    }
    
    return true;
  }

  void _showSnack(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 100, // Espaço suficiente para não cobrir os botões
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> enviarNotas() async {
    if (_notaEnviada || usuarioLogado == null || lutadores.isEmpty) return;

    // 🔥 VALIDAÇÃO: Verificar se há pelo menos uma nota 10 em todos os rounds
    if (!_validarNota10Obrigatoria()) {
      _showSnack("ERRO: Pelo menos um lutador deve ter nota 10 em cada round!", error: true);
      return;
    }

    final Map<String, List<double>> notasParaSalvar = {};
    notasPorRound.forEach((key, list) {
      notasParaSalvar[key] = list
          .map((v) => double.parse(v.toStringAsFixed(1)))
          .toList();
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

  Widget _avatarForLutador(_LutadorLocal l, double radius) {
    if (l.fotoBase64 != null && l.fotoBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(l.fotoBase64!);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.transparent,
        );
      } catch (_) {}
    }

    final parts = l.nome.trim().split(' ');
    String initials = '';
    if (parts.isNotEmpty) initials += parts[0][0].toUpperCase();
    if (parts.length > 1) initials += parts[1][0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueGrey.withOpacity(0.2),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLutadorCard(_LutadorLocal lutadorLocal) {
    final notaAtual = notasPorRound[lutadorLocal.nome]![roundAtual];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
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
            children: [
              _avatarForLutador(lutadorLocal, 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lutadorLocal.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // 🔥 INDICADOR DE NOTA 10
              if (notaAtual == 10.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    "10!",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 7,
                  max: 10,
                  divisions: 3, // 10, 9, 8, 7
                  value: notaAtual,
                  label: notaAtual.toStringAsFixed(0),
                  activeColor: _notaEnviada ? Colors.grey : Colors.blueGrey,
                  inactiveColor: Colors.grey[700],
                  onChanged: _notaEnviada
                      ? null
                      : (value) {
                          setState(() {
                            notasPorRound[lutadorLocal.nome]![roundAtual] =
                                value.roundToDouble();
                          });
                        },
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text(
                    "Nota:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      notaAtual.toStringAsFixed(0),
                      style: TextStyle(
                        color: notaAtual == 10.0 ? Colors.green : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIndicator() {
    // 🔥 VERIFICAR SE ESTE ROUND TEM NOTA 10
    bool roundTemNota10 = false;
    for (var lutador in lutadores) {
      if (notasPorRound[lutador.nome]![roundAtual] == 10.0) {
        roundTemNota10 = true;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: roundTemNota10 ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roundTemNota10 ? Icons.check_circle : Icons.warning,
            color: roundTemNota10 ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            "Round ${roundAtual + 1}/3",
            style: TextStyle(
              color: roundTemNota10 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (!roundTemNota10) ...[
            const SizedBox(width: 8),
            const Text(
              "(Precisa de uma nota 10)",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    // 🔥 VERIFICAR SE PODE AVANÇAR (tem nota 10 no round atual)
    bool podeAvancar = true;
    for (var lutador in lutadores) {
      if (notasPorRound[lutador.nome]![roundAtual] == 10.0) {
        podeAvancar = true;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: roundAtual > 0
                  ? () => setState(() => roundAtual--)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: roundAtual > 0 ? accent : Colors.grey[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text("Anterior"),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSending
                  ? null
                  : roundAtual < 2
                  ? (podeAvancar ? () => setState(() => roundAtual++) : null)
                  : (_notaEnviada ? null : enviarNotas),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notaEnviada
                    ? Colors.grey
                    : roundAtual < 2
                    ? (podeAvancar ? accent : Colors.orange)
                    : Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (roundAtual < 2) ...[
                          Text(podeAvancar ? "Próximo" : "Precisa de 10"),
                          const SizedBox(width: 8),
                          Icon(podeAvancar ? Icons.arrow_forward : Icons.warning, size: 18),
                        ] else if (_notaEnviada) ...[
                          const Icon(Icons.check_circle, size: 18),
                          const SizedBox(width: 8),
                          const Text("Enviadas"),
                        ] else ...[
                          const Icon(Icons.send, size: 18),
                          const SizedBox(width: 8),
                          const Text("Enviar Notas"),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueGrey),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Avaliação da Luta"),
        backgroundColor: accent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildRoundIndicator(),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueGrey, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Avalie cada lutador de 7 a 10 por round. Pelo menos UM lutador deve ter nota 10 em cada round!",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: lutadores.map(_buildLutadorCard).toList(),
              ),
            ),

            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }
}