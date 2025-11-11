import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_lobby.dart';

class ConfirmacaoEntrada extends StatelessWidget {
  final String idSala;
  final String criadorId;

  const ConfirmacaoEntrada({
    super.key,
    required this.idSala,
    required this.criadorId,
  });

  Future<void> _entrarComoJuiz(String idSala) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('lutas').doc(idSala);

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
    final bool isCentral = (criadorId == userId);

    return AlertDialog(
      backgroundColor: const Color(0xFF1B1B1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isCentral ? "Administrador da Sala" : "Entrar como Juiz",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Text(
        isCentral
            ? "Você é o criador da sala e terá acesso às funções administrativas."
            : "Você está prestes a entrar como juiz, podendo avaliar e pontuar os rounds. O administrador pode removê-lo caso não tenha autorização.",
        style: const TextStyle(color: Colors.white70, height: 1.4),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (!isCentral) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _entrarComoJuiz(idSala);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LobbyPage(
                      isCentral: false,
                      idSala: idSala,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A6D8C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Entrar"),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LobbyPage(
                    isCentral: true,
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
      ],
    );
  }
}
