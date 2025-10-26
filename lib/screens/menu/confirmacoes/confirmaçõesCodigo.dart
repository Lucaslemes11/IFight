import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/menu_page.dart';

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

      // Recarrega para garantir estado atualizado
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
            _mensagemErro = 'Confirme seu email antes de continuar.');
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Erro ao verificar email.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Reenvia o e-mail de verificação
  Future<void> _reenviarEmail() async {
    setState(() => _carregando = true);
    _mensagemErro = '';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _mensagemErro = 'Usuário não logado.');
        return;
      }

      // Recarrega para pegar estado atualizado
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        await updatedUser.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email reenviado!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _mensagemErro =
          e.message ?? 'Erro ao reenviar email de verificação.');
    } catch (e) {
      setState(() => _mensagemErro = 'Erro desconhecido ao reenviar email.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Verificação de Email'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Um email de verificação foi enviado.\nConfirme e pressione "Confirmar".',
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
                onPressed: _reenviarEmail,
                child: const Text(
                  'Reenviar email',
                  style: TextStyle(color: Colors.blueGrey),
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
