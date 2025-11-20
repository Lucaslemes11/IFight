import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/score_details.dart' show ScoreDetails;
import 'package:firebase_auth/firebase_auth.dart';

class Historico extends StatefulWidget {
  const Historico({super.key});

  @override
  State<Historico> createState() => _HistoricoState();
}

class _HistoricoState extends State<Historico> {
  String filtroPesquisa = "";

  final Color bg = const Color(0xFF1B1B1B);
  final Color cardBg = const Color.fromARGB(255, 29, 29, 29);
  final Color accent = Colors.blueGrey;

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    else if (raw is DateTime) dt = raw;
    else if (raw is String) dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '';
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    else if (raw is DateTime) dt = raw;
    else if (raw is String) dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('HH:mm').format(dt) : '';
  }

  Map<String, List<double>> _parseNotas(dynamic rawNotas) {
    if (rawNotas is Map) {
      return rawNotas.map((key, value) {
        final list = (value as List?)?.map((e) => (e as num).toDouble()).toList() ?? <double>[];
        return MapEntry(key.toString(), list);
      });
    }
    return {};
  }

  // 🔹 MÉTODO MELHORADO: Buscar nome atual pelo ID - com fallback para nome original
  Future<String> _buscarNomeAtual(String? lutadorId, String nomeOriginal) async {
    if (lutadorId == null || lutadorId.isEmpty) return nomeOriginal;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lutadores')
          .doc(lutadorId)
          .get();
          
      if (doc.exists && doc.data() != null) {
        return doc['nome'] ?? nomeOriginal;
      }
      return nomeOriginal;
    } catch (e) {
      return nomeOriginal;
    }
  }

  // 🔹 MÉTODO MELHORADO: Buscar nome do vencedor atual
  Future<String> _buscarVencedorAtual(Map<String, dynamic> dados) async {
    final vencedorId = dados['vencedorId'];
    final vencedorOriginal = dados['vencedor'] ?? 'Empate';
    
    if (vencedorId == 'Empate') return 'Empate';
    if (vencedorId == null || vencedorId.isEmpty) return vencedorOriginal;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lutadores')
          .doc(vencedorId)
          .get();
          
      if (doc.exists && doc.data() != null) {
        return doc['nome'] ?? vencedorOriginal;
      }
      return vencedorOriginal;
    } catch (e) {
      return vencedorOriginal;
    }
  }

  Future<void> _removerHistorico(String docId) async {
    final senhaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text("Remover Luta", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Digite sua senha para confirmar a remoção desta luta:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Senha",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Remover"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: senhaController.text.trim(),
        );
        try {
          await user.reauthenticateWithCredential(cred);
          await FirebaseFirestore.instance.collection('historico').doc(docId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Luta removida do histórico!")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Senha incorreta!")),
            );
          }
        }
      }
    }
  }

  // ==================== CARD DO HISTÓRICO ATUALIZADO ====================
  Widget _buildHistoricoCard(Map<String, dynamic> dados, String docId) {
    final rawData = dados['data'];
    final data = _formatDate(rawData);
    final hora = _formatTime(rawData);
    final totalA = (dados['totalA'] as num?)?.toDouble() ?? 0.0;
    final totalB = (dados['totalB'] as num?)?.toDouble() ?? 0.0;
    final vencedorKO = dados['vencedorKO'] == true;
    final vencedorDesempate = dados['vencedorDesempate'] == true;
    final votosDesempate = dados['votosDesempate'];

    return FutureBuilder<Map<String, String>>(
      future: _carregarNomesAtuais(dados),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCardEsqueleto();
        }

        final nomes = snapshot.data ?? {};
        final lutador1 = nomes['lutador1'] ?? dados['lutador1'] ?? 'Lutador 1';
        final lutador2 = nomes['lutador2'] ?? dados['lutador2'] ?? 'Lutador 2';
        final vencedor = nomes['vencedor'] ?? dados['vencedor'] ?? 'Empate';

        // 🔹 CORREÇÃO: Usar os nomes ORIGINAIS da luta para buscar as notas
        final lutador1Original = dados['lutador1'] ?? 'Lutador 1';
        final lutador2Original = dados['lutador2'] ?? 'Lutador 2';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreDetails(
                    lutador1: lutador1,
                    lutador2: lutador2,
                    // 🔹 CORREÇÃO CRÍTICA: Usar os nomes ORIGINAIS para buscar as notas
                    notasTotais: _mapearNotasParaNomesAtuais(
                      _parseNotas(dados['notas']),
                      lutador1Original,
                      lutador2Original,
                      lutador1,
                      lutador2,
                    ),
                    vencedor: vencedor,
                    vencedorKO: vencedorKO,
                    vencedorDesempate: vencedorDesempate,
                    votosDesempate: votosDesempate,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  // 🔥 ÍCONE COM COR DO VENCEDOR
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getVencedorColor(vencedor, lutador1, lutador2),
                        width: 2,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _getVencedorColor(vencedor, lutador1, lutador2).withOpacity(0.7),
                          _getVencedorColor(vencedor, lutador1, lutador2).withOpacity(0.3),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      vencedorKO ? Icons.flash_on : 
                      vencedorDesempate ? Icons.gavel : Icons.emoji_events,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 NOMES COM CORES VERMELHO E AZUL
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  lutador1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "VS",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  lutador2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // 🔥 INFORMAÇÕES DA LUTA
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              data,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, color: Colors.white54, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              hora,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // 🔥 VENCEDOR E PONTUAÇÃO
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events, 
                              color: _getVencedorColor(vencedor, lutador1, lutador2),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Vencedor: $vencedor',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _getVencedorColor(vencedor, lutador1, lutador2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (vencedorKO)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Text(
                                  'KO',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (vencedorDesempate)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Text(
                                  'Desempate',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // 🔥 PONTUAÇÃO TOTAL - CORREÇÃO PARA DESEMPATE
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Placar: ',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${totalA.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' - ',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${totalB.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // 🔥 INDICADOR DE PONTUAÇÃO ZERADA EM DESEMPATE
                            if (vencedorDesempate && totalA == 0 && totalB == 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: const Text(
                                    'Sem pontuação',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 🔥 BOTÃO DE DELETAR
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        onPressed: () => _removerHistorico(docId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18, color: Colors.blueGrey),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScoreDetails(
                                lutador1: lutador1,
                                lutador2: lutador2,
                                notasTotais: _mapearNotasParaNomesAtuais(
                                  _parseNotas(dados['notas']),
                                  lutador1Original,
                                  lutador2Original,
                                  lutador1,
                                  lutador2,
                                ),
                                vencedor: vencedor,
                                vencedorKO: vencedorKO,
                                vencedorDesempate: vencedorDesempate,
                                votosDesempate: votosDesempate,
                              ),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔹 MÉTODO CORRIGIDO: Obter cor do vencedor
  Color _getVencedorColor(String vencedor, String lutador1, String lutador2) {
    if (vencedor == 'Empate') return Colors.orange;
    
    // 🔥 CORREÇÃO: Comparação case-insensitive e com trim
    final vencedorNormalizado = vencedor.toLowerCase().trim();
    final lutador1Normalizado = lutador1.toLowerCase().trim();
    final lutador2Normalizado = lutador2.toLowerCase().trim();
    
    if (vencedorNormalizado == lutador1Normalizado) return Colors.red;
    if (vencedorNormalizado == lutador2Normalizado) return Colors.blue;
    
    // 🔥 CORREÇÃO ADICIONAL: Verificar se contém parte do nome
    if (vencedorNormalizado.contains(lutador1Normalizado) || 
        lutador1Normalizado.contains(vencedorNormalizado)) {
      return Colors.red;
    }
    if (vencedorNormalizado.contains(lutador2Normalizado) || 
        lutador2Normalizado.contains(vencedorNormalizado)) {
      return Colors.blue;
    }
    
    return Colors.grey;
  }

  // 🔹 NOVO MÉTODO CRÍTICO: Mapear notas dos nomes antigos para os novos
  Map<String, List<double>> _mapearNotasParaNomesAtuais(
    Map<String, List<double>> notasOriginais,
    String lutador1Original,
    String lutador2Original,
    String lutador1Atual,
    String lutador2Atual,
  ) {
    final notasAtualizadas = <String, List<double>>{};
    
    // Mapeia as notas do lutador 1 original para o nome atual
    if (notasOriginais.containsKey(lutador1Original)) {
      notasAtualizadas[lutador1Atual] = notasOriginais[lutador1Original]!;
    } else if (notasOriginais.containsKey(lutador1Atual)) {
      // Se já está com o nome atual, mantém
      notasAtualizadas[lutador1Atual] = notasOriginais[lutador1Atual]!;
    }
    
    // Mapeia as notas do lutador 2 original para o nome atual
    if (notasOriginais.containsKey(lutador2Original)) {
      notasAtualizadas[lutador2Atual] = notasOriginais[lutador2Original]!;
    } else if (notasOriginais.containsKey(lutador2Atual)) {
      // Se já está com o nome atual, mantém
      notasAtualizadas[lutador2Atual] = notasOriginais[lutador2Atual]!;
    }
    
    // Se não encontrou nenhuma nota, retorna as originais
    if (notasAtualizadas.isEmpty) {
      return notasOriginais;
    }
    
    return notasAtualizadas;
  }

  // 🔹 MÉTODO: Carregar todos os nomes atuais de uma vez
  Future<Map<String, String>> _carregarNomesAtuais(Map<String, dynamic> dados) async {
    final nomes = <String, String>{};
    
    try {
      final lutador1Original = dados['lutador1'] ?? 'Lutador 1';
      final lutador2Original = dados['lutador2'] ?? 'Lutador 2';
      
      // Busca nome do lutador 1
      final lutador1Id = dados['lutador1Id'];
      nomes['lutador1'] = await _buscarNomeAtual(lutador1Id, lutador1Original);
      
      // Busca nome do lutador 2
      final lutador2Id = dados['lutador2Id'];
      nomes['lutador2'] = await _buscarNomeAtual(lutador2Id, lutador2Original);
      
      // Busca nome do vencedor
      nomes['vencedor'] = await _buscarVencedorAtual(dados);
      
    } catch (e) {
      debugPrint('Erro ao carregar nomes atuais: $e');
    }
    
    return nomes;
  }

  // 🔹 MÉTODO: Card de loading
  Widget _buildCardEsqueleto() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white12,
            ),
            child: const Icon(Icons.history, color: Colors.white54, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.delete, size: 20, color: Colors.white30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Histórico de Lutas'),
        backgroundColor: accent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Pesquisar por nome, ID da sala ou vencedor...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) => setState(() => filtroPesquisa = valor.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('historico')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma luta finalizada ainda.',
                      style: TextStyle(color: Colors.white70)
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final idSala = (dados['idSala'] ?? '').toString().toLowerCase();
                  final vencedor = (dados['vencedor'] ?? '').toString().toLowerCase();
                  final lutador1 = (dados['lutador1'] ?? '').toString().trim();
                  final lutador2 = (dados['lutador2'] ?? '').toString().trim();

                  if (lutador1.isEmpty || lutador2.isEmpty) return false;
                  
                  return idSala.contains(filtroPesquisa) || 
                         vencedor.contains(filtroPesquisa) ||
                         lutador1.toLowerCase().contains(filtroPesquisa) ||
                         lutador2.toLowerCase().contains(filtroPesquisa);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma luta encontrada',
                      style: TextStyle(color: Colors.white70)
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lutaDoc = docs[index];
                    final dados = lutaDoc.data() as Map<String, dynamic>;
                    return _buildHistoricoCard(dados, lutaDoc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}