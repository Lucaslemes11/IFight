import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassificacaoPage extends StatefulWidget {
  const ClassificacaoPage({super.key});

  @override
  State<ClassificacaoPage> createState() => _ClassificacaoPageState();
}

class _ClassificacaoPageState extends State<ClassificacaoPage> {
  final Color bg = const Color(0xFF1B1B1B);
  final Color panel = const Color(0xFF1B1B1B);
  final Color accent = Colors.blueGrey;
  final Color accentDark = const Color(0xFF1B1B1B);

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

          if (!snapshotLutadores.hasData ||
              snapshotLutadores.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum lutador cadastrado',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

<<<<<<< HEAD
          // 🔹 Mapa de lutadores usando ID como chave
          final lutadoresMap = {
            for (var doc in snapshotLutadores.data!.docs)
              doc.id: {
                'nome': doc['nome'] as String,
                'categoria': doc['categoria'] ?? 'Sem categoria',
                'peso': doc['peso'] ?? 0,
                'fotoBase64': doc['fotoBase64'],
                'lutadorId': doc.id, // ID do documento
=======
          // 🔹 Mapa de lutadores com dados básicos
          final lutadoresMap = {
            for (var doc in snapshotLutadores.data!.docs)
              doc['nome'] as String: {
                'categoria': doc['categoria'] ?? 'Sem categoria',
                'peso': doc['peso'] ?? 0,
                'fotoBase64': doc['fotoBase64'],
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
              }
          };

          return StreamBuilder<QuerySnapshot>(
            stream: historicoRef.snapshots(),
            builder: (context, snapshotHistorico) {
              if (snapshotHistorico.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final Map<String, Map<String, dynamic>> ranking = {};

              for (var doc in snapshotHistorico.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) continue;

<<<<<<< HEAD
                // 🔹 AGORA USAMOS OS IDs EM VEZ DOS NOMES
                final lutador1Id = data['lutador1Id'] ?? '';
                final lutador2Id = data['lutador2Id'] ?? '';
                final vencedorId = data['vencedorId'] ?? '';
                final bool vencedorKO = data['vencedorKO'] == true;

                // Processa ambos os lutadores usando IDs
                for (var lutadorId in [lutador1Id, lutador2Id]) {
                  if (lutadorId.isEmpty || !lutadoresMap.containsKey(lutadorId)) continue;

                  ranking.putIfAbsent(lutadorId, () {
                    final info = lutadoresMap[lutadorId]!;
                    return {
                      'nome': info['nome'],
=======
                final lutador1 = data['lutador1'] ?? '';
                final lutador2 = data['lutador2'] ?? '';
                final vencedor = data['vencedor'] ?? '';
                final bool vencedorKO = data['vencedorKO'] == true;

                for (var nome in [lutador1, lutador2]) {
                  if (!lutadoresMap.containsKey(nome)) continue;

                  ranking.putIfAbsent(nome, () {
                    final info = lutadoresMap[nome]!;
                    return {
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
                      'vitorias': 0,
                      'vitoriasKO': 0,
                      'derrotas': 0,
                      'categoria': info['categoria'],
                      'peso': info['peso'],
                      'fotoBase64': info['fotoBase64'],
<<<<<<< HEAD
                      'lutadorId': lutadorId, // Mantém o ID para referência
=======
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
                    };
                  });
                }

<<<<<<< HEAD
                // Atualiza vitórias usando ID
                if (vencedorId.isNotEmpty && 
                    vencedorId != 'Empate' && 
                    lutadoresMap.containsKey(vencedorId)) {
                  ranking[vencedorId]!['vitorias'] =
                      (ranking[vencedorId]!['vitorias'] ?? 0) + 1;

                  if (vencedorKO) {
                    ranking[vencedorId]!['vitoriasKO'] =
                        (ranking[vencedorId]!['vitoriasKO'] ?? 0) + 1;
                  }
                }

                // Atualiza derrotas usando ID
                for (var lutadorId in [lutador1Id, lutador2Id]) {
                  if (lutadorId.isNotEmpty &&
                      vencedorId != lutadorId &&
                      vencedorId != 'Empate' && 
                      lutadoresMap.containsKey(lutadorId)) {
                    ranking[lutadorId]!['derrotas'] =
                        (ranking[lutadorId]!['derrotas'] ?? 0) + 1;
=======
                if (vencedor.isNotEmpty &&
                    vencedor != 'Empate' &&
                    lutadoresMap.containsKey(vencedor)) {
                  ranking[vencedor]!['vitorias'] =
                      (ranking[vencedor]!['vitorias'] ?? 0) + 1;

                  if (vencedorKO) {
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
                  }
                }
              }

              // 🔹 Filtrar por categoria
              final lista = ranking.entries
                  .where((e) =>
                      categoriaSelecionada == 'Todos' ||
                      e.value['categoria'] == categoriaSelecionada)
                  .map((e) => {
<<<<<<< HEAD
                        'lutadorId': e.key, // ID para referência
                        'nome': e.value['nome'],
=======
                        'nome': e.key,
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
                        'vitorias': e.value['vitorias'],
                        'vitoriasKO': e.value['vitoriasKO'],
                        'derrotas': e.value['derrotas'],
                        'categoria': e.value['categoria'],
                        'fotoBase64': e.value['fotoBase64'],
                      })
                  .toList();

              lista.sort((a, b) {
                int cmpV =
                    (b['vitorias'] as int).compareTo(a['vitorias'] as int);
                if (cmpV != 0) return cmpV;
                int cmpKO = (b['vitoriasKO'] as int)
                    .compareTo(a['vitoriasKO'] as int);
                if (cmpKO != 0) return cmpKO;
                return (a['derrotas'] as int)
                    .compareTo(b['derrotas'] as int);
              });

              final int maxVitorias = lista.isEmpty
                  ? 0
                  : lista
                      .map((e) => e['vitorias'] as int)
                      .reduce((a, b) => a > b ? a : b);

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    _buildHeader(lista.length),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Filtrar por categoria: ',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: categoriaSelecionada,
                          dropdownColor: panel,
                          items: categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                              )
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final jogador = lista[index];
                          final bool primeiroLugar = index == 0;
                          final double progress = maxVitorias > 0
                              ? (jogador['vitorias'] as int) / maxVitorias
                              : 0.0;

                          final fotoBase64 = jogador['fotoBase64'] as String?;
                          ImageProvider? fotoProvider;
                          if (fotoBase64 != null &&
                              fotoBase64.isNotEmpty) {
                            try {
                              fotoProvider = MemoryImage(
                                  base64Decode(fotoBase64));
                            } catch (_) {}
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
<<<<<<< HEAD
                              onTap: () {
                                // Agora você tem acesso ao jogador['lutadorId'] para ações futuras
                              },
=======
                              onTap: () {},
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
                                    // 🏆 posição
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: primeiroLugar
                                              ? accent
                                              : Colors.white12,
                                          width: 2,
                                        ),
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
                                              color: Colors.white, size: 24)
                                          : Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                    ),

                                    const SizedBox(width: 10),

                                    // 📷 foto do lutador
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white12,
                                      backgroundImage: fotoProvider,
                                      child: fotoProvider == null
                                          ? const Icon(Icons.person,
                                              color: Colors.white54,
                                              size: 22)
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // 🔹 informações
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: progress,
                                                    minHeight: 8,
                                                    backgroundColor:
                                                        Colors.white10,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      primeiroLugar
                                                          ? accent
                                                              .withOpacity(0.95)
                                                          : accent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${jogador['vitorias']} vit',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildStatChip(
                                            '${jogador['vitoriasKO']}', 'KO'),
                                        const SizedBox(height: 6),
                                        _buildStatChip(
                                          '${jogador['derrotas']}',
                                          'D',
                                          muted: true,
                                        ),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
