import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/screens/menu/confirmacoes/confirma%C3%A7%C3%B5esCodigo.dart';
import 'package:flutter_application_1/screens/tela_login.dart';
import 'package:flutter_application_1/screens/menu_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, fontFamily: '.SF Pro Text',),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const TelaDeLoginCadastro(),
        '/login_cadastro': (context) => const TelaDeLoginCadastro(),
        '/menu_page': (context) => const MenuPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto verifica o estado do usuário
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se não tiver usuário logado, mostra tela de login
        if (!snapshot.hasData) {
          return const TelaDeLoginCadastro();
        }

        // Se tiver usuário logado, verifica email
        final user = snapshot.data!;
        return FutureBuilder(
          future: user.reload().then((_) => user.emailVerified),
          builder: (context, verificaSnapshot) {
            if (verificaSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (verificaSnapshot.hasData && verificaSnapshot.data == true) {
              return const MenuPage();
            } else {
              // Se email não estiver verificado, envia para a tela de verificação
              return VerificacaoEmailPage(
                email: user.email ?? '',
                senha: '', // senha não precisa aqui
                nome: user.displayName ?? '',
              );
            }
          },
        );
      },
    );
  }
}
