import 'dart:io';
import 'package:flutter/foundation.dart'; // Importante para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_settings.dart';
import '../models/imovel_model.dart';
import '../services/imovel_service.dart';

class CadastroImovelScreen extends StatefulWidget {
  final Imovel? imovelParaEditar;
  const CadastroImovelScreen({super.key, this.imovelParaEditar});

  @override
  State<CadastroImovelScreen> createState() => _CadastroImovelScreenState();
}

class _CadastroImovelScreenState extends State<CadastroImovelScreen> {
  final _tituloController = TextEditingController();
  final _localController = TextEditingController();
  final _quartosController = TextEditingController();
  final _areaController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  List<XFile> _novasImagens = [];
  List<String> _fotosExistentes = [];
  
  double? _latitude;
  double? _longitude;
  bool _obtendoLocalizacao = false;

  bool _isLoading = false;
  final ImovelService _imovelService = ImovelService();

  @override
  void initState() {
    super.initState();
    if (widget.imovelParaEditar != null) {
      final i = widget.imovelParaEditar!;
      _tituloController.text = i.titulo;
      _localController.text = i.localizacao;
      _quartosController.text = i.quartos.toString();
      _areaController.text = i.area.toString();
      _valorController.text = i.valor.toStringAsFixed(2);
      _descricaoController.text = i.descricao;
      _fotosExistentes = List.from(i.fotos);
      _latitude = i.latitude;
      _longitude = i.longitude;
    }
  }

  Future<void> _capturarLocalizacao() async {
    setState(() => _obtendoLocalizacao = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permissão de localização negada";
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização capturada! 📍')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _obtendoLocalizacao = false);
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
      String nomeArquivo = "imovel_${DateTime.now().millisecondsSinceEpoch}_${urls.length}";
      Reference ref = FirebaseStorage.instance.ref().child('imoveis/$nomeArquivo.jpg');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imagemXFile.readAsBytes();
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        File file = File(imagemXFile.path);
        uploadTask = ref.putFile(file);
      }
      
      urls.add(await (await uploadTask).ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _salvarImovel() async {
    if (_tituloController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha Título e Valor')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      List<String> novasUrls = [];
      if (_novasImagens.isNotEmpty) novasUrls = await _uploadTodasImagens();

      Imovel imovelMontado = Imovel(
        id: widget.imovelParaEditar?.id,
        titulo: _tituloController.text,
        localizacao: _localController.text,
        quartos: int.tryParse(_quartosController.text) ?? 0,
        area: double.tryParse(_areaController.text) ?? 0,
        valor: double.tryParse(_valorController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        descricao: _descricaoController.text,
        fotos: [..._fotosExistentes, ...novasUrls],
        latitude: _latitude,
        longitude: _longitude,
      );

      if (widget.imovelParaEditar == null) {
        await _imovelService.adicionarImovel(imovelMontado);
      } else {
        await _imovelService.atualizarImovel(widget.imovelParaEditar!.id!, imovelMontado);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: corTexto.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: corTexto, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDark;

    final Color azulMarinho = const Color.fromARGB(255, 2, 56, 83);
    final Color dourado = const Color(0xFFEBE4AB);
    final Color corTexto = isDark ? dourado : azulMarinho;
    final List<Color> gradiente = isDark ? [const Color(0xFF1E293B), Colors.black] : [const Color(0xFFFFFDF0), const Color(0xFFEBE4AB)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.imovelParaEditar == null ? "NOVO IMÓVEL" : "EDITAR IMÓVEL", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: corTexto, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: corTexto),
      ),
      body: Container(
        // Fundo Gradiente Tela Cheia
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: gradiente)),
        
        // CORREÇÃO DE LARGURA AQUI:
        child: _isLoading 
        ? Center(child: CircularProgressIndicator(color: corTexto)) 
        : Center( // 1. Centraliza
            child: ConstrainedBox( // 2. Limita largura
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Fotos do Imóvel", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    const SizedBox(height: 10),
                    _buildPreviewFotos(corTexto),
                    const SizedBox(height: 25),
                    
                    TextField(controller: _tituloController, style: TextStyle(color: corTexto), decoration: _estiloInput("Título (Ex: Casa Centro)", corTexto)),
                    const SizedBox(height: 15),
                    TextField(controller: _localController, style: TextStyle(color: corTexto), decoration: _estiloInput("Endereço", corTexto)),
                    
                    const SizedBox(height: 15),
                    // --- BOTÃO GPS ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: corTexto.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: corTexto.withOpacity(0.3))),
                      child: Column(
                        children: [
                          if (_latitude != null) Text("Coordenadas Salvas ✅", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          ElevatedButton.icon(
                            onPressed: _obtendoLocalizacao ? null : _capturarLocalizacao,
                            icon: _obtendoLocalizacao ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                            label: Text(_obtendoLocalizacao ? "Obtendo..." : "USAR LOCALIZAÇÃO ATUAL"),
                            style: ElevatedButton.styleFrom(backgroundColor: corTexto, foregroundColor: isDark ? azulMarinho : Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(child: TextField(controller: _quartosController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Quartos", corTexto))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _areaController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Área (m²)", corTexto))),
                    ]),
                    const SizedBox(height: 15),
                    TextField(controller: _valorController, keyboardType: TextInputType.number, style: TextStyle(color: corTexto), decoration: _estiloInput("Valor (R\$)", corTexto)),
                    const SizedBox(height: 15),
                    TextField(controller: _descricaoController, maxLines: 3, style: TextStyle(color: corTexto), decoration: _estiloInput("Descrição", corTexto)),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _salvarImovel,
                        style: ElevatedButton.styleFrom(backgroundColor: corTexto, foregroundColor: isDark ? azulMarinho : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("SALVAR IMÓVEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _selecionarImagens,
            child: Container(
              width: 80, margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: corIcone.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: corIcone.withOpacity(0.3))),
              child: Icon(Icons.add_a_photo, color: corIcone),
            ),
          ),
          ..._fotosExistentes.map((url) => Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, width: 100, fit: BoxFit.cover)))),
          ..._novasImagens.map((xFile) => Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: kIsWeb ? Image.network(xFile.path, width: 100, fit: BoxFit.cover) : Image.file(File(xFile.path), width: 100, fit: BoxFit.cover)))),
        ],
      ),
    );
  }
}