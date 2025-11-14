import 'dart:convert';
import 'dart:io';
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

  // Cores para consistência com LutadoresPage
  final Color bg = const Color(0xFF1B1B1B);
  final Color cardBg = const Color.fromARGB(255, 29, 29, 29);
  final Color accent = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      ImageProvider? foto;
      if (data['fotoBase64'] != null &&
          data['fotoBase64'].toString().isNotEmpty) {
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
              title: const Text(
                'Câmera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.camera);
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
                _pegarFoto(ImageSource.gallery);
              },
            ),
            if (fotoUsuario != null)
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.white),
                title: const Text(
                  'Visualizar Foto',
                  style: TextStyle(color: Colors.white),
                ),
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Foto atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao salvar foto: $e"),
          backgroundColor: Colors.red,
        ),
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
            child: Image(image: fotoUsuario!, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  // ==================== Card de Informações do Usuário ====================
  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            onTap: _abrirOpcoesFoto,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[800],
              backgroundImage: fotoUsuario ?? const AssetImage("assets/images/user.png"),
              child: fotoUsuario == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Informações do Usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nome ?? "Usuário",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _mudarNome,
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: "Editar nome",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.email,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Conta verificada",
                      style: TextStyle(
                        color: Colors.greenAccent[400],
                        fontSize: 14,
                      ),
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

  // ==================== Botões de Ação ====================
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  // ==================== Logout ====================
  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                "Sair da conta",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Tem certeza de que deseja sair da sua conta?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.blueGrey),
        ),
      );
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil("/login_cadastro", (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao deslogar: $e"),
          backgroundColor: Colors.red,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.person, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                "Mudar Nome",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: TextField(
            controller: nomeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Novo nome",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: Colors.blueGrey),
                  ),
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
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Nome atualizado com sucesso!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ Erro ao atualizar nome: $e"),
                      backgroundColor: Colors.red,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey),
      ),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📧 E-mail de redefinição de senha enviado!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao enviar e-mail de redefinição: $e"),
          backgroundColor: Colors.red,
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Remover Conta",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Esta ação é irreversível. Digite sua senha para confirmar:",
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
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.blueGrey),
        ),
      );

      // Reautenticar
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: senhaController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // Remover do Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .delete();

      // Remover conta Firebase
      await user.delete();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pushNamedAndRemoveUntil("/login_cadastro", (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Conta removida com sucesso."),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      String msg = "❌ Erro ao remover conta.";
      if (e.code == "wrong-password") msg = "🔒 Senha incorreta.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao remover conta: $e"),
          backgroundColor: Colors.red,
        ),
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
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: accent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmarLogout,
            tooltip: "Sair",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Informações do Usuário
            _buildUserInfoCard(),
            
            const SizedBox(height: 20),
            
            // Título das Ações
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Ações da Conta",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botões de Ação
            Expanded(
              child: ListView(
                children: [
                  _buildActionButton(
                    icon: Icons.history,
                    text: "Ver histórico de lutas",
                    color: Colors.blueGrey,
                    onPressed: _verHistorico,
                  ),
                  _buildActionButton(
                    icon: Icons.lock_reset,
                    text: "Alterar Senha",
                    color: Colors.orangeAccent,
                    onPressed: _alterarSenha,
                  ),
                  _buildActionButton(
                    icon: Icons.delete_forever,
                    text: "Remover Conta",
                    color: Colors.redAccent,
                    onPressed: _removerConta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}