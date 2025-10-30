import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/lobby_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_avalia%C3%A7%C3%A3o.dart';
import 'package:flutter_application_1/screens/menu_page.dart';
import 'package:intl/intl.dart';

class LobbyPage extends StatefulWidget {
  final bool isCentral;
  final String idSala;

  const LobbyPage({super.key, required this.isCentral, required this.idSala});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final LobbyController controller = LobbyController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  bool saiuVoluntariamente = false;
  bool _processingExit = false;
  bool _lutaIniciadaLocal = false;

  @override
  void initState() {
    super.initState();
    saiuVoluntariamente = false;
  }

  void showTopSnackBar(String message, Color color) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2500))
        .then((_) => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_processingExit) return false;
        _processingExit = true;
        saiuVoluntariamente = true;

        try {
          await controller.removerJuizDaSala(
            idSala: widget.idSala,
            isCentral: widget.isCentral,
          );
        } catch (e, st) {
          debugPrint('Erro ao remover juiz da sala: $e\n$st');
        } finally {
          _processingExit = false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 27, 27),
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: const Text('Lobby da Luta'),
          centerTitle: true,
          leading: widget.isCentral
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (_processingExit) return;
                    _processingExit = true;
                    saiuVoluntariamente = true;

                    try {
                      await controller.removerJuizDaSala(
                        idSala: widget.idSala,
                        isCentral: widget.isCentral,
                      );
                    } catch (e, st) {
                      debugPrint('Erro ao remover juiz (leading): $e\n$st');
                    } finally {
                      _processingExit = false;
                    }

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MenuPage()),
                      (route) => false,
                    );
                  },
                ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lutas')
              .doc(widget.idSala)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.exists == false) {
              if (!widget.isCentral) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuPage()),
                    (route) => false,
                  );
                });
                return const SizedBox.shrink();
              }

              return const Center(
                child: Text('Sala não encontrada',
                    style: TextStyle(color: Colors.white70)),
              );
            }

            final dados = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final lutadorA = dados['lutador1'] ?? 'Lutador A';
            final lutadorB = dados['lutador2'] ?? 'Lutador B';
            final criadorId = (dados['criadorId'] ?? '').toString();

            final data = (dados['data'] is Timestamp)
                ? (dados['data'] as Timestamp).toDate()
                : (dados['data'] is DateTime
                    ? dados['data'] as DateTime
                    : DateTime.now());
            final horario = dados['horario'] ?? '20:00';
            final List<String> juizes = List<String>.from(dados['juizes'] ?? []);

            final bool lutaIniciadaFirestore =
                (dados['iniciada'] == true) || (dados['avaliacoesLiberadas'] == true);

            if (lutaIniciadaFirestore && !_lutaIniciadaLocal) {
              _lutaIniciadaLocal = true;
            }

            if (!widget.isCentral && userId != null && !juizes.contains(userId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                if (saiuVoluntariamente) return;

                showTopSnackBar('Você foi expulso da sala.', Colors.redAccent);
                await Future.delayed(const Duration(milliseconds: 350));
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuPage()),
                  (route) => false,
                );
              });
            }

            return SafeArea(
              child: Column(
                children: [
                  _buildFightCard(dados, lutadorA, lutadorB, data, horario, criadorId),
                  // _buildJuizesList já retorna Expanded, então NÃO envolver com outro Expanded aqui.
                  _buildJuizesList(juizes),
                  SafeArea(
                    minimum: const EdgeInsets.all(16),
                    child: widget.isCentral
                        ? _buildCentralButtons()
                        : _buildAvaliarButton(juizes, lutaIniciadaFirestore),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =================== CARTÃO DA LUTA ===================
  Widget _buildFightCard(
    Map<String, dynamic> dados,
    String lutadorA,
    String lutadorB,
    DateTime data,
    String horario,
    String criadorId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 37, 37, 37), Color.fromARGB(255, 37, 37, 37)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_mma, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$lutadorA  x  $lutadorB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                const SizedBox(height: 8),
                if (criadorId.isNotEmpty)
                  FutureBuilder<String?>(
                    future: controller.fetchNomeCentral(criadorId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 18);
                      }
                      final nome = snap.data;
                      if (nome == null) return const SizedBox.shrink();
                      return Row(
                        children: [
                          const Icon(Icons.gavel_sharp,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Central: $nome',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(data)} • $horario',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.vpn_key,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      dados['idSala'] ?? '',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== LISTA DE JUÍZES ===================
  // Retorna Expanded (o caller NÃO deve envolver em outro Expanded)
  Widget _buildJuizesList(List<String> juizes) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 37, 37, 37), Color.fromARGB(255, 37, 37, 37)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Juízes na sala',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(
                  '${juizes.length}/3',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ListView dentro de Expanded já (para ocupar o espaço restante)
            Expanded(
              child: ListView.builder(
                itemCount: juizes.length,
                itemBuilder: (context, index) {
                  final juizId = juizes[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(juizId)
                        .get(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final user = snap.data!.data() as Map<String, dynamic>?;
                      final nome = user?['nome'] ?? 'Juiz';
                      final fotoBase64 = user?['fotoBase64'] as String?;

                      ImageProvider? foto;
                      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                        try {
                          foto = MemoryImage(base64Decode(fotoBase64));
                        } catch (_) {
                          foto = null;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Colors.blueGrey.withOpacity(0.2),
                            backgroundImage: foto,
                            child: foto == null
                                ? const Icon(Icons.person,
                                    color: Colors.blueGrey)
                                : null,
                          ),
                          title: Text(nome,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15)),
                          trailing: widget.isCentral
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _confirmarRemocaoJuiz(context, juizId, nome),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== CONFIRMAÇÃO DE REMOÇÃO ===================
  Future<void> _confirmarRemocaoJuiz(
      BuildContext context, String juizId, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Remover juiz',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Deseja realmente remover "$nome" da sala?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Sim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('lutas')
          .doc(widget.idSala)
          .update({
        'juizes': FieldValue.arrayRemove([juizId]),
      });
      showTopSnackBar('Juiz removido.', Colors.green);
    } catch (e, st) {
      debugPrint('Erro ao remover juiz: $e\n$st');
      showTopSnackBar('Falha ao remover juiz.', Colors.redAccent);
    }
  }

  // =================== BOTÕES DO CENTRAL ===================
  Widget _buildCentralButtons() {
    if (_lutaIniciadaLocal) {
      return ElevatedButton.icon(
        onPressed: () {
          controller.navegarParaTelaCentral(context, widget.idSala);
        },
        icon: const Icon(Icons.table_chart),
        label: const Text('Ver Tabela', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          backgroundColor: Colors.blueGrey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('lutas')
                    .doc(widget.idSala)
                    .update({
                  'iniciada': true,
                  'avaliacoesLiberadas': true,
                });

                setState(() {
                  _lutaIniciadaLocal = true;
                });
              } catch (e, st) {
                debugPrint('Erro ao iniciar luta: $e\n$st');
                showTopSnackBar(
                    'Falha ao iniciar a luta. Tente novamente.',
                    Colors.redAccent);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Luta', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.blueGrey,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('lutas')
                    .doc(widget.idSala)
                    .delete();
              } catch (e, st) {
                debugPrint('Erro ao deletar luta: $e\n$st');
                showTopSnackBar('Erro ao deletar luta.', Colors.redAccent);
              }
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar Luta', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.redAccent,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // =================== BOTÃO DOS JUÍZES ===================
  Widget _buildAvaliarButton(List<String> juizes, bool lutaIniciada) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // permite quando: usuário já está na lista OU há menos de 3 juízes
    final podeEntrar = (uid != null && juizes.contains(uid)) || (juizes.length < 3);
    final labelText = lutaIniciada ? 'Avaliar Luta' : 'Aguardando liberação';
    final isEnabled = podeEntrar && lutaIniciada;

    return ElevatedButton.icon(
      onPressed: () async {
        if (!mounted) return;

        // Caso luta não liberada ou usuário não pode entrar: mostrar motivo
        if (!isEnabled) {
          if (!lutaIniciada) {
            showTopSnackBar(
                'Aguarde: o central precisa iniciar a luta para liberar avaliações.',
                Colors.orangeAccent);
          } else {
            // luta iniciada mas não pode entrar
            if (uid != null && !juizes.contains(uid) && juizes.length >= 3) {
              showTopSnackBar('Sala cheia (máximo de 3 juízes atingido).',
                  Colors.orangeAccent);
            } else {
              showTopSnackBar('Você não tem permissão para avaliar.', Colors.orangeAccent);
            }
          }
          return;
        }

        if (uid == null) {
          showTopSnackBar('Usuário não autenticado.', Colors.redAccent);
          return;
        }

        final salaRef = FirebaseFirestore.instance
            .collection('lutas')
            .doc(widget.idSala);

        try {
          // Garantir que o juiz consta na lista (se ainda não estiver)
          final salaSnap = await salaRef.get();
          final dadosSala = salaSnap.data() ?? {};
          final List<String> juizesAtuais = List<String>.from(dadosSala['juizes'] ?? []);

          if (!juizesAtuais.contains(uid)) {
            // Se ainda tem espaço, adiciona; caso contrário aborta (concorrência)
            if (juizesAtuais.length < 3) {
              await salaRef.update({
                'juizes': FieldValue.arrayUnion([uid])
              });
            } else {
              // Se chegou a 3 entre a checagem e aqui, aborta
              showTopSnackBar('Sala cheia (máximo de 3 juízes atingido).', Colors.orangeAccent);
              return;
            }
          }

          // Verificar se já enviou notas
          final notasDoc = await salaRef.collection('notas').doc(uid).get();
          if (notasDoc.exists) {
            showTopSnackBar('Você já enviou suas notas para esta luta.',
                Colors.orangeAccent);
            return;
          }

          // Navega para tela de notas
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TelaNotas(salaId: widget.idSala)),
          );

          if (!mounted) return;
          if (result == 'enviado') {
            showTopSnackBar('Notas enviadas com sucesso.', Colors.green);
          }
        } catch (e, st) {
          debugPrint('Erro ao processar entrada para avaliar: $e\n$st');
          showTopSnackBar('Erro ao verificar/entrar na sala: $e', Colors.redAccent);
        }
      },
      icon: const Icon(Icons.rate_review),
      label: Text(labelText, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: isEnabled ? Colors.blueGrey : Colors.grey,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
