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
    // Soma os valores garantindo conversão segura para double
    double total1 =
        notasTotais[lutador1]?.fold(0, (a, b) => a! + (b).toDouble()) ?? 0;
    double total2 =
        notasTotais[lutador2]?.fold(0, (a, b) => a! + (b).toDouble()) ?? 0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
      appBar: AppBar(
        title: const Text("Detalhes da Luta"),
        backgroundColor: const Color.fromARGB(255, 12, 77, 14),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "$lutador1  x  $lutador2",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.transparent),
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 26, 26, 26),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          "Lutador 1",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          "Round",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          "Lutador 2",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                for (int i = 0; i < 3; i++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: i.isOdd
                          ? const Color.fromARGB(255, 34, 34, 34)
                          : Colors.grey[850],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            notasTotais[lutador1] != null &&
                                    notasTotais[lutador1]!.length > i
                                ? notasTotais[lutador1]![i].toStringAsFixed(1)
                                : '0',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            "Round ${i + 1}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            notasTotais[lutador2] != null &&
                                    notasTotais[lutador2]!.length > i
                                ? notasTotais[lutador2]![i].toStringAsFixed(1)
                                : '0',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 45, 45, 45),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          total1.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 12, 77, 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          "Total",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          total2.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 12, 77, 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Vencedor: $vencedor",
              style: const TextStyle(
                color: Color.fromARGB(255, 12, 77, 14),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
