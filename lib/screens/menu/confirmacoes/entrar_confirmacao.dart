import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_lobby.dart';

class ConfirmacaoEntrada extends StatelessWidget {
  final String idSala; // ID da sala
  final String criadorId; // ID do usuário que criou a sala

  const ConfirmacaoEntrada({
    super.key,
    required this.idSala,
    required this.criadorId,
  });

  // Função para registrar o usuário como juiz no Firestore
  Future<void> entrarComoJuiz(String idSala) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef =
          FirebaseFirestore.instance.collection('lutas').doc(idSala);

      // Usa set com merge para evitar erro de update em doc inexistente
      await docRef.set({
        'juizes': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Erro ao entrar como juiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final bool isCentral = (criadorId == userId); // verifica se é o criador

    return Stack(
      children: [
        // Fundo desfocado
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),

        // Caixa de confirmação
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  isCentral
                      ? "Você é o administrador da sala"
                      : "Entrar como juiz?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isCentral
                      ? "Como criador da sala, você terá acesso às funções administrativas."
                      : "Você vai entrar na luta como juiz, podendo avaliar e dar notas aos rounds. "
                          "O administrador pode expulsá-lo caso não tenha autorização.",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!isCentral)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botão NÃO
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Não"),
                      ),
                      // Botão SIM
                      ElevatedButton(
                        onPressed: () async {
                          await entrarComoJuiz(idSala); // registra como juiz
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LobbyPage(
                                isCentral: false, // Juiz
                                idSala: idSala,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A6D8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Sim"),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LobbyPage(
                            isCentral: true, // Administrador
                            idSala: idSala,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A6D8C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Continuar"),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
