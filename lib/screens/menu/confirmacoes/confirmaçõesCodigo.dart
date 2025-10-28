<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu_page.dart';
import 'package:flutter_application_1/screens/tela_login.dart'; 
=======
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu_page.dart';

>>>>>>> origin/master
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
<<<<<<< HEAD
  int _tempoRestante = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarContagem() {
    setState(() => _tempoRestante = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempoRestante == 0) {
        timer.cancel();
      } else {
        setState(() => _tempoRestante--);
      }
    });
  }

=======

  @override
  void initState() {
    super.initState();
    _enviarEmailSeNecessario();
  }

  // Envia o e-mail apenas se o usuário não tiver verificado
  Future<void> _enviarEmailSeNecessario() async {
    setState(() => _carregando = true);
    _mensagemErro = '';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

      // Recarrega o usuário para atualizar o estado
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        await updatedUser.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email de verificação enviado! Confira sua caixa de entrada.",
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _mensagemErro =
          e.message ?? 'Erro ao enviar email de verificação.');
    } catch (e) {
      setState(() => _mensagemErro = 'Erro desconhecido ao enviar email.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Verifica se o e-mail foi confirmado
>>>>>>> origin/master
  Future<void> _verificarEmail() async {
    setState(() {
      _carregando = true;
      _mensagemErro = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

<<<<<<< HEAD
=======
      // Recarrega para garantir estado atualizado
>>>>>>> origin/master
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
        setState(() =>
<<<<<<< HEAD
            _mensagemErro = 'Confirme seu e-mail antes de continuar.');
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Erro ao verificar e-mail.');
=======
            _mensagemErro = 'Confirme seu email antes de continuar.');
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Erro ao verificar email.');
>>>>>>> origin/master
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

<<<<<<< HEAD
  Future<void> _reenviarEmail() async {
    if (_tempoRestante > 0) return;

    setState(() {
      _carregando = true;
      _mensagemErro = '';
    });
=======
  // Reenvia o e-mail de verificação
  Future<void> _reenviarEmail() async {
    setState(() => _carregando = true);
    _mensagemErro = '';
>>>>>>> origin/master

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

<<<<<<< HEAD
=======
      // Recarrega para pegar estado atualizado
>>>>>>> origin/master
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        await updatedUser.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
          const SnackBar(content: Text("E-mail de verificação reenviado!")),
        );
        _iniciarContagem();
      }
    } on FirebaseAuthException catch (e) {
      if (e.message != null &&
          e.message!.contains('We have blocked all requests')) {
        debugPrint('Firebase bloqueou o envio temporariamente (ignorado).');
      } else {
        debugPrint('Erro no reenvio de e-mail: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erro desconhecido ao reenviar e-mail: $e');
=======
          const SnackBar(content: Text("Email reenviado!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _mensagemErro =
          e.message ?? 'Erro ao reenviar email de verificação.');
    } catch (e) {
      setState(() => _mensagemErro = 'Erro desconhecido ao reenviar email.');
>>>>>>> origin/master
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
<<<<<<< HEAD
        title: const Text('Verificação de E-mail'),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TelaDeLoginCadastro()),
            );
          },
        ),
=======
        title: const Text('Verificação de Email'),
        backgroundColor: Colors.blueGrey,
>>>>>>> origin/master
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
<<<<<<< HEAD
                'Um e-mail de verificação foi enviado.\nConfirme e pressione "Confirmar".',
=======
                'Um email de verificação foi enviado.\nConfirme e pressione "Confirmar".',
>>>>>>> origin/master
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
                              borderRadius: BorderRadius.circular(10)),
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
<<<<<<< HEAD
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
=======
                onPressed: _reenviarEmail,
                child: const Text(
                  'Reenviar email',
                  style: TextStyle(color: Colors.blueGrey),
>>>>>>> origin/master
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
