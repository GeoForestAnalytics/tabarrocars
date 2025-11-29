import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_settings.dart';
import '../models/veiculo_model.dart';
import '../services/veiculo_service.dart';

class CadastroVeiculoScreen extends StatefulWidget {
  final Veiculo? veiculoParaEditar;

  const CadastroVeiculoScreen({super.key, this.veiculoParaEditar});

  @override
  State<CadastroVeiculoScreen> createState() => _CadastroVeiculoScreenState();
}

class _CadastroVeiculoScreenState extends State<CadastroVeiculoScreen> {
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();
  final _kmController = TextEditingController();
  final _corController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  List<XFile> _novasImagens = [];
  List<String> _fotosExistentes = [];
  
  bool _isLoading = false;
  final VeiculoService _veiculoService = VeiculoService();

  @override
  void initState() {
    super.initState();
    if (widget.veiculoParaEditar != null) {
      final v = widget.veiculoParaEditar!;
      _modeloController.text = v.modelo;
      _anoController.text = v.ano.toString();
      _kmController.text = v.km.toString();
      _corController.text = v.cor;
      _valorController.text = v.valor.toStringAsFixed(2);
      _descricaoController.text = v.descricao;
      _fotosExistentes = List.from(v.fotos);
    }
  }

  Future<void> _selecionarImagens() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> imagens = await picker.pickMultiImage();
    if (imagens.isNotEmpty) {
      setState(() => _novasImagens.addAll(imagens));
    }
  }

  Future<List<String>> _uploadTodasImagens() async {
    List<String> urls = [];
    for (var imagemXFile in _novasImagens) {
      String nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString() + "_" + urls.length.toString();
      Reference ref = FirebaseStorage.instance.ref().child('veiculos/$nomeArquivo.jpg');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imagemXFile.readAsBytes();
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        File file = File(imagemXFile.path);
        uploadTask = ref.putFile(file);
      }
      
      TaskSnapshot taskSnapshot = await uploadTask;
      String url = await taskSnapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _salvarVeiculo() async {
    if (_modeloController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha Modelo e Valor')));
      return;
    }

    if (_novasImagens.isEmpty && _fotosExistentes.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma foto!')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> novasUrls = [];
      if (_novasImagens.isNotEmpty) novasUrls = await _uploadTodasImagens();

      List<String> listaFinalDeFotos = [..._fotosExistentes, ...novasUrls];

      Veiculo veiculoMontado = Veiculo(
        id: widget.veiculoParaEditar?.id,
        modelo: _modeloController.text,
        ano: int.tryParse(_anoController.text) ?? 0,
        km: double.tryParse(_kmController.text) ?? 0,
        cor: _corController.text,
        valor: double.tryParse(_valorController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        descricao: _descricaoController.text,
        fotos: listaFinalDeFotos,
      );

      if (widget.veiculoParaEditar == null) {
        await _veiculoService.adicionarVeiculo(veiculoMontado);
      } else {
        await _veiculoService.atualizarVeiculo(widget.veiculoParaEditar!.id!, veiculoMontado);
      }
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _estiloInput(String label, Color corTexto) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: corTexto.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: corTexto.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: corTexto, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDark;

    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);
    
    final Color corTexto = isDark ? dourado : azulMarinho;
    final List<Color> gradiente = isDark 
        ? [const Color(0xFF1E293B), Colors.black] 
        : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.veiculoParaEditar == null ? "NOVO VEÍCULO" : "EDITAR VEÍCULO",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: corTexto, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: corTexto),
      ),
      body: Container(
        // O Container ocupa a tela toda com o gradiente
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: gradiente)),
        
        // CORREÇÃO DE LARGURA AQUI:
        child: _isLoading 
        ? Center(child: CircularProgressIndicator(color: corTexto))
        : Center( // 1. Centraliza o conteúdo na tela
            child: ConstrainedBox( // 2. Trava a largura máxima
              constraints: const BoxConstraints(maxWidth: 700), // Largura ideal para formulários web
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Fotos do Veículo", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    const SizedBox(height: 10),
                    _buildPreviewFotos(corTexto),
                    
                    const SizedBox(height: 25),
                    
                    TextField(controller: _modeloController, style: TextStyle(color: corTexto), decoration: _estiloInput("Modelo", corTexto)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _anoController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Ano", corTexto))),
                        const SizedBox(width: 15),
                        Expanded(child: TextField(controller: _kmController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Km", corTexto))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: _corController, style: TextStyle(color: corTexto), decoration: _estiloInput("Cor", corTexto)),
                    const SizedBox(height: 15),
                    TextField(controller: _valorController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Valor (R\$)", corTexto)),
                    const SizedBox(height: 15),
                    TextField(controller: _descricaoController, maxLines: 3, style: TextStyle(color: corTexto), decoration: _estiloInput("Descrição", corTexto)),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _salvarVeiculo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corTexto,
                          foregroundColor: isDark ? azulMarinho : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: Text(
                          widget.veiculoParaEditar == null ? "CADASTRAR VEÍCULO" : "SALVAR ALTERAÇÕES",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildPreviewFotos(Color corIcone) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _selecionarImagens,
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: corIcone.withOpacity(0.1),
                border: Border.all(color: corIcone.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 30, color: corIcone),
                  Text("Adicionar", style: TextStyle(color: corIcone, fontSize: 12))
                ],
              ),
            ),
          ),
          ..._fotosExistentes.map((url) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover)),
          )),
          ..._novasImagens.map((xFile) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb 
                    ? Image.network(xFile.path, width: 100, height: 100, fit: BoxFit.cover)
                    : Image.file(File(xFile.path), width: 100, height: 100, fit: BoxFit.cover),
                ),
                const Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: Colors.green, size: 20))
              ],
            ),
          )),
        ],
      ),
    );
  }
}