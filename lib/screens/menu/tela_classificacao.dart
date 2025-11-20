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
  String generoSelecionado = 'Geral';

  // 🔥 CATEGORIAS SEPARADAS POR GÊNERO
  final List<String> categoriasMasculino = [
    'Mosca',
    'Pena', 
    'Leve',
    'Meio-médio',
    'Médio',
    'Meio-pesado',
    'Pesado',
    'Superpesado',
  ];

  final List<String> categoriasFeminino = [
    'Palha',
    'Mosca',
    'Galo',
    'Pena',
    'Leve',
    'Meio-médio',
    'Médio',
  ];

  // Lista dinâmica que será atualizada conforme o gênero selecionado
  List<String> get categoriasDisponiveis {
    if (generoSelecionado == 'Feminino') {
      return ['Todos', ...categoriasFeminino];
    } else if (generoSelecionado == 'Masculino') {
      return ['Todos', ...categoriasMasculino];
    } else {
      // Geral - mostra todas as categorias sem duplicatas
      final todasCategorias = {...categoriasMasculino, ...categoriasFeminino};
      return ['Todos', ...todasCategorias.toList()];
    }
  }

  final List<String> generos = [
    'Geral',
    'Masculino',
    'Feminino',
  ];

  // Função auxiliar para acessar campos de forma segura
  dynamic _getFieldSafe(DocumentSnapshot doc, String field, {dynamic defaultValue}) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey(field)) {
      return data[field];
    }
    return defaultValue;
  }

  // Função para extrair a categoria simplificada do campo categoriaPeso
  String _extrairCategoriaSimplificada(String categoriaPeso) {
    if (categoriaPeso.isEmpty || categoriaPeso == 'Sem categoria') {
      return 'Sem categoria';
    }

    // Remove os parênteses e conteúdo dentro deles
    String categoria = categoriaPeso.split('(').first.trim();
    
    // Remove "M" ou "W" no final
    if (categoria.endsWith(' M') || categoria.endsWith(' W')) {
      categoria = categoria.substring(0, categoria.length - 2);
    }
    
    // Remove "Leve" das categorias para simplificar
    categoria = categoria.replaceAll(' Leve', '');
    categoria = categoria.replaceAll('Super', '');
    
    // Mapeia categorias específicas
    if (categoria.contains('Mínimo')) return 'Mosca';
    if (categoria.contains('Galo')) return 'Galo';
    if (categoria.contains('Cruzador')) return 'Pesado';
    
    return categoria.trim();
  }

  @override
  void initState() {
    super.initState();
    categoriaSelecionada = 'Todos';
  }

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

          // 🔹 Mapa de lutadores usando ID como chave - COM ACESSO SEGURO
          final lutadoresMap = {
            for (var doc in snapshotLutadores.data!.docs)
              doc.id: {
                'nome': _getFieldSafe(doc, 'nome', defaultValue: 'Sem nome'),
                'categoriaPeso': _getFieldSafe(doc, 'categoriaPeso', defaultValue: 'Sem categoria'),
                'categoria': _getFieldSafe(doc, 'categoria', defaultValue: 'Sem categoria'), // Tenta o campo categoria primeiro
                'genero': _getFieldSafe(doc, 'genero', defaultValue: 'Masculino'),
                'peso': _getFieldSafe(doc, 'peso', defaultValue: 0),
                'fotoBase64': _getFieldSafe(doc, 'fotoBase64', defaultValue: ''),
                'lutadorId': doc.id,
              }
          };

          return StreamBuilder<QuerySnapshot>(
            stream: historicoRef.snapshots(),
            builder: (context, snapshotHistorico) {
              if (snapshotHistorico.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshotHistorico.hasData) {
                return const Center(
                  child: Text(
                    'Nenhum histórico encontrado',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final Map<String, Map<String, dynamic>> ranking = {};

              for (var doc in snapshotHistorico.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) continue;

                final lutador1Id = data['lutador1Id'] ?? '';
                final lutador2Id = data['lutador2Id'] ?? '';
                final vencedorId = data['vencedorId'] ?? '';
                final bool vencedorKO = data['vencedorKO'] == true;

                // Processa ambos os lutadores usando IDs
                for (var lutadorId in [lutador1Id, lutador2Id]) {
                  if (lutadorId.isEmpty || !lutadoresMap.containsKey(lutadorId)) continue;

                  ranking.putIfAbsent(lutadorId, () {
                    final info = lutadoresMap[lutadorId]!;
                    
                    // 🔥 CORREÇÃO: Usa categoriaPeso se categoria não existir
                    String categoria = info['categoria'] ?? 'Sem categoria';
                    if (categoria == 'Sem categoria' && info['categoriaPeso'] != 'Sem categoria') {
                      categoria = _extrairCategoriaSimplificada(info['categoriaPeso']);
                    }

                    return {
                      'nome': info['nome'],
                      'vitorias': 0,
                      'vitoriasKO': 0,
                      'derrotas': 0,
                      'categoria': categoria,
                      'genero': info['genero'],
                      'peso': info['peso'],
                      'fotoBase64': info['fotoBase64'],
                      'lutadorId': lutadorId,
                    };
                  });
                }

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
                  }
                }
              }

              // 🔹 Filtrar por categoria E gênero
              final lista = ranking.entries
                  .where((e) {
                    // Filtro por categoria
                    final categoriaMatch = categoriaSelecionada == 'Todos' ||
                        e.value['categoria'] == categoriaSelecionada;
                    
                    // Filtro por gênero
                    final generoMatch = generoSelecionado == 'Geral' ||
                        e.value['genero'] == generoSelecionado;
                    
                    return categoriaMatch && generoMatch;
                  })
                  .map((e) => {
                        'lutadorId': e.key,
                        'nome': e.value['nome'],
                        'vitorias': e.value['vitorias'] ?? 0,
                        'vitoriasKO': e.value['vitoriasKO'] ?? 0,
                        'derrotas': e.value['derrotas'] ?? 0,
                        'categoria': e.value['categoria'] ?? 'Sem categoria',
                        'genero': e.value['genero'] ?? 'Masculino',
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
                    
                    // 🔹 FILTROS - CATEGORIA E GÊNERO
                    Row(
                      children: [
                        // Filtro de Gênero
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gênero:',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: panel,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: DropdownButton<String>(
                                value: generoSelecionado,
                                dropdownColor: panel,
                                underline: const SizedBox(),
                                items: generos
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(
                                          g,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    generoSelecionado = value!;
                                    // Reseta a categoria quando muda o gênero
                                    categoriaSelecionada = 'Todos';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Filtro de Categoria
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Categoria:',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: panel,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: DropdownButton<String>(
                                  value: categoriaSelecionada,
                                  dropdownColor: panel,
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                  items: categoriasDisponiveis
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 🔥 INDICADOR DE CATEGORIAS DISPONÍVEIS
                    if (generoSelecionado != 'Geral')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          generoSelecionado == 'Masculino' 
                            ? 'Categorias Masculinas' 
                            : 'Categorias Femininas',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // 🔹 INDICADORES DE FILTRO ATIVO
                    if (categoriaSelecionada != 'Todos' || generoSelecionado != 'Geral')
                      Row(
                        children: [
                          if (generoSelecionado != 'Geral')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    generoSelecionado == 'Feminino' 
                                      ? Icons.female 
                                      : Icons.male,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    generoSelecionado,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        generoSelecionado = 'Geral';
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (categoriaSelecionada != 'Todos') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoriaSelecionada,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        categoriaSelecionada = 'Todos';
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Botão para limpar todos os filtros
                          if (categoriaSelecionada != 'Todos' || generoSelecionado != 'Geral')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  categoriaSelecionada = 'Todos';
                                  generoSelecionado = 'Geral';
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: const Text(
                                'Limpar filtros',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: lista.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    generoSelecionado == 'Feminino' 
                                      ? Icons.female 
                                      : Icons.male,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    generoSelecionado == 'Geral'
                                      ? 'Nenhum lutador encontrado'
                                      : 'Nenhum lutador ${generoSelecionado.toLowerCase()} encontrado',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    categoriaSelecionada != 'Todos'
                                      ? 'Na categoria $categoriaSelecionada'
                                      : 'Tente ajustar os filtros',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
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
                                  } catch (_) {
                                    // Ignora erro de decode
                                  }
                                }

                                // Ícone de gênero
                                final IconData genderIcon = jogador['genero'] == 'Feminino' 
                                    ? Icons.female 
                                    : Icons.male;
                                final Color genderColor = jogador['genero'] == 'Feminino'
                                    ? Colors.pink
                                    : Colors.blue;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      // Agora você tem acesso ao jogador['lutadorId'] para ações futuras
                                    },
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
                                                ? Icon(Icons.emoji_events,
                                                    color: genderColor, size: 24)
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
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: Colors.white12,
                                                backgroundImage: fotoProvider,
                                                child: fotoProvider == null
                                                    ? Icon(Icons.person,
                                                        color: genderColor.withOpacity(0.7),
                                                        size: 22)
                                                    : null,
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: genderColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: panel,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    genderIcon,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: genderColor.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: genderColor.withOpacity(0.5)),
                                                      ),
                                                      child: Text(
                                                        jogador['categoria'] as String,
                                                        style: TextStyle(
                                                          color: genderColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      genderIcon,
                                                      size: 12,
                                                      color: genderColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      jogador['genero'] as String,
                                                      style: TextStyle(
                                                        color: genderColor,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
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
                                                            genderColor,
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
                                                  '${jogador['vitoriasKO']}', 'KO', color: genderColor),
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
        
        // Indicador de filtro ativo
        if (generoSelecionado != 'Geral' || categoriaSelecionada != 'Todos')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt, 
                  size: 12, 
                  color: generoSelecionado == 'Feminino' 
                    ? Colors.pink 
                    : generoSelecionado == 'Masculino'
                      ? Colors.blue
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  'Filtrado',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, {bool muted = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? Colors.white12 : (color?.withOpacity(0.2) ?? Colors.white10),
        borderRadius: BorderRadius.circular(8),
        border: color != null && !muted ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: muted ? Colors.white70 : (color ?? Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: muted ? Colors.white54 : (color?.withOpacity(0.8) ?? Colors.white70), 
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}