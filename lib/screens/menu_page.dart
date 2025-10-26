import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/menu/tela_classificacao.dart';
import 'package:flutter_application_1/screens/menu/tela_lutadores.dart';
import 'package:flutter_application_1/screens/menu/tela_perfil.dart';
import 'package:flutter_application_1/screens/menu/lista_lutas.dart';
import 'package:flutter_application_1/screens/tela_login.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ListaDeLutas(),
      LutadoresPage(),
      ClassificacaoPage(),
      MeuPerfilPage(
        onLogout: () => _logout(context),
      ),
      const Center(
        child: Text(
          "🏆 Campeonato",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/user_avatar.png'),
            ),
            SizedBox(height: 16),
            Text(
              "Meu Perfil",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ],
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => TelaDeLoginCadastro()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.09),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.grey[900],
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blueGrey,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.sports_mma_outlined),
                activeIcon: Icon(Icons.sports_mma),
                label: "Nova Luta",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_alt),
                activeIcon: Icon(Icons.people_alt),
                label: "Lutadores",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: "Campeonato",
              ),
              BottomNavigationBarItem(
                icon: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get(),
                  builder: (context, snapshot) {
                    ImageProvider image =
                        const AssetImage('assets/images/user_avatar.png');
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null &&
                          data['fotoBase64'] != null &&
                          data['fotoBase64'].toString().isNotEmpty) {
                        try {
                          final bytes = base64Decode(data['fotoBase64']);
                          image = MemoryImage(bytes);
                        } catch (_) {}
                      }
                    }
                    return CircleAvatar(radius: 12, backgroundImage: image);
                  },
                ),
                label: "Perfil",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
