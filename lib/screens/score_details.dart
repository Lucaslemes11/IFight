import 'package:flutter/material.dart';

class ScoreDetails extends StatelessWidget {
  final String lutador1;
  final String lutador2;
  final Map<String, List<double>> notasTotais;
  final String vencedor;
  final bool? vencedorKO;
  final bool? vencedorDesempate;
  final Map<String, dynamic>? votosDesempate;

  const ScoreDetails({
    super.key,
    required this.lutador1,
    required this.lutador2,
    required this.notasTotais,
    required this.vencedor,
    this.vencedorKO,
    this.vencedorDesempate,
    this.votosDesempate,
  });

  // 🔥 MÉTODO: Obter cor do vencedor
  Color _getVencedorColor() {
    if (vencedor == 'Empate') return Colors.orange;
    if (vencedor == lutador1) return Colors.red;
    if (vencedor == lutador2) return Colors.blue;
    return Colors.grey;
  }

  // 🔥 MÉTODO: Obter tipo de vitória
  String _getTipoVitoria() {
    if (vencedorKO == true) return 'Vitória por KO';
    if (vencedorDesempate == true) return 'Vitória por Desempate';
    return 'Vitória por Pontos';
  }

  // 🔥 MÉTODO: Obter ícone do tipo de vitória
  IconData _getIconeTipoVitoria() {
    if (vencedorKO == true) return Icons.flash_on;
    if (vencedorDesempate == true) return Icons.gavel;
    return Icons.score;
  }

  // 🔥 MÉTODO: Obter cor do tipo de vitória
  Color _getCorTipoVitoria() {
    if (vencedorKO == true) return Colors.redAccent;
    if (vencedorDesempate == true) return Colors.orange;
    return Colors.green;
  }

  // 🔥 MÉTODO: Calcular estatísticas dos rounds
  Map<String, dynamic> _calcularEstatisticas() {
    final roundsLutador1 = List<int>.filled(3, 0);
    final roundsLutador2 = List<int>.filled(3, 0);
    final roundsEmpate = List<int>.filled(3, 0);

    for (int i = 0; i < 3; i++) {
      final nota1 = notasTotais[lutador1]?[i] ?? 0.0;
      final nota2 = notasTotais[lutador2]?[i] ?? 0.0;

      if (nota1 > nota2) {
        roundsLutador1[i] = 1;
      } else if (nota2 > nota1) {
        roundsLutador2[i] = 1;
      } else {
        roundsEmpate[i] = 1;
      }
    }

    return {
      'roundsVencidos1': roundsLutador1.where((r) => r == 1).length,
      'roundsVencidos2': roundsLutador2.where((r) => r == 1).length,
      'roundsEmpatados': roundsEmpate.where((r) => r == 1).length,
      'roundsLutador1': roundsLutador1,
      'roundsLutador2': roundsLutador2,
    };
  }

  @override
  Widget build(BuildContext context) {
    double total1 = notasTotais[lutador1]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
    double total2 = notasTotais[lutador2]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
    final estatisticas = _calcularEstatisticas();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text(
          "Detalhes da Luta",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [            
            // 🔥 HEADER COM CORES DOS LUTADORES
            Container(
              margin: const EdgeInsets.only(bottom: 20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lutador1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        total1.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${estatisticas['roundsVencidos1']} rounds",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Column(
                    children: [
                      Text(
                        "VS",
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "x",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lutador2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        total2.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${estatisticas['roundsVencidos2']} rounds",
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

            // 🔥 TIPO DE VITÓRIA
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 29, 29, 29),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
                border: Border.all(
                  color: _getCorTipoVitoria().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconeTipoVitoria(),
                    color: _getCorTipoVitoria(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTipoVitoria(),
                    style: TextStyle(
                      color: _getCorTipoVitoria(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 TABELA PRINCIPAL COM CORES VERMELHO E AZUL
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 37, 37, 37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.blueGrey.shade800, width: 0.6),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                  },
                  children: [
                    // Cabeçalho
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                      ),
                      children: [
                        _buildHeaderCell(lutador1, Colors.red),
                        _buildHeaderCell("Rodadas", Colors.white),
                        _buildHeaderCell(lutador2, Colors.blue),
                      ],
                    ),

                    // Linhas dos rounds
                    for (int i = 0; i < 3; i++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: i.isOdd
                              ? const Color(0xFF323232)
                              : const Color(0xFF3A3A3A),
                        ),
                        children: [
                          _buildScoreCell(notasTotais[lutador1], i, Colors.red),
                          _buildRoundCell("Round ${i + 1}", estatisticas, i),
                          _buildScoreCell(notasTotais[lutador2], i, Colors.blue),
                        ],
                      ),

                    // Linha total
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                      ),
                      children: [
                        _buildTotalCell(total1, Colors.red),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "Total",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _buildTotalCell(total2, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 ESTATÍSTICAS DOS ROUNDS
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumo dos Rounds",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        "${estatisticas['roundsVencidos1']}",
                        "Rounds Ganhos",
                        Colors.red,
                      ),
                      _buildStatCard(
                        "${estatisticas['roundsEmpatados']}",
                        "Rounds Empatados",
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "${estatisticas['roundsVencidos2']}",
                        "Rounds Ganhos",
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔥 VENCEDOR COM COR CORRESPONDENTE
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                border: Border.all(
                  color: _getVencedorColor().withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: _getVencedorColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Vencedor: $vencedor",
                    style: TextStyle(
                      color: _getVencedorColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 DIFERENÇA DE PONTOS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 29, 29, 29),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Diferença:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${(total1 - total2).abs().toStringAsFixed(1)} pontos",
                    style: TextStyle(
                      color: total1 > total2 ? Colors.red.shade300 : Colors.blue.shade300,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 DETALHES DO DESEMPATE (se aplicável)
            if (vencedorDesempate == true && votosDesempate != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
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
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Detalhes do Desempate",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Votos recebidos: ${votosDesempate!.values.where((v) => v == vencedor).length}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  // ======== COMPONENTES DE TABELA ATUALIZADOS ========

  Widget _buildHeaderCell(String text, Color color) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildScoreCell(List<double>? notas, int i, Color color) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            notas != null && notas.length > i
                ? notas[i].toStringAsFixed(1)
                : '0.0',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildRoundCell(String text, Map<String, dynamic> estatisticas, int roundIndex) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                text,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              _getRoundWinnerIcon(estatisticas, roundIndex),
            ],
          ),
        ),
      );

  Widget _getRoundWinnerIcon(Map<String, dynamic> estatisticas, int roundIndex) {
    final round1 = estatisticas['roundsLutador1']?[roundIndex] ?? 0;
    final round2 = estatisticas['roundsLutador2']?[roundIndex] ?? 0;
    
    if (round1 == 1) {
      return Icon(Icons.circle, color: Colors.red, size: 12);
    } else if (round2 == 1) {
      return Icon(Icons.circle, color: Colors.blue, size: 12);
    } else {
      return Icon(Icons.remove, color: Colors.orange, size: 12);
    }
  }

  Widget _buildTotalCell(double total, Color color) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            total.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );

  // 🔥 COMPONENTE PARA CARD DE ESTATÍSTICA
  Widget _buildStatCard(String value, String label, Color color) => Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      );
}