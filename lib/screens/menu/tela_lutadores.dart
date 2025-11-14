import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  File? _fotoArquivo;
  MemoryImage? fotoUsuario;

  // Cores para manter consistência
  final Color bg = const Color(0xFF1B1B1B);
  final Color cardBg = const Color.fromARGB(255, 29, 29, 29);
  final Color accent = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    // Migra automaticamente quando a página abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _migrarLutadoresExistentes();
    });
  }

  // ==================== MIGRAÇÃO DE DADOS EXISTENTES ====================
  Future<void> _migrarLutadoresExistentes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lutadores')
          .get();

      int migrados = 0;
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in snapshot.docs) {
        final dados = doc.data();
        // Se o lutador não tem lutadorId, adiciona
        if (dados['lutadorId'] == null) {
          batch.update(doc.reference, {
            'lutadorId': doc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          migrados++;
        }
      }
      
      if (migrados > 0) {
        await batch.commit();
        if (mounted) {
          print('✅ $migrados lutadores migrados com sucesso!');
        }
      }
    } catch (e) {
      print('❌ Erro na migração: $e');
    }
  }

  // ==================== Compressão ====================
  Future<Uint8List> _comprimirImagem(
    Uint8List bytes, {
    int maxBytes = 500 * 1024,
  }) async {
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    ui.Image image = frame.image;

    Uint8List result = bytes;
    double scale = 1.0;

    while (result.lengthInBytes > maxBytes && scale > 0.1) {
      int width = (image.width * scale).toInt();
      int height = (image.height * scale).toInt();

      ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint(),
      );

      ui.Image resized = await recorder.endRecording().toImage(width, height);
      final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);
      result = byteData!.buffer.asUint8List();
      scale -= 0.1;
    }

    return result;
  }

  // ==================== Foto ====================
  void _abrirOpcoesFoto(String docId, Map<String, dynamic> dados) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Câmera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.camera, docId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text(
                'Galeria',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.gallery, docId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text(
                'Visualizar Foto',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _visualizarFoto(dados['fotoBase64']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pegarFoto(ImageSource source, String docId) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    Uint8List bytes;
    if (kIsWeb) {
      bytes = await pickedFile.readAsBytes();
    } else {
      _fotoArquivo = File(pickedFile.path);
      bytes = await _fotoArquivo!.readAsBytes();
    }

    bytes = await _comprimirImagem(bytes);

    // ======== Solicita senha antes de atualizar ========
    final senhaController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text(
          "Confirmação de Segurança",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Digite sua senha para confirmar a atualização da foto:",
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
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
    if (user == null) return;

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: senhaController.text.trim(),
    );

    try {
      // Reautentica o usuário antes de permitir a atualização
      await user.reauthenticateWithCredential(cred);

      // Converte imagem para Base64 e atualiza no Firestore
      final fotoBase64 = base64Encode(bytes);
      await FirebaseFirestore.instance
          .collection('lutadores')
          .doc(docId)
          .update({'fotoBase64': fotoBase64});

      setState(() {
        fotoUsuario = MemoryImage(bytes);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Foto atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Senha incorreta ou sessão expirada!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _visualizarFoto(String? base64) {
    if (base64 == null || base64.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nenhuma foto disponível.")));
      return;
    }

    final bytes = base64Decode(base64);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  // ==================== FUNÇÃO DELETE CORRIGIDA ====================
  Future<void> _deleteLutador(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lutadores')
          .doc(docId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Lutador deletado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erro ao deletar lutador: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== Editar e Remover ====================
  void _editarLutador(
    BuildContext context,
    String docId,
    Map<String, dynamic> dados,
  ) {
    final nomeController = TextEditingController(text: dados['nome']);
    final idadeController = TextEditingController(
      text: dados['idade']?.toString(),
    );
    final pesoController = TextEditingController(
      text: dados['peso']?.toString(),
    );
    final alturaController = TextEditingController(
      text: dados['altura']?.toString(),
    );
    final categoriaController = TextEditingController(text: dados['categoria']);
    final matriculaController = TextEditingController(text: dados['matricula']);

    void atualizarCategoria(String valorPeso) {
      final peso = int.tryParse(valorPeso) ?? 0;
      final pesoAjustado = peso.clamp(1, 300);
      if (peso != pesoAjustado) {
        pesoController.text = pesoAjustado.toString();
        pesoController.selection = TextSelection.fromPosition(
          TextPosition(offset: pesoController.text.length),
        );
      }

      String categoria;
      if (pesoAjustado <= 52) {
        categoria = "Mosca";
      } else if (pesoAjustado <= 57)
        categoria = "Pena";
      else if (pesoAjustado <= 63)
        categoria = "Leve";
      else if (pesoAjustado <= 69)
        categoria = "Meio-médio";
      else if (pesoAjustado <= 75)
        categoria = "Médio";
      else if (pesoAjustado <= 81)
        categoria = "Meio-pesado";
      else if (pesoAjustado <= 91)
        categoria = "Pesado";
      else
        categoria = "Superpesado";

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
        title: const Text(
          "Editar Lutador",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Nome", nomeController),
              _buildTextField("Matrícula", matriculaController),
              _buildTextField(
                "Idade",
                idadeController,
                teclado: TextInputType.number,
                onChanged: (_) => validarCamposNumericos(),
              ),
              _buildTextField(
                "Peso (kg)",
                pesoController,
                teclado: TextInputType.number,
                onChanged: atualizarCategoria,
              ),
              _buildTextField("Categoria", categoriaController, readOnly: true),
              _buildTextField(
                "Altura (cm)",
                alturaController,
                teclado: TextInputType.number,
                onChanged: (_) => validarCamposNumericos(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () async {
              final senhaController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1B1B1B),
                  title: const Text(
                    "Confirmação",
                    style: TextStyle(color: Colors.white),
                  ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
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

                  // 🔹 ATUALIZA COM O ID INCLUÍDO
                  await FirebaseFirestore.instance
                      .collection('lutadores')
                      .doc(docId)
                      .update({
                        "nome": nomeController.text.trim(),
                        "matricula": matriculaController.text.trim(),
                        "idade": int.tryParse(idadeController.text.trim()) ?? 0,
                        "peso": int.tryParse(pesoController.text.trim()) ?? 0,
                        "altura": int.tryParse(alturaController.text.trim()) ?? 0,
                        "categoria": categoriaController.text.trim(),
                        "lutadorId": docId, // 🔹 GARANTE que o ID está salvo
                        "updatedAt": FieldValue.serverTimestamp(),
                      });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lutador editado com sucesso!"),
                    ),
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
        title: const Text(
          "Remover Lutador",
          style: TextStyle(color: Colors.white),
        ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
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
          // 🔹 USA A FUNÇÃO DELETE CORRIGIDA
          await _deleteLutador(docId);
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Senha incorreta!")));
        }
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType teclado = TextInputType.text,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
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

  // ==================== CARD DESIGN CORRIGIDO ====================
  Widget _buildLutadorCard(Map<String, dynamic> dados, String docId) {
    final nome = dados['nome'] ?? "Sem nome";
    final categoria = dados['categoria'] ?? "Sem categoria";
    final peso = dados['peso']?.toString() ?? "0";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
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
          // Avatar/Photo
          GestureDetector(
            onTap: () => _abrirOpcoesFoto(docId, dados),
            child:
                (dados['fotoBase64'] != null &&
                    dados['fotoBase64'].toString().isNotEmpty)
                ? CircleAvatar(
                    radius: 26,
                    backgroundImage: MemoryImage(
                      base64Decode(dados['fotoBase64']),
                    ),
                  )
                : CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // Informações do Lutador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
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
                    const Icon(
                      Icons.military_tech,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Categoria: $categoria",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Peso: $peso kg",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botões de ação
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                onPressed: () => _editarLutador(context, docId, dados),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () => _removerLutador(docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Meus Lutadores"),
        backgroundColor: accent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Pesquisar por nome ou matrícula...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) =>
                  setState(() => filtroPesquisa = valor.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lutadores')
                  .orderBy('nome')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueGrey),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum lutador cadastrado',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                List<QueryDocumentSnapshot> lutadores = snapshot.data!.docs
                    .where((doc) {
                      final dados = doc.data() as Map<String, dynamic>;
                      final nome = (dados['nome'] ?? '')
                          .toString()
                          .toLowerCase();
                      final matricula = (dados['matricula'] ?? '')
                          .toString()
                          .toLowerCase();
                      return nome.contains(filtroPesquisa) ||
                          matricula.contains(filtroPesquisa);
                    })
                    .toList();

                if (filtroPesquisa.isEmpty && lutadores.length > 5) {
                  lutadores = lutadores.take(5).toList();
                }

                if (lutadores.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum lutador encontrado',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: lutadores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = lutadores[index];
                    final dados = doc.data() as Map<String, dynamic>;
                    return _buildLutadorCard(dados, doc.id);
                  },
                );
              },
            ),
          ),

          // Botão de adicionar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FormularioLutadorVisual(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(" + Adicionar Lutador"),
            ),
          ),
        ],
      ),
    );
  }
}