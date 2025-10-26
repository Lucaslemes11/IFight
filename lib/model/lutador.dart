
import 'package:cloud_firestore/cloud_firestore.dart';

class Lutador {
  String? matricula; // ID do doc no Firestore
  String nome;
  int idade;
  String categoria;
  int peso;
  int altura;
  String? fotoBase64; // nova propriedade para a foto

  Lutador({
    this.matricula,
    required this.nome,
    required this.idade,
    required this.categoria,
    required this.peso,
    required this.altura,
    this.fotoBase64,
  });

  // Converter Map -> Objeto
  factory Lutador.fromMap(Map<String, dynamic> json, {String? id}) {
    return Lutador(
      matricula: id ?? json['matricula'],
      nome: json['nome'],
      idade: json['idade'],
      categoria: json['categoria'],
      peso: json['peso'],
      altura: json['altura'],
      fotoBase64: json['fotoBase64'],
    );
  }

  // Converter Objeto -> Map
  Map<String, dynamic> toMap() {
    return {
      'matricula': matricula,
      'nome': nome,
      'idade': idade,
      'categoria': categoria,
      'peso': peso,
      'altura': altura,
      'fotoBase64': fotoBase64,
    };
  }

  // CADASTRAR
  static Future<String> cadastrar(Lutador lutador) async {
    final db = FirebaseFirestore.instance.collection('lutadores');
    final docRef = await db.add(lutador.toMap());
    await docRef.update({'matricula': docRef.id}); // garante o id dentro do doc
    return docRef.id;
  }

  // EDITAR
  static Future<void> editar(Lutador lutador) async {
    if (lutador.matricula == null) {
      throw Exception("Lutador não possui matrícula (ID)");
    }
    await FirebaseFirestore.instance
        .collection('lutadores')
        .doc(lutador.matricula)
        .update(lutador.toMap());
  }

  // LISTAR
  static Stream<List<Lutador>> listar() {
    return FirebaseFirestore.instance.collection('lutadores').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Lutador.fromMap(doc.data(), id: doc.id);
        }).toList();
      },
    );
  }

  // BUSCAR POR ID
  static Future<Lutador?> buscarPorId(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('lutadores')
        .doc(id)
        .get();
    if (doc.exists) {
      return Lutador.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }

  // EXCLUIR
  static Future<void> excluir(String id) async {
    await FirebaseFirestore.instance.collection('lutadores').doc(id).delete();
  }
}
