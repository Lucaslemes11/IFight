import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class FormularioLutadorVisual extends StatefulWidget {
  const FormularioLutadorVisual({super.key});

  @override
  State<FormularioLutadorVisual> createState() =>
      _FormularioLutadorVisualState();
}

class _FormularioLutadorVisualState extends State<FormularioLutadorVisual> {
  Uint8List? imagemBytes;
  File? imagemFile;
  String? fotoBase64;

  final matriculaController = TextEditingController();
  final nomeController = TextEditingController();
  final idadeController = TextEditingController();
  final categoriaController = TextEditingController();
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();

  bool carregando = false;
  final ImagePicker _picker = ImagePicker();

  // ==================== Função de compressão ====================
  Future<Uint8List> comprimirImagem(
    Uint8List bytes, {
    int maxBytes = 500 * 1024,
  }) async {
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    ui.Image image = frame.image;

    Uint8List result;
    double scale = 1.0;

    while (true) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      result = byteData!.buffer.asUint8List();

      if (result.lengthInBytes <= maxBytes || scale <= 0.1) break;

      int width = (image.width * scale).toInt();
      int height = (image.height * scale).toInt();

      ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint(),
      );
      image = await recorder.endRecording().toImage(width, height);

      scale -= 0.1;
    }

    return result;
  }

  // ==================== Imagem ====================
  void _abrirOpcoesFoto() {
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
              title: const Text(
                'Câmera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text(
                'Galeria',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pegarFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pegarFoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    Uint8List bytes;
    if (kIsWeb) {
      bytes = await pickedFile.readAsBytes();
    } else {
      imagemFile = File(pickedFile.path);
      bytes = await imagemFile!.readAsBytes();
    }

    bytes = await comprimirImagem(bytes); // Comprime corretamente

    setState(() => imagemBytes = bytes);
  }

  // ==================== Campos ====================
  void _atualizarCategoria(String valorPeso) {
    int peso = int.tryParse(valorPeso) ?? 0;
    peso = peso.clamp(0, 300);
    if (pesoController.text != peso.toString()) {
      pesoController.text = peso.toString();
      pesoController.selection = TextSelection.fromPosition(
        TextPosition(offset: pesoController.text.length),
      );
    }

    String categoria;
    if (peso <= 52) {
      categoria = "Mosca";
    } else if (peso <= 57) {
      categoria = "Pena";
    } else if (peso <= 63) {
      categoria = "Leve";
    } else if (peso <= 69) {
      categoria = "Meio-médio";
    } else if (peso <= 75) {
      categoria = "Médio";
    } else if (peso <= 81) {
      categoria = "Meio-pesado";
    } else if (peso <= 91) {
      categoria = "Pesado";
    } else {
      categoria = "Superpesado";
    }

    categoriaController.text = categoria;
  }

  void _validarCamposNumericos() {
    int idade = int.tryParse(idadeController.text) ?? 1;
    idade = idade.clamp(1, 120);
    idadeController.text = idade.toString();
    idadeController.selection = TextSelection.fromPosition(
      TextPosition(offset: idadeController.text.length),
    );

    int altura = int.tryParse(alturaController.text) ?? 1;
    altura = altura.clamp(1, 272);
    alturaController.text = altura.toString();
    alturaController.selection = TextSelection.fromPosition(
      TextPosition(offset: alturaController.text.length),
    );

    int peso = int.tryParse(pesoController.text) ?? 1;
    peso = peso.clamp(1, 300);
    pesoController.text = peso.toString();
    pesoController.selection = TextSelection.fromPosition(
      TextPosition(offset: pesoController.text.length),
    );
  }

  // ==================== Salvar ====================
  Future<void> salvarLutador() async {
    final matricula = matriculaController.text.trim();
    final nome = nomeController.text.trim();
    final idade = int.tryParse(idadeController.text.trim()) ?? 0;
    final peso = int.tryParse(pesoController.text.trim()) ?? 0;
    final altura = int.tryParse(alturaController.text.trim()) ?? 0;
    final categoria = categoriaController.text.trim();

    if (matricula.isEmpty ||
        nome.isEmpty ||
        idade <= 0 ||
        peso <= 0 ||
        altura <= 0 ||
        categoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos corretamente")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      if (imagemBytes != null) {
        fotoBase64 = base64Encode(imagemBytes!);
      }

      // SALVAR LUTADOR COM ID
      final lutadorData = {
        "matricula": matricula,
        "nome": nome,
        "idade": idade,
        "categoria": categoria,
        "peso": peso,
        "altura": altura,
        "fotoBase64": fotoBase64 ?? '',
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Adiciona o lutador e obtém a referência do documento
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('lutadores')
          .add(lutadorData);

      // IMPORTANTE: Atualiza o documento para incluir o ID como campo
      await docRef.update({
        'lutadorId': docRef.id, // Salva o ID como campo adicional
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lutador salvo com sucesso!")),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar lutador: $e")));
    } finally {
      setState(() => carregando = false);
    }
  }

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (imagemBytes != null) {
      avatarImage = MemoryImage(imagemBytes!);
    } else if (imagemFile != null) {
      avatarImage = FileImage(imagemFile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Lutador"),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: const Color(0xFF1B1B1B),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _abrirOpcoesFoto,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField("Matrícula", matriculaController),
            const SizedBox(height: 12),
            _buildTextField("Nome", nomeController),
            const SizedBox(height: 12),
            _buildTextField(
              "Idade",
              idadeController,
              teclado: TextInputType.number,
              onChanged: (_) => _validarCamposNumericos(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Peso (kg)",
              pesoController,
              teclado: TextInputType.number,
              onChanged: _atualizarCategoria,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Categoria (automática)",
              categoriaController,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Altura (cm)",
              alturaController,
              teclado: TextInputType.number,
              onChanged: (_) => _validarCamposNumericos(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            carregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: salvarLutador,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Salvar Lutador",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType teclado = TextInputType.text,
    void Function(String)? onChanged,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: teclado,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}