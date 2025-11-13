import 'package:cloud_firestore/cloud_firestore.dart';

class Luta {
  String? id;
  final String lutador1;
  final String lutador2;
  final DateTime data;
  final String horario; // formato preferencial: 'HH:mm' ou string vazia
  final List<String> juizes;
  final String criadorId; // UID do criador

  Luta({
    this.id,
    required this.lutador1,
    required this.lutador2,
    required this.data,
    this.horario = "",
    required this.juizes,
    required this.criadorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'lutador1': lutador1,
      'lutador2': lutador2,
      'data': Timestamp.fromDate(data),
      'horario': horario,
      'juizes': juizes,
      'criadorId': criadorId,
    };
  }

  factory Luta.fromMap(Map<String, dynamic> map, {String? id}) {
    dynamic rawData = map['data'];
    DateTime parsedDate;
    if (rawData is Timestamp) {
      parsedDate = rawData.toDate();
    } else if (rawData is DateTime) {
      parsedDate = rawData;
    } else if (rawData is String) {
      parsedDate = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Luta(
      id: id,
      lutador1: map['lutador1'] ?? '',
      lutador2: map['lutador2'] ?? '',
      data: parsedDate,
      horario: map['horario'] ?? '',
      juizes: List<String>.from(map['juizes'] ?? []),
      criadorId: map['criadorId'] ?? '',
    );
  }

  
  static Future<String> cadastrar(Luta luta) async {
    final db = FirebaseFirestore.instance.collection('lutas');
    final docRef = await db.add(luta.toMap());
    await docRef.update({
      'id': docRef.id,
      'idSala': docRef.id, 
    }); 
    return docRef.id;
  }

  
  static Future<void> editar(Luta luta) async {
    if (luta.id == null) {
      throw Exception("A luta não possui ID para edição");
    }
    await FirebaseFirestore.instance
        .collection('lutas')
        .doc(luta.id)
        .update(luta.toMap());
  }

  // LISTAR
  static Stream<List<Luta>> listar() {
    return FirebaseFirestore.instance
        .collection('lutas')
        .orderBy('data')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Luta.fromMap(doc.data(), id: doc.id);
          }).toList();
        });
  }

  // BUSCAR POR ID
  static Future<Luta?> buscarPorId(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('lutas')
        .doc(id)
        .get();
    if (doc.exists) {
      return Luta.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }

  // EXCLUIR
  static Future<void> excluir(String id) async {
    await FirebaseFirestore.instance.collection('lutas').doc(id).delete();
  }
}