import 'dart:io';
import 'dart:convert';
<<<<<<< HEAD
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
=======
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/user.dart';
<<<<<<< HEAD
import 'package:flutter_application_1/screens/menu/confirmacoes/confirmaçõesCodigo.dart';
import 'package:image_picker/image_picker.dart';

/// Tela combinada de Login / Cadastro com rodapé de créditos visível ao rolar.
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/menu/confirmacoes/confirmaçõesCodigo.dart';
import 'package:image_picker/image_picker.dart';

>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
class TelaDeLoginCadastro extends StatefulWidget {
  const TelaDeLoginCadastro({super.key});

  @override
  State<TelaDeLoginCadastro> createState() => _TelaDeLoginCadastroState();
}

class _TelaDeLoginCadastroState extends State<TelaDeLoginCadastro> {
  final Usuario _controller = Usuario();

<<<<<<< HEAD
  // flags de UI
=======
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
  bool _mostrandoCadastro = false;
  bool _mostrandoLogin = false;
  bool _carregando = false;

<<<<<<< HEAD
  // keys
  final _formKeyCadastro = GlobalKey<FormState>();
  final _formKeyLogin = GlobalKey<FormState>();

  // controllers
=======
  final _formKeyCadastro = GlobalKey<FormState>();
  final _formKeyLogin = GlobalKey<FormState>();

>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

<<<<<<< HEAD
  // controle de visibilidade de cada campo de senha
  final ValueNotifier<bool> _mostrarSenhaCadastro = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _mostrarConfirmSenhaCadastro =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _mostrarSenhaLogin = ValueNotifier<bool>(false);

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _mostrarSenhaCadastro.dispose();
    _mostrarConfirmSenhaCadastro.dispose();
    _mostrarSenhaLogin.dispose();
    super.dispose();
  }

  @override
=======
  final ImagePicker _picker = ImagePicker();

  @override
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
<<<<<<< HEAD
            // conteúdo rolável — credits ficam abaixo
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // logo + card principal
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  _cardPrincipal(),
                  const SizedBox(height: 24),
                  _rodapeCreditos(),
                ],
              ),
