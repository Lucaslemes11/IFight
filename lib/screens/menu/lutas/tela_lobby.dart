import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/lobby_controller.dart';
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
        backgroundColor: const Color(0xFF1B1B1B),
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
                  // Header da luta
                  _buildLutaHeader(dados, lutadorA, lutadorB, data, horario, criadorId),
                  
                  // Lista de juízes
                  _buildJuizesSection(juizes),
                  
                  // Botões de ação
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

  // =================== HEADER DA LUTA ===================
  Widget _buildLutaHeader(
    Map<String, dynamic> dados,
    String lutadorA,
    String lutadorB,
    DateTime data,
    String horario,
    String criadorId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(12),
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
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 2),
              color: Colors.white12,
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.isCentral ? Icons.gavel : Icons.sports_mma,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$lutadorA  x  $lutadorB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(data),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      horario,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      dados['idSala'] ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                if (criadorId.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
                          const Icon(Icons.gavel_sharp, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Central: $nome',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== SEÇÃO DE JUÍZES ===================
  Widget _buildJuizesSection(List<String> juizes) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Juízes Conectados',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${juizes.length}/3',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: juizes.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum juiz conectado',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: juizes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final juizId = juizes[index];
                        return _buildJuizCard(juizId);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== CARD DO JUÍZ ===================
  Widget _buildJuizCard(String juizId) {
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  // Avatar sem contorno cinza
                  foto != null
                      ? CircleAvatar(
                          radius: 20,
                          backgroundImage: foto,
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (widget.isCentral)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmarRemocaoJuiz(context, juizId, nome),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
      return ElevatedButton(
        onPressed: () {
          controller.navegarParaTelaCentral(context, widget.idSala);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.blueGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Ver Tabela', style: TextStyle(fontSize: 16)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Iniciar Luta', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancelar Luta', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // =================== BOTÃO DOS JUÍZES ===================
  Widget _buildAvaliarButton(List<String> juizes, bool lutaIniciada) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final podeEntrar = (uid != null && juizes.contains(uid)) || (juizes.length < 3);
    final labelText = lutaIniciada ? 'Avaliar Luta' : 'Aguardando liberação';
    final isEnabled = podeEntrar && lutaIniciada;

    return ElevatedButton(
      onPressed: () async {
        if (!mounted) return;

        if (!isEnabled) {
          if (!lutaIniciada) {
            showTopSnackBar(
                'Aguarde: o central precisa iniciar a luta para liberar avaliações.',
                Colors.orangeAccent);
          } else {
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
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: isEnabled ? Colors.blueGrey : Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(labelText, style: const TextStyle(fontSize: 16)),
    );
  }
}