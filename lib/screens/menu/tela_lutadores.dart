import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/menu/formularios/formulario_lutador.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LutadoresPage extends StatefulWidget {
  const LutadoresPage({super.key});

  @override
  State<LutadoresPage> createState() => _LutadoresPageState();
}

class _LutadoresPageState extends State<LutadoresPage> {
  String filtroPesquisa = "";

  void _editarLutador(BuildContext context, String docId, Map<String, dynamic> dados) {
    final nomeController = TextEditingController(text: dados['nome']);
    final idadeController = TextEditingController(text: dados['idade']?.toString());
    final pesoController = TextEditingController(text: dados['peso']?.toString());
    final alturaController = TextEditingController(text: dados['altura']?.toString());
    final categoriaController = TextEditingController(text: dados['categoria']);
    final matriculaController = TextEditingController(text: dados['matricula']);

    void atualizarCategoria(String valorPeso) {
      final peso = int.tryParse(valorPeso) ?? 0;
      final pesoAjustado = peso.clamp(1, 300);
      if (peso != pesoAjustado) {
        pesoController.text = pesoAjustado.toString();
        pesoController.selection = TextSelection.fromPosition(
            TextPosition(offset: pesoController.text.length));
      }

      String categoria;
      if (pesoAjustado <= 52) categoria = "Mosca";
      else if (pesoAjustado <= 57) categoria = "Pena";
      else if (pesoAjustado <= 63) categoria = "Leve";
      else if (pesoAjustado <= 69) categoria = "Meio-médio";
      else if (pesoAjustado <= 75) categoria = "Médio";
      else if (pesoAjustado <= 81) categoria = "Meio-pesado";
      else if (pesoAjustado <= 91) categoria = "Pesado";
      else categoria = "Superpesado";

      categoriaController.text = categoria;
    }

    void validarCamposNumericos() {
      final idade = int.tryParse(idadeController.text) ?? 0;
      if (idade > 120) idadeController.text = "120";

      final altura = int.tryParse(alturaController.text) ?? 0;
      if (altura > 272) alturaController.text = "272";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text("Editar Lutador", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Nome", nomeController),
              _buildTextField("Matrícula", matriculaController),
              _buildTextField("Idade", idadeController, teclado: TextInputType.number, onChanged: (_) => validarCamposNumericos()),
              _buildTextField("Peso (kg)", pesoController, teclado: TextInputType.number, onChanged: atualizarCategoria),
              _buildTextField("Categoria", categoriaController, readOnly: true),
              _buildTextField("Altura (cm)", alturaController, teclado: TextInputType.number, onChanged: (_) => validarCamposNumericos()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () async {
              final senhaController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1B1B1B),
                  title: const Text("Confirmação", style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Digite sua senha para confirmar a edição deste lutador:",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: senhaController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Senha",
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF252525),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      child: const Text("Confirmar"),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final cred = EmailAuthProvider.credential(
                  email: user.email!,
                  password: senhaController.text.trim(),
                );

                try {
                  await user.reauthenticateWithCredential(cred);

                  await FirebaseFirestore.instance.collection('lutadores').doc(docId).update({
                    "nome": nomeController.text.trim(),
                    "matricula": matriculaController.text.trim(),
                    "idade": int.tryParse(idadeController.text.trim()) ?? 0,
                    "peso": int.tryParse(pesoController.text.trim()) ?? 0,
                    "altura": int.tryParse(alturaController.text.trim()) ?? 0,
                    "categoria": categoriaController.text.trim(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lutador editado com sucesso!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Senha incorreta!")),
                  );
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _removerLutador(String docId) async {
    final senhaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text("Remover Lutador", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Digite sua senha para confirmar a remoção deste lutador:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senhaController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Senha",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Remover"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: senhaController.text.trim(),
        );
        try {
          await user.reauthenticateWithCredential(cred);
          await FirebaseFirestore.instance.collection('lutadores').doc(docId).delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lutador removido!")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Senha incorreta!")),
          );
        }
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType teclado = TextInputType.text, void Function(String)? onChanged, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: teclado,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF252525),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text("Meus Lutadores"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Pesquisar por nome ou matrícula...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF252525),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (valor) => setState(() => filtroPesquisa = valor.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lutadores')
                  .orderBy('docId', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum lutador cadastrado', style: TextStyle(color: Colors.white70)));
                }

                List<QueryDocumentSnapshot> lutadores = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? '').toString().toLowerCase();
                  final matricula = (dados['matricula'] ?? '').toString().toLowerCase();
                  return nome.contains(filtroPesquisa) || matricula.contains(filtroPesquisa);
                }).toList();

                if (filtroPesquisa.isEmpty && lutadores.length > 3) {
                  lutadores = lutadores.take(5).toList();
                }

                if (lutadores.isEmpty) {
                  return const Center(child: Text('Nenhum lutador encontrado', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  itemCount: lutadores.length,
                  itemBuilder: (context, index) {
                    final doc = lutadores[index];
                    final dados = doc.data() as Map<String, dynamic>;
                    final nome = dados['nome'] ?? "Sem nome";
                    final categoria = dados['categoria'] ?? "Sem categoria";
                    final peso = dados['peso']?.toString() ?? "0";

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(2, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: (dados['fotoBase64'] != null && dados['fotoBase64'].toString().isNotEmpty)
                                  ? MemoryImage(base64Decode(dados['fotoBase64']))
                                  : null,
                              child: (dados['fotoBase64'] == null || dados['fotoBase64'].toString().isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.military_tech, color: Colors.white70, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Categoria: $categoria",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.monitor_weight, color: Colors.white70, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Peso: $peso kg",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                              onPressed: () => _editarLutador(context, doc.id, dados),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                              onPressed: () => _removerLutador(doc.id),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FormularioLutadorVisual()));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(" + Adicionar Lutador"),
            ),
          ),
        ],
      ),
    );
  }
}