=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _cardPrincipal() {
    return Card(
      color: const Color(0xFF1B1B1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mostrandoCadastro) ...[
              _titulo("Cadastro"),
              const SizedBox(height: 12),
              _buildAvatarPicker(),
              const SizedBox(height: 12),
              Form(key: _formKeyCadastro, child: _formCadastro()),
            ] else if (_mostrandoLogin) ...[
              _titulo("Entrar"),
              const SizedBox(height: 8),
              Form(key: _formKeyLogin, child: _formLogin()),
            ] else ...[
              _titulo("Bem-vindo"),
              const SizedBox(height: 16),
              _botao("Cadastrar", Colors.blueGrey[700]!, () {
                setState(() {
                  _mostrandoCadastro = true;
                  _mostrandoLogin = false;
                  _limparCampos();
                });
              }),
              const SizedBox(height: 12),
              _botao("Entrar", const Color(0xFF2C2C2E), () {
                setState(() {
                  _mostrandoLogin = true;
                  _mostrandoCadastro = false;
                  _limparCampos();
                });
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _titulo(String texto) => Text(
        texto,
        style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
      );

  Widget _botao(String texto, Color cor, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
<<<<<<< HEAD
            padding: const EdgeInsets.symmetric(vertical: 14),
=======
            padding: const EdgeInsets.symmetric(vertical: 18),
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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

<<<<<<< HEAD
  Widget _buildAvatarPicker() => Column(
        children: [
          GestureDetector(
            onTap: _selecionarImagem,
            child: CircleAvatar(
              radius: 48,
=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
                  ? const Icon(Icons.camera_alt, color: Colors.white, size: 36)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _selecionarImagem,
            child: const Text(
              "Adicionar foto (opcional)",
=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      );

<<<<<<< HEAD
  Widget _formCadastro() {
    return Column(
      children: [
        _buildTextField(_nomeController, "Nome"),
        const SizedBox(height: 8),
        _buildTextField(
          _emailController,
          "E-mail",
          keyboard: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return "Campo obrigatório";
            final emailRegex =
                RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
            if (!emailRegex.hasMatch(value)) return "Digite um e-mail válido";
            return null;
          },
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: _mostrarSenhaCadastro,
          builder: (_, mostrar, __) {
            return _buildTextField(
              _senhaController,
              "Senha",
              obscure: true,
              mostrarSenhaNotifier: _mostrarSenhaCadastro,
              validator: (val) {
                if (val == null || val.isEmpty) return "Campo obrigatório";
                if (val.length < 6) return "Senha deve ter ao menos 6 caracteres";
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: _mostrarConfirmSenhaCadastro,
          builder: (_, mostrar, __) {
            return _buildTextField(
              _confirmarSenhaController,
              "Confirmar senha",
              obscure: true,
              mostrarSenhaNotifier: _mostrarConfirmSenhaCadastro,
              validator: (val) {
                if (val == null || val.isEmpty) return "Campo obrigatório";
                if (val != _senhaController.text) return "Senhas não coincidem";
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 12),
        _carregando
            ? const CircularProgressIndicator(color: Colors.blueGrey)
            : _botao("Cadastrar", Colors.blueGrey[700]!, _cadastrarUsuario),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _mostrandoCadastro = false;
              _limparCampos();
            });
          },
          child: const Text("Já tem conta? Entrar",
              style: TextStyle(color: Colors.blueGrey)),
        ),
      ],
    );
  }

  Widget _formLogin() {
    return Column(
      children: [
        _buildTextField(_emailController, "E-mail",
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: _mostrarSenhaLogin,
          builder: (_, mostrar, __) {
            return _buildTextField(
              _senhaController,
              "Senha",
              obscure: true,
              mostrarSenhaNotifier: _mostrarSenhaLogin,
            );
          },
        ),
        const SizedBox(height: 12),
        _carregando
            ? const CircularProgressIndicator(color: Colors.blueGrey)
            : _botao("Entrar", Colors.blueGrey[700]!, _logarUsuario),
        TextButton(
          onPressed: _recuperarSenha,
          child: const Text("Esqueci a senha",
              style: TextStyle(color: Colors.blueGrey)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _mostrandoLogin = false;
              _limparCampos();
            });
          },
          child:
              const Text("Não tem conta? Cadastrar", style: TextStyle(color: Colors.blueGrey)),
        ),
      ],
    );
  }

=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
<<<<<<< HEAD
    ValueNotifier<bool>? mostrarSenhaNotifier,
  }) {
    // se o campo é de senha e foi passado um notifier, usamo-lo para alternar
    return ValueListenableBuilder<bool>(
      valueListenable: mostrarSenhaNotifier ?? ValueNotifier(false),
      builder: (context, mostrar, child) {
        return TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboard,
          obscureText: obscure && !mostrar,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color.fromARGB(255, 37, 37, 37),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                        mostrar ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white),
                    onPressed: () {
                      if (mostrarSenhaNotifier != null) {
                        mostrarSenhaNotifier.value = !mostrarSenhaNotifier.value;
                      }
                    },
                  )
                : null,
          ),
          validator: validator ??
              (value) =>
                  (value == null || value.isEmpty) ? "Campo obrigatório" : null,
        );
      },
    );
  }

=======
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
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _senhaController.clear();
    _confirmarSenhaController.clear();
    _controller.imagemBytes = null;
    _controller.imagemSelecionada = null;
<<<<<<< HEAD

    // reset visibilities
    _mostrarSenhaCadastro.value = false;
    _mostrarConfirmSenhaCadastro.value = false;
    _mostrarSenhaLogin.value = false;
    setState(() {});
  }

  // ========== Recuperar senha ==========
=======
  }

  // ==================== Recuperar Senha ====================
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  // ========== Cadastro Firebase ==========
=======

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    }
  }

  // ==================== Cadastro Firebase ====================
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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

<<<<<<< HEAD
      // Navega para página de verificação (mantive como no seu original)
=======
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
=======

>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
=======

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
    } finally {
      setState(() => _carregando = false);
    }
  }

<<<<<<< HEAD
  // ========== Login Firebase ==========
=======
  // ==================== Login Firebase ====================
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
=======

>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
=======

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
    } finally {
      setState(() => _carregando = false);
    }
  }

<<<<<<< HEAD
  // ========== Selecionar imagem ==========
=======
  // ==================== Selecionar Imagem ====================
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD
              title: const Text('Câmera', style: TextStyle(color: Colors.white)),
=======
              title:
                  const Text('Câmera', style: TextStyle(color: Colors.white)),
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
              onTap: () async {
                Navigator.pop(context);
                await _pegarImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
<<<<<<< HEAD
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
=======
              title:
                  const Text('Galeria', style: TextStyle(color: Colors.white)),
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
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
<<<<<<< HEAD

  Widget _rodapeCreditos() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Divider(color: Colors.grey),
      const SizedBox(height: 12),

      const Text(
        "Créditos",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      const SizedBox(height: 8),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/if.png",
            height: 18, // tamanho pequeno proporcional ao texto
          ),
          const SizedBox(width: 8),
          const Text(
            "Instituto Federal do Paraná",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),

      const SizedBox(height: 6),
      const Text(
        "Desenvolvedores:",
        style: TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 4),
      const Text(
        "Allan Silva Fagundes\nLucas Rodrigues Lemes\nKhadija Marcela Atanazio Baggio",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 12),

      const Text(
        "© 2025 - Todos os direitos reservados",
        style: TextStyle(color: Colors.white24, fontSize: 12),
      ),
    ],
  );
}

=======
>>>>>>> ae67028bd4ca6cee21b40941c2c76870a4164f1f
}
