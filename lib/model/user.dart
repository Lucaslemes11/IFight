import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Usuario {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? imagemSelecionada;
  Uint8List? imagemBytes;
  String? fotoBase64;

  // Getter público para UID do usuário logado
  String? get uid => _auth.currentUser?.uid;

  // =================== OBTER FOTO DO USUÁRIO ===================
  Future<ImageProvider?> obterFotoUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      final data = doc.data();
      if (data == null || data['fotoBase64'] == null || data['fotoBase64'].isEmpty) {
        return null;
      }
      final bytes = base64Decode(data['fotoBase64']);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("Erro ao obter foto: $e");
      return null;
    }
  }

  // =================== CADASTRAR USUÁRIO ===================
  Future<void> cadastrarUsuario({
    required BuildContext context,
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    if (senha.trim() != confirmarSenha.trim()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não conferem")),
      );
      return;
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      // Envia verificação de e-mail
      await cred.user?.sendEmailVerification();

      // Converter imagem em Base64
      if ((kIsWeb && imagemBytes != null) || (!kIsWeb && imagemSelecionada != null)) {
        Uint8List bytes = kIsWeb
            ? imagemBytes!
            : await imagemSelecionada!.readAsBytes();
        fotoBase64 = base64Encode(bytes);
      }

      // Salvar no Firestore
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'nome': nome.trim(),
        'email': email.trim(),
        'tipo': 'user',
        'fotoBase64': fotoBase64 ?? '',
        'verificado': false,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conta criada! Verifique seu e-mail.")),
      );
      Navigator.of(context).pushReplacementNamed("/login_page");
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String mensagem = "Erro ao cadastrar usuário.";
      if (e.code == 'email-already-in-use') mensagem = "Este e-mail já está em uso.";
      if (e.code == 'weak-password') mensagem = "A senha é muito fraca.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro inesperado: $e")),
      );
    }
  }

  // =================== LOGIN USUÁRIO ===================
  Future<void> loginUsuario({
    required BuildContext context,
    required String email,
    required String senha,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: "user-null",
          message: "Não foi possível obter os dados do usuário.",
        );
      }

      // Verifica se o e-mail está confirmado
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("E-mail ainda não verificado. Verifique sua caixa de entrada."),
          ),
        );
        await _auth.signOut();
        return;
      }

      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed("/menu_page");
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String mensagem = "Erro ao logar.";
      if (e.code == 'wrong-password') mensagem = "Senha incorreta.";
      if (e.code == 'user-not-found') mensagem = "Usuário não encontrado.";
      if (e.code == 'invalid-email') mensagem = "E-mail inválido.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro inesperado: $e")),
      );
    }
  }

  // =================== REENVIAR VERIFICAÇÃO ===================
  Future<void> reenviarVerificacao(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verificação reenviada para o e-mail cadastrado.")),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário já está verificado ou não está logado.")),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao reenviar verificação: $e")),
      );
    }
  }

  // =================== SELECIONAR IMAGEM ===================
  Future<void> selecionarImagem(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        if (kIsWeb) {
          final bytes = result.files.first.bytes;
          if (bytes != null) imagemBytes = bytes;
        } else {
          imagemSelecionada = File(result.files.single.path!);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao selecionar imagem: $e")),
      );
      
    }
  }
}
