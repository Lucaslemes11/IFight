// luta_controller.dart (BACKEND)
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/menu/formularios/formulario_lutas.dart';

class LutaController {
 
  final List<Map<String, String>> lutas = List.generate(
    5,
    (index) => {
      'jogadorA': 'Jogador A${index + 1}',
      'jogadorB': 'Jogador B${index + 1}',
      'idSala': 'Sala ID: #00${index + 1}',
    },
  );

  
  void novaSala(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Formulariolutas()),
    );
  }
}
