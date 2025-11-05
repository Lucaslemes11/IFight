import 'package:flutter/material.dart';

class ScoreDetails extends StatelessWidget {
  final String lutador1;
  final String lutador2;
  final Map<String, List<double>> notasTotais;
  final String vencedor;

  const ScoreDetails({
    super.key,
    required this.lutador1,
    required this.lutador2,
    required this.notasTotais,
    required this.vencedor,
  });

  @override
  Widget build(BuildContext context) {
    double total1 =
        notasTotais[lutador1]?.fold(0.0, (a, b) => a! + b) ?? 0.0;
    double total2 =
        notasTotais[lutador2]?.fold(0.0, (a, b) => a! + b) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
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
            // Tabela principal com o mesmo estilo da ScoreTable
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 37, 37),
                    Color.fromARGB(255, 47, 47, 47)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Table(
                  border: TableBorder.symmetric(
                    inside:
                        BorderSide(color: Colors.blueGrey.shade800, width: 0.6),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                  },
                  children: [
                    // Cabeçalho
                    TableRow(
                      decoration: const BoxDecoration(color: Color.fromARGB(255, 37, 37, 37)),
                      children: [
                        _buildHeaderCell(lutador1),
                        _buildHeaderCell("Rodadas"),
                        _buildHeaderCell(lutador2),
                      ],
                    ),

                    // Linhas dos rounds
                    for (int i = 0; i < 3; i++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: i.isOdd
                              ? const Color(0xFF303030)
                              : const Color(0xFF383838),
                        ),
                        children: [
                          _buildScoreCell(notasTotais[lutador1], i),
                          _buildRoundCell("Round ${i + 1}"),
                          _buildScoreCell(notasTotais[lutador2], i),
                        ],
                      ),

                    // Linha total
                    TableRow(
                      decoration: const BoxDecoration(color: Color.fromARGB(255, 37, 37, 37)),
                      children: [
                        _buildTotalCell(total1),
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
                        _buildTotalCell(total2),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Vencedor
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 37, 37, 37),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade700, width: 1),
              ),
              child: Center(
                child: Text(
                  "Vencedor: $vencedor",
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== COMPONENTES DE TABELA ========

  Widget _buildHeaderCell(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildScoreCell(List<double>? notas, int i) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            notas != null && notas.length > i
                ? notas[i].toStringAsFixed(1)
                : '0.0',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildRoundCell(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );

  Widget _buildTotalCell(double total) => Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            total.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
}
