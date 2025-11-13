import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/luta.dart';
import 'package:flutter_application_1/screens/menu/lutas/tela_lobby.dart';

class Formulariolutas extends StatefulWidget {
  const Formulariolutas({super.key});

  @override
  State<Formulariolutas> createState() => _FormulariolutasState();
}

class _FormulariolutasState extends State<Formulariolutas> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();

  String? lutador1;
  String? lutador2;
  List<String> listaLutadores = [];
  bool _isLoadingLutadores = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarLutadores();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  Future<void> _carregarLutadores() async {
    setState(() => _isLoadingLutadores = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('lutadores').get();

      final nomes = snapshot.docs
          .map((doc) => (doc.data()['nome']?.toString().trim() ?? ''))
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      nomes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() => listaLutadores = nomes);
    } catch (e) {
      // opcional: log de erro
    } finally {
      setState(() => _isLoadingLutadores = false);
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final hoje = DateTime.now();
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: hoje, // impede datas passadas
      lastDate: hoje.add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataController.text =
            "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
      });
    }
  }

  Future<void> _selecionarHorario(BuildContext context) async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecione o horário da luta',
    );

    if (hora != null) {
      final horaFormatada =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      setState(() {
        _horaController.text = horaFormatada;
      });
    }
  }

  String gerarIdSala({int tamanho = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(tamanho, (i) => chars[random.nextInt(chars.length)])
        .join();
  }

  void _salvarLuta() async {
    if (lutador1 == null ||
        lutador2 == null ||
        _dataController.text.isEmpty ||
        _horaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    if (lutador1 == lutador2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Os lutadores devem ser diferentes.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final partes = _dataController.text.split('/');
      if (partes.length != 3) throw Exception('Data inválida');

      final data = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );

      final luta = Luta(
        lutador1: lutador1!,
        lutador2: lutador2!,
        data: data,
        horario: _horaController.text,
        juizes: [],
        criadorId: user.uid,
      );

      final idLuta = await Luta.cadastrar(luta);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyPage(
            isCentral: true,
            idSala: idLuta,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar luta: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponiveisPara1 = listaLutadores.where((n) => n != lutador2).toList();
    final disponiveisPara2 = listaLutadores.where((n) => n != lutador1).toList();

    final valor1 = disponiveisPara1.contains(lutador1) ? lutador1 : null;
    final valor2 = disponiveisPara2.contains(lutador2) ? lutador2 : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Luta"),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: const Color(0xFF1B1B1B),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoadingLutadores)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),

            // Dropdown para Lutador 1 com texto truncado
            DropdownButtonFormField<String>(
              initialValue: valor1,
              items: disponiveisPara1
                  .map((nome) => DropdownMenuItem(
                        value: nome,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            nome,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  lutador1 = valor;
                  if (lutador2 == valor) lutador2 = null;
                });
              },
              decoration: const InputDecoration(
                labelText: "Selecione o Lutador 1",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF252525),
              ),
              dropdownColor: const Color(0xFF252525),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
            ),

            const SizedBox(height: 12),

            // Dropdown para Lutador 2 com texto truncado
            DropdownButtonFormField<String>(
              initialValue: valor2,
              items: disponiveisPara2
                  .map((nome) => DropdownMenuItem(
                        value: nome,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            nome,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  lutador2 = valor;
                  if (lutador1 == valor) lutador1 = null;
                });
              },
              decoration: const InputDecoration(
                labelText: "Selecione o Lutador 2",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF252525),
              ),
              dropdownColor: const Color(0xFF252525),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _dataController,
              readOnly: true,
              onTap: () => _selecionarData(context),
              decoration: const InputDecoration(
                labelText: "Data da Luta",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF252525),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _horaController,
              readOnly: true,
              onTap: () => _selecionarHorario(context),
              decoration: const InputDecoration(
                labelText: "Horário da Luta",
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF252525),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isSaving ? null : _salvarLuta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Salvar Luta",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}