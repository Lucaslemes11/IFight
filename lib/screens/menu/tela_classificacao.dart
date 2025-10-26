import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassificacaoPage extends StatefulWidget {
  const ClassificacaoPage({super.key});

  @override
  State<ClassificacaoPage> createState() => _ClassificacaoPageState();
}

class _ClassificacaoPageState extends State<ClassificacaoPage> {
  final Color bg = const Color(0xFF1B1B1B);
  final Color panel = const Color(0xFF121212);
  final Color accent = Colors.blueGrey;
  final Color accentDark = const Color.fromARGB(255, 80, 75, 0);

  String categoriaSelecionada = 'Todos';

  final List<String> categorias = [
    'Todos',
    'Mosca',
    'Pena',
    'Leve',
    'Meio-médio',
    'Médio',
    'Meio-pesado',
    'Pesado',
    'Superpesado',
  ];

  @override
  Widget build(BuildContext context) {
    final lutadoresRef = FirebaseFirestore.instance.collection('lutadores');
    final historicoRef = FirebaseFirestore.instance.collection('historico');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Classificação'),
        backgroundColor: accent,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: lutadoresRef.get(),
        builder: (context, snapshotLutadores) {
          if (snapshotLutadores.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshotLutadores.hasData || snapshotLutadores.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum lutador cadastrado',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          // 🔹 Mapa de lutadores com nome → categoria e peso
          final lutadoresMap = {
            for (var doc in snapshotLutadores.data!.docs)
              doc['nome'] as String: {
                'categoria': doc['categoria'] ?? 'Sem categoria',
                'peso': doc['peso'] ?? 0,
              }
          };

          return StreamBuilder<QuerySnapshot>(
            stream: historicoRef.snapshots(),
            builder: (context, snapshotHistorico) {
              if (snapshotHistorico.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final Map<String, Map<String, dynamic>> ranking = {};

              for (var doc in snapshotHistorico.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) continue;

                final lutador1 = data['lutador1'] ?? '';
                final lutador2 = data['lutador2'] ?? '';
                final vencedor = data['vencedor'] ?? '';
                final notas = (data['notas'] as Map<String, dynamic>? ?? {})
                    .map((k, v) => MapEntry(k, List<dynamic>.from(v)));

                for (var nome in [lutador1, lutador2]) {
                  if (!lutadoresMap.containsKey(nome)) continue;

                  ranking.putIfAbsent(nome, () => {
                        'vitorias': 0,
                        'vitoriasKO': 0,
                        'derrotas': 0,
                        'categoria': lutadoresMap[nome]!['categoria'],
                        'peso': lutadoresMap[nome]!['peso'],
                      });
                }

                if (vencedor.isNotEmpty &&
                    vencedor != 'Empate' &&
                    lutadoresMap.containsKey(vencedor)) {
                  ranking[vencedor]!['vitorias'] =
                      (ranking[vencedor]!['vitorias'] ?? 0) + 1;

                  bool teveKO = false;
                  if (notas[vencedor] != null) {
                    for (var n in notas[vencedor]!) {
                      if ((n as num) >= 10) {
                        teveKO = true;
                        break;
                      }
                    }
                  }
                  if (teveKO) {
                    ranking[vencedor]!['vitoriasKO'] =
                        (ranking[vencedor]!['vitoriasKO'] ?? 0) + 1;
                  }
                }

                for (var nome in [lutador1, lutador2]) {
                  if (vencedor != nome &&
                      vencedor != 'Empate' &&
                      lutadoresMap.containsKey(nome)) {
                    ranking[nome]!['derrotas'] =
                        (ranking[nome]!['derrotas'] ?? 0) + 1;
                  }
                }
              }

              // 🔹 Filtrar por categoria selecionada
              final lista = ranking.entries
                  .where((e) =>
                      categoriaSelecionada == 'Todos' ||
                      e.value['categoria'] == categoriaSelecionada)
                  .map((e) => {
                        'nome': e.key,
                        'vitorias': e.value['vitorias'],
                        'vitoriasKO': e.value['vitoriasKO'],
                        'derrotas': e.value['derrotas'],
                        'categoria': e.value['categoria'],
                      })
                  .toList();

              lista.sort((a, b) {
                int cmpV = (b['vitorias'] as int).compareTo(a['vitorias'] as int);
                if (cmpV != 0) return cmpV;
                int cmpKO =
                    (b['vitoriasKO'] as int).compareTo(a['vitoriasKO'] as int);
                if (cmpKO != 0) return cmpKO;
                return (a['derrotas'] as int).compareTo(b['derrotas'] as int);
              });

              final int maxVitorias = lista.isEmpty
                  ? 0
                  : lista.map((e) => e['vitorias'] as int).reduce((a, b) => a > b ? a : b);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    _buildHeader(lista.length),
                    const SizedBox(height: 12),
                    // 🔹 Dropdown de categorias
                    Row(
                      children: [
                        const Text('Filtrar por categoria: ',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: categoriaSelecionada,
                          dropdownColor: panel,
                          items: categorias
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              categoriaSelecionada = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final jogador = lista[index];
                          final bool primeiroLugar = index == 0;
                          final double progress = maxVitorias > 0
                              ? (jogador['vitorias'] as int) / maxVitorias
                              : 0.0;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: primeiroLugar
                                        ? [
                                            accentDark.withOpacity(0.9),
                                            panel.withOpacity(0.4)
                                          ]
                                        : [
                                            panel.withOpacity(0.9),
                                            panel.withOpacity(0.8)
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      offset: const Offset(0, 6),
                                      blurRadius: 14,
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: primeiroLugar
                                                ? accent
                                                : Colors.white12,
                                            width: 2),
                                        gradient: primeiroLugar
                                            ? LinearGradient(colors: [
                                                accent.withOpacity(0.9),
                                                accentDark.withOpacity(0.9)
                                              ])
                                            : null,
                                        color: primeiroLugar
                                            ? null
                                            : const Color(0xFF2A2A2A),
                                      ),
                                      alignment: Alignment.center,
                                      child: primeiroLugar
                                          ? const Icon(Icons.emoji_events,
                                              color: Colors.white, size: 26)
                                          : Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jogador['nome'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            jogador['categoria'] as String,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: LinearProgressIndicator(
                                                    value: progress,
                                                    minHeight: 8,
                                                    backgroundColor: Colors.white10,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<Color>(
                                                            primeiroLugar
                                                                ? accent.withOpacity(0.95)
                                                                : accent),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${jogador['vitorias']} vit',
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildStatChip('${jogador['vitoriasKO']}', 'KO'),
                                        const SizedBox(height: 6),
                                        _buildStatChip('${jogador['derrotas']}', 'D',
                                            muted: true),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.leaderboard, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Ranking', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$total atletas',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? Colors.white12 : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
