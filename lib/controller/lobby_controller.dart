import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_avalia%C3%A7%C3%A3o.dart';
import 'package:flutter_application_1/screens/menu/lutas/tabela_score.dart';

class LobbyController {
  static const int maxJuizes = 3;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> removerJuizDaSala({
    required String idSala,
    required bool isCentral,
  }) async {
    if (isCentral) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      await _firestore.collection('lutas').doc(idSala).update({
        'juizes': FieldValue.arrayRemove([currentUid]),
      });
    } catch (e) {
     
      debugPrint('removerJuizDaSala erro: $e');
      rethrow;
    }
  }

 
  void navegarParaTelaJuiz(BuildContext context, String salaId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaNotas(salaId: salaId)),
    );
  }

  
  void navegarParaTelaCentral(BuildContext context, String salaId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScoreTable(salaId: salaId)),
    );
  }

  
  Future<String?> fetchNomeCentral(String? criadorId) async {
    if (criadorId == null || criadorId.isEmpty) return null;
    final doc = await _firestore.collection('usuarios').doc(criadorId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data == null ? null : (data['nome'] as String?);
  }


  bool podeEntrarComoJuiz(List<String> juizes) {
    return juizes.length < maxJuizes;
  }
}
