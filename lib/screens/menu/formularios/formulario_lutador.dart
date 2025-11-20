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
  final categoriaPesoController = TextEditingController();
  final categoriaIdadeController = TextEditingController();
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  final equipeController = TextEditingController();
  final estadoController = TextEditingController();

  String genero = 'Masculino';
  bool carregando = false;
  final ImagePicker _picker = ImagePicker();

  // Lista de estados brasileiros (siglas)
  final List<String> estadosBrasileiros = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

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

    bytes = await comprimirImagem(bytes);

    setState(() => imagemBytes = bytes);
  }

  // ==================== Cálculo de Idade e Categoria ====================
  void _calcularIdadeECategoria(String valorIdade) {
    int idade = int.tryParse(valorIdade) ?? 0;
    idade = idade.clamp(1, 120);
    
    if (idadeController.text != idade.toString()) {
      idadeController.text = idade.toString();
      idadeController.selection = TextSelection.fromPosition(
        TextPosition(offset: idadeController.text.length),
      );
    }

    // Cálculo automático da categoria de idade
    String categoriaIdade;
    if (idade >= 13 && idade <= 14) {
      categoriaIdade = "U15";
    } else if (idade >= 15 && idade <= 16) {
      categoriaIdade = "Sub-17";
    } else if (idade >= 17 && idade <= 18) {
      categoriaIdade = "Sub-19";
    } else if (idade >= 19 && idade <= 40) {
      categoriaIdade = "Elite";
    } else if (idade > 40) {
      categoriaIdade = "Masters";
    } else {
      categoriaIdade = "Idade não permitida";
    }

    categoriaIdadeController.text = categoriaIdade;
    
    // CORREÇÃO: Atualiza a categoria de peso quando a idade muda
    if (pesoController.text.isNotEmpty) {
      _atualizarCategoriaPeso(pesoController.text);
    }
  }

  // ==================== Cálculo de Categoria de Peso ====================
  void _atualizarCategoriaPeso(String valorPeso) {
    int peso = int.tryParse(valorPeso) ?? 0;
    peso = peso.clamp(0, 300);
    if (pesoController.text != peso.toString()) {
      pesoController.text = peso.toString();
      pesoController.selection = TextSelection.fromPosition(
        TextPosition(offset: pesoController.text.length),
      );
    }

    String categoriaPeso;
    
    // Obtém a categoria de idade para determinar as categorias de peso
    final idade = int.tryParse(idadeController.text) ?? 0;
    final isSub17 = idade >= 15 && idade <= 16;
    final isSub19 = idade >= 17 && idade <= 18;
    final isElite = idade >= 19 && idade <= 40;

    if (genero == 'Masculino') {
      if (isSub17) {
        // Categorias Sub-17 Masculino
        if (peso <= 46) {
          categoriaPeso = "Mínimo (M46kg)";
        } else if (peso <= 48) {
          categoriaPeso = "Mosca Leve (M48kg)";
        } else if (peso <= 50) {
          categoriaPeso = "Mosca (M50kg)";
        } else if (peso <= 52) {
          categoriaPeso = "Galo Leve (M52kg)";
        } else if (peso <= 54) {
          categoriaPeso = "Galo (M54kg)";
        } else if (peso <= 57) {
          categoriaPeso = "Pena (M57kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (M60kg)";
        } else if (peso <= 63) {
          categoriaPeso = "Meio-médio Leve (M63kg)";
        } else if (peso <= 66) {
          categoriaPeso = "Meio-médio (M66kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Meio-médio Leve (M70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (M75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (M80kg)";
        } else {
          categoriaPeso = "Pesado (M80+kg)";
        }
      } else if (isSub19 || isElite) {
        // Categorias Sub-19 e Elite Masculino (a partir de 2025)
        if (peso <= 50) {
          categoriaPeso = "Mosca (M50kg)";
        } else if (peso <= 55) {
          categoriaPeso = "Galo (M55kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (M60kg)";
        } else if (peso <= 65) {
          categoriaPeso = "Meio-médio (M65kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Supermeio-médio (M70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (M75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (M80kg)";
        } else if (peso <= 85) {
          categoriaPeso = "Cruzador (M85kg)";
        } else if (peso <= 90) {
          categoriaPeso = "Pesado (M90kg)";
        } else {
          categoriaPeso = "Superpesado (M90+kg)";
        }
      } else {
        // Para U15 e Masters, usa categorias mais simples
        if (peso <= 50) {
          categoriaPeso = "Mosca (M50kg)";
        } else if (peso <= 55) {
          categoriaPeso = "Galo (M55kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (M60kg)";
        } else if (peso <= 65) {
          categoriaPeso = "Meio-médio (M65kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Supermeio-médio (M70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (M75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (M80kg)";
        } else {
          categoriaPeso = "Pesado (M80+kg)";
        }
      }
    } else {
      // Categorias Femininas - CORRIGIDAS
      if (isSub17) {
        // Categorias Sub-17 Feminino (compartilhadas com masculino)
        if (peso <= 46) {
          categoriaPeso = "Mínimo (W46kg)";
        } else if (peso <= 48) {
          categoriaPeso = "Mosca Leve (W48kg)";
        } else if (peso <= 50) {
          categoriaPeso = "Mosca (W50kg)";
        } else if (peso <= 52) {
          categoriaPeso = "Galo Leve (W52kg)";
        } else if (peso <= 54) {
          categoriaPeso = "Galo (W54kg)";
        } else if (peso <= 57) {
          categoriaPeso = "Pena (W57kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (W60kg)";
        } else if (peso <= 63) {
          categoriaPeso = "Meio-médio Leve (W63kg)";
        } else if (peso <= 66) {
          categoriaPeso = "Meio-médio (W66kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Meio-médio Leve (W70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (W75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (W80kg)";
        } else {
          categoriaPeso = "Pesado (W80+kg)";
        }
      } else if (isSub19) {
        // Categorias Sub-19 Feminino (a partir de 2025)
        if (peso <= 48) {
          categoriaPeso = "Mínimo (W48kg)";
        } else if (peso <= 51) {
          categoriaPeso = "Mosca (W51kg)";
        } else if (peso <= 54) {
          categoriaPeso = "Galo (W54kg)";
        } else if (peso <= 57) {
          categoriaPeso = "Pena (W57kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (W60kg)";
        } else if (peso <= 65) {
          categoriaPeso = "Meio-médio (W65kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Meio-médio Leve (W70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (W75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (W80kg)";
        } else {
          categoriaPeso = "Pesado (W81+kg)";
        }
      } else if (isElite) {
        // Categorias Elite Feminino (a partir de 2025)
        if (peso <= 48) {
          categoriaPeso = "Mosca Leve (W48kg)";
        } else if (peso <= 51) {
          categoriaPeso = "Mosca (W51kg)";
        } else if (peso <= 54) {
          categoriaPeso = "Galo (W54kg)";
        } else if (peso <= 57) {
          categoriaPeso = "Pena (W57kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (W60kg)";
        } else if (peso <= 65) {
          categoriaPeso = "Meio-médio (W65kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Meio-médio Leve (W70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (W75kg)";
        } else if (peso <= 80) {
          categoriaPeso = "Meio-Pesado (W80kg)";
        } else {
          categoriaPeso = "Pesado (W81+kg)";
        }
      } else {
        // Para U15 e Masters, usa categorias mais simples
        if (peso <= 48) {
          categoriaPeso = "Mosca Leve (W48kg)";
        } else if (peso <= 51) {
          categoriaPeso = "Mosca (W51kg)";
        } else if (peso <= 54) {
          categoriaPeso = "Galo (W54kg)";
        } else if (peso <= 57) {
          categoriaPeso = "Pena (W57kg)";
        } else if (peso <= 60) {
          categoriaPeso = "Leve (W60kg)";
        } else if (peso <= 65) {
          categoriaPeso = "Meio-médio (W65kg)";
        } else if (peso <= 70) {
          categoriaPeso = "Meio-médio Leve (W70kg)";
        } else if (peso <= 75) {
          categoriaPeso = "Médio (W75kg)";
        } else {
          categoriaPeso = "Meio-Pesado (W80kg)";
        }
      }
    }

    categoriaPesoController.text = categoriaPeso;
  }

  void _validarCamposNumericos() {
    int idade = int.tryParse(idadeController.text) ?? 1;
    idade = idade.clamp(1, 120);
    if (idadeController.text != idade.toString()) {
      idadeController.text = idade.toString();
      idadeController.selection = TextSelection.fromPosition(
        TextPosition(offset: idadeController.text.length),
      );
    }

    int altura = int.tryParse(alturaController.text) ?? 1;
    altura = altura.clamp(1, 272);
    if (alturaController.text != altura.toString()) {
      alturaController.text = altura.toString();
      alturaController.selection = TextSelection.fromPosition(
        TextPosition(offset: alturaController.text.length),
      );
    }

    int peso = int.tryParse(pesoController.text) ?? 1;
    peso = peso.clamp(1, 300);
    if (pesoController.text != peso.toString()) {
      pesoController.text = peso.toString();
      pesoController.selection = TextSelection.fromPosition(
        TextPosition(offset: pesoController.text.length),
      );
    }
  }

  // ==================== Validação do Estado ====================
  void _validarEstado(String sigla) {
    String siglaUpper = sigla.toUpperCase().trim();
    
    // CORREÇÃO: Só valida quando tiver 2 caracteres
    if (siglaUpper.length == 2) {
      if (!estadosBrasileiros.contains(siglaUpper)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado inválido: $siglaUpper"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Mantém a conversão para maiúsculas
    if (estadoController.text != siglaUpper) {
      estadoController.text = siglaUpper;
      estadoController.selection = TextSelection.fromPosition(
        TextPosition(offset: estadoController.text.length),
      );
    }
  }

  // ==================== Salvar ====================
  Future<void> salvarLutador() async {
    final matricula = matriculaController.text.trim();
    final nome = nomeController.text.trim();
    final idade = int.tryParse(idadeController.text.trim()) ?? 0;
    final peso = int.tryParse(pesoController.text.trim()) ?? 0;
    final altura = int.tryParse(alturaController.text.trim()) ?? 0;
    final categoriaPeso = categoriaPesoController.text.trim();
    final categoriaIdade = categoriaIdadeController.text.trim();
    final equipe = equipeController.text.trim();
    final estado = estadoController.text.trim().toUpperCase();

    if (matricula.isEmpty ||
        nome.isEmpty ||
        idade <= 0 ||
        peso <= 0 ||
        altura <= 0 ||
        categoriaPeso.isEmpty ||
        categoriaIdade.isEmpty ||
        equipe.isEmpty ||
        estado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos corretamente")),
      );
      return;
    }

    // CORREÇÃO: Validação melhorada do estado
    if (estado.length != 2 || !estadosBrasileiros.contains(estado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite uma sigla de estado válida (ex: PR, RS, SP)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validação de idade mínima
    if (idade < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Idade mínima permitida é 13 anos")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      if (imagemBytes != null) {
        fotoBase64 = base64Encode(imagemBytes!);
      }

      final lutadorData = {
        "matricula": matricula,
        "nome": nome,
        "idade": idade,
        "genero": genero,
        "categoriaPeso": categoriaPeso,
        "categoriaIdade": categoriaIdade,
        "peso": peso,
        "altura": altura,
        "equipe": equipe,
        "estado": estado,
        "fotoBase64": fotoBase64 ?? '',
        "createdAt": FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('lutadores')
          .add(lutadorData);

      await docRef.update({
        'lutadorId': docRef.id,
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
            // Campo de Gênero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gênero",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            "Masculino",
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 'Masculino',
                          groupValue: genero,
                          onChanged: (value) {
                            setState(() {
                              genero = value!;
                              // Atualiza a categoria de peso quando o gênero muda
                              if (pesoController.text.isNotEmpty) {
                                _atualizarCategoriaPeso(pesoController.text);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            "Feminino",
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 'Feminino',
                          groupValue: genero,
                          onChanged: (value) {
                            setState(() {
                              genero = value!;
                              // Atualiza a categoria de peso quando o gênero muda
                              if (pesoController.text.isNotEmpty) {
                                _atualizarCategoriaPeso(pesoController.text);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Idade",
              idadeController,
              teclado: TextInputType.number,
              onChanged: (valor) {
                _validarCamposNumericos();
                _calcularIdadeECategoria(valor);
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hintText: "Digite a idade",
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Categoria de Idade (automática)",
              categoriaIdadeController,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Peso (kg)",
              pesoController,
              teclado: TextInputType.number,
              onChanged: (valor) {
                _validarCamposNumericos();
                _atualizarCategoriaPeso(valor);
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hintText: "Digite o peso",
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Categoria de Peso (automática)",
              categoriaPesoController,
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
            const SizedBox(height: 12),
            _buildTextField("Equipe", equipeController),
            const SizedBox(height: 12),
            _buildTextField(
              "Estado (sigla)",
              estadoController,
              teclado: TextInputType.text,
              onChanged: _validarEstado,
              inputFormatters: [
                LengthLimitingTextInputFormatter(2),
                UpperCaseTextFormatter(),
              ],
              hintText: "Ex: PR, RS, SP",
            ),
            const SizedBox(height: 8),
            _buildEstadoInfo(),
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
    String? hintText,
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
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildEstadoInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "Digite a sigla do estado (ex: PR, RS, SP, RJ, MG)\n"
        "Será validado automaticamente",
        style: TextStyle(color: Colors.white70, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Formatter para converter texto para maiúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}