import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/menu/confirmacoes/confirmaçõesCodigo.dart';
import 'package:image_picker/image_picker.dart';

class TelaDeLoginCadastro extends StatefulWidget {
  const TelaDeLoginCadastro({super.key});

  @override
  State<TelaDeLoginCadastro> createState() => _TelaDeLoginCadastroState();
}

class _TelaDeLoginCadastroState extends State<TelaDeLoginCadastro> {
  final Usuario _controller = Usuario();

  bool _mostrandoCadastro = false;
  bool _mostrandoLogin = false;
  bool _carregando = false;

  final _formKeyCadastro = GlobalKey<FormState>();
  final _formKeyLogin = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                if (_mostrandoCadastro)
                  _buildCadastro()
                else if (_mostrandoLogin)
                  _buildLogin()
                else
                  _buildInicial(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== UI Inicial ====================
  Widget _buildInicial() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _botao("Cadastrar", Colors.blueGrey[700]!, () {
            setState(() {
              _mostrandoCadastro = true;
              _mostrandoLogin = false;
              _limparCampos();
            });
          }),
          const SizedBox(height: 16),
          _botao("Entrar", const Color(0xFF2C2C2E), () {
            setState(() {
              _mostrandoLogin = true;
              _mostrandoCadastro = false;
              _limparCampos();
            });
          }),
        ],
      );

  Widget _botao(String texto, Color cor, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  // ==================== Cadastro ====================
  Widget _buildCadastro() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Cadastro",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selecionarImagem,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              backgroundImage: kIsWeb
                  ? (_controller.imagemBytes != null
                      ? MemoryImage(_controller.imagemBytes!)
                      : null)
                  : (_controller.imagemSelecionada != null
                      ? FileImage(_controller.imagemSelecionada!)
                      : null),
              child: (_controller.imagemBytes == null &&
                      _controller.imagemSelecionada == null)
                  ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKeyCadastro,
            child: Column(
              children: [
                _buildTextField(_nomeController, "Nome"),
                const SizedBox(height: 8),
                _buildTextField(
                  _emailController,
                  "Email",
                  keyboard: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Campo obrigatório";
                    }
                    final emailRegex =
                        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                    if (!emailRegex.hasMatch(value)) {
                      return "Digite um e-mail válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _buildTextField(_senhaController, "Senha", obscure: true),
                const SizedBox(height: 8),
                _buildTextField(
                  _confirmarSenhaController,
                  "Confirmar Senha",
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _carregando
                    ? const CircularProgressIndicator(color: Colors.blueGrey)
                    : _botao(
                        "Cadastrar", Colors.blueGrey[700]!, _cadastrarUsuario),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _mostrandoCadastro = false;
                _limparCampos();
              });
            },
            child: const Text(
              "Já tem conta? Entrar",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      );

  // ==================== Login ====================
  Widget _buildLogin() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Login",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKeyLogin,
            child: Column(
              children: [
                _buildTextField(
                  _emailController,
                  "Email",
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                _buildTextField(_senhaController, "Senha", obscure: true),
                const SizedBox(height: 16),
                _carregando
                    ? const CircularProgressIndicator(color: Colors.blueGrey)
                    : _botao("Entrar", Colors.blueGrey[700]!, _logarUsuario),
                TextButton(
                  onPressed: _recuperarSenha,
                  child: const Text(
                    "Esqueci a senha",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _mostrandoLogin = false;
                _limparCampos();
              });
            },
            child: const Text(
              "Não tem conta? Cadastrar",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      );

  // ==================== Campo de Texto ====================
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    bool mostrarSenha = false;

    return StatefulBuilder(
      builder: (context, setState) => TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboard,
        obscureText: obscure && !mostrarSenha,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color.fromARGB(255, 37, 37, 37),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    mostrarSenha ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => mostrarSenha = !mostrarSenha),
                )
              : null,
        ),
        validator: validator ??
            (value) =>
                value == null || value.isEmpty ? "Campo obrigatório" : null,
      ),
    );
  }

  // ==================== Limpar Campos ====================
  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _senhaController.clear();
    _confirmarSenhaController.clear();
    _controller.imagemBytes = null;
    _controller.imagemSelecionada = null;
  }

  // ==================== Recuperar Senha ====================
  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite seu e-mail para redefinir a senha.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("E-mail de redefinição enviado! Verifique sua caixa de entrada."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao enviar e-mail de redefinição.";
      if (e.code == 'user-not-found') {
        mensagem = "Nenhuma conta encontrada com este e-mail.";
      } else if (e.code == 'invalid-email') {
        mensagem = "E-mail inválido.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    }
  }

  // ==================== Cadastro Firebase ====================
  Future<void> _cadastrarUsuario() async {
    if (!_formKeyCadastro.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem.")),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      await userCredential.user!.sendEmailVerification();

      Uint8List? fotoBytes = _controller.imagemBytes;
      if (_controller.imagemSelecionada != null && !kIsWeb) {
        fotoBytes = await _controller.imagemSelecionada!.readAsBytes();
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        "nome": nome,
        "email": email,
        "fotoBase64": fotoBytes != null ? base64Encode(fotoBytes) : null,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificacaoEmailPage(
            email: email,
            senha: senha,
            nome: nome,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao cadastrar usuário.";

      switch (e.code) {
        case "email-already-in-use":
          mensagem = "Este e-mail já está em uso.";
          break;
        case "invalid-email":
          mensagem = "O formato do e-mail é inválido.";
          break;
        case "weak-password":
          mensagem = "A senha é muito fraca. Tente uma mais forte.";
          break;
        default:
          mensagem = e.message ?? "Erro desconhecido ao cadastrar.";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ==================== Login Firebase ====================
  Future<void> _logarUsuario() async {
    if (!_formKeyLogin.currentState!.validate()) return;

    setState(() => _carregando = true);

    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);

      final user = credential.user;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          Navigator.pushReplacementNamed(context, '/menu_page');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificacaoEmailPage(
                email: email,
                senha: senha,
                nome: user.displayName ?? '',
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao entrar.";

      switch (e.code) {
        case "user-not-found":
          mensagem = "Usuário não encontrado. Verifique o e-mail.";
          break;
        case "wrong-password":
          mensagem = "Senha incorreta. Tente novamente.";
          break;
        case "invalid-email":
          mensagem = "E-mail inválido.";
          break;
        default:
          mensagem = e.message ?? "Erro desconhecido ao fazer login.";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ==================== Selecionar Imagem ====================
  Future<void> _selecionarImagem() async {
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
              title:
                  const Text('Câmera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _pegarImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title:
                  const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _pegarImagem(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final XFile? imagem =
        await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
    if (imagem == null) return;

    if (kIsWeb) {
      final bytes = await imagem.readAsBytes();
      _controller.imagemBytes = bytes;
    } else {
      _controller.imagemSelecionada = File(imagem.path);
    }

    setState(() {});
  }
}
