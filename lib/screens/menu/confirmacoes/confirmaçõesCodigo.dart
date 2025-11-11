import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu_page.dart';

import 'package:flutter_application_1/screens/tela_login.dart'; // ajuste se o nome for diferente

class VerificacaoEmailPage extends StatefulWidget {
  final String email;
  final String senha;
  final String nome;

  const VerificacaoEmailPage({
    super.key,
    required this.email,
    required this.senha,
    required this.nome,
  });

  @override
  State<VerificacaoEmailPage> createState() => _VerificacaoEmailPageState();
}

class _VerificacaoEmailPageState extends State<VerificacaoEmailPage> {
  bool _carregando = false;
  String _mensagemErro = '';
  int _tempoRestante = 0;
  Timer? _timer;

  late final String userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email ?? widget.email;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarContagem() {
    setState(() => _tempoRestante = 50);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempoRestante == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _tempoRestante--);
      }
    });
  }

  Future<void> _verificarEmail() async {
    setState(() {
      _carregando = true;
      _mensagemErro = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuPage()),
          (route) => false,
        );
      } else {
        if (mounted) setState(() =>
            _mensagemErro = 'Confirme seu e-mail antes de continuar.');
      }
    } catch (e) {
      if (mounted) setState(() => _mensagemErro = 'Erro ao verificar e-mail.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _reenviarEmail() async {
    if (_tempoRestante > 0) return;

    setState(() {
      _carregando = true;
      _mensagemErro = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("E-mail de verificação enviado para $userEmail!")),
      );

      _iniciarContagem();
    } catch (e) {
      if (mounted) setState(() => _mensagemErro = 'Erro ao reenviar e-mail: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Verificação de E-mail'),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TelaDeLoginCadastro()),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Um e-mail de verificação foi enviado.\nConfirme e pressione "Confirmar".',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Campo de e-mail FIXO
              TextField(
                controller: TextEditingController(text: userEmail),
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueGrey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _carregando
                  ? const CircularProgressIndicator(color: Colors.blueGrey)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verificarEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _tempoRestante > 0 ? null : _reenviarEmail,
                child: Text(
                  _tempoRestante > 0
                      ? 'Aguarde $_tempoRestante s para reenviar'
                      : 'Reenviar e-mail',
                  style: TextStyle(
                    color: _tempoRestante > 0
                        ? Colors.grey
                        : Colors.blueGrey[200],
                  ),
                ),
              ),

              if (_mensagemErro.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _mensagemErro,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
