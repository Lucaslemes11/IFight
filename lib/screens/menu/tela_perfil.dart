import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/menu/tela_historico.dart';
import 'package:image_picker/image_picker.dart';

class MeuPerfilPage extends StatefulWidget {
  const MeuPerfilPage({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends State<MeuPerfilPage> {
  String? nome;
  String? email;
  ImageProvider? fotoUsuario;
  File? _fotoArquivo;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      ImageProvider? foto;
      if (data['fotoBase64'] != null && data['fotoBase64'].toString().isNotEmpty) {
        try {
          final bytes = base64Decode(data['fotoBase64']);
          foto = MemoryImage(bytes);
        } catch (_) {
          foto = null;
        }
      }

      if (!mounted) return;
      setState(() {
        nome = data['nome'] ?? "Usuário";
        email = data['email'] ?? "";
        fotoUsuario = foto;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados do usuário: $e");
    }
  }

  // ==================== Compressão ====================
  Future<Uint8List> _comprimirImagem(Uint8List bytes,
      {int maxBytes = 500 * 1024}) async {
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
  void _abrirOpcoesFoto() {
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
              title: const Text('Câmera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text('Visualizar Foto', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _visualizarFoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pegarFoto(ImageSource source) async {
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

    setState(() {
      fotoUsuario = MemoryImage(bytes);
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final fotoBase64 = bytes.isNotEmpty ? base64Encode(bytes) : '';
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'fotoBase64': fotoBase64});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar foto: $e")),
      );
    }
  }

  void _visualizarFoto() {
    if (fotoUsuario == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image(
              image: fotoUsuario!,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  // ==================== Logout ====================
  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          title: const Text(
            "Sair da conta",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Tem certeza de que deseja sair?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Sair"),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil("/login_cadastro", (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao deslogar: $e")),
      );
    }
  }

  // ==================== Mudar Nome ====================
  void _mudarNome() {
    final nomeController = TextEditingController(text: nome);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          title: const Text("Mudar Nome", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nomeController,
            decoration: const InputDecoration(
              labelText: "Novo nome",
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF252525),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .update({"nome": nomeController.text.trim()});

                  if (!mounted) return;
                  setState(() => nome = nomeController.text.trim());
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(context).pop();
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao atualizar nome: $e")),
                  );
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  // ==================== Alterar Senha ====================
  void _alterarSenha() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-mail de redefinição de senha enviado!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar e-mail de redefinição: $e")),
      );
    }
  }

  // ==================== Remover Conta ====================
  void _removerConta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final senhaController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text("Remover Conta", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Digite sua senha para confirmar a exclusão:",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF252525),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Remover"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Reautenticar
      final cred = EmailAuthProvider.credential(email: user.email!, password: senhaController.text.trim());
      await user.reauthenticateWithCredential(cred);

      // Remover do Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).delete();

      // Remover conta Firebase
      await user.delete();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pushNamedAndRemoveUntil("/login_cadastro", (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conta removida com sucesso.")),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      String msg = "Erro ao remover conta.";
      if (e.code == "wrong-password") msg = "Senha incorreta.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao remover conta: $e")),
      );
    }
  }

  void _verHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Historico()),
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmarLogout),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _abrirOpcoesFoto,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: fotoUsuario ?? const AssetImage("assets/images/user.png"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome ?? "Usuário",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: _mudarNome,
                            icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                            tooltip: "Editar nome",
                          ),
                        ],
                      ),
                      Text(
                        email ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _verHistorico,
                  icon: const Icon(Icons.history),
                  label: const Text("Ver histórico de lutas"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _alterarSenha,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Alterar Senha"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _removerConta,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Remover Conta"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
