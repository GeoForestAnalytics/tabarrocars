class Imovel {
  String? id;
  String titulo;
  String localizacao;
  int quartos;
  double area;
  double valor;
  String descricao;
  List<String> fotos;
  // NOVOS CAMPOS:
  double? latitude;
  double? longitude;

  Imovel({
    this.id,
    required this.titulo,
    required this.localizacao,
    required this.quartos,
    required this.area,
    required this.valor,
    required this.descricao,
    required this.fotos,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'localizacao': localizacao,
      'quartos': quartos,
      'area': area,
      'valor': valor,
      'descricao': descricao,
      'fotos': fotos,
      'latitude': latitude,   // Salva Lat
      'longitude': longitude, // Salva Long
    };
  }

  factory Imovel.fromMap(Map<String, dynamic> map, String id) {
    List<String> listaFotos = [];
    if (map['fotos'] != null) {
      listaFotos = List<String>.from(map['fotos']);
    } else if (map['imagemUrl'] != null) {
      listaFotos = [map['imagemUrl']];
    }

    return Imovel(
      id: id,
      titulo: map['titulo'] ?? '',
      localizacao: map['localizacao'] ?? '',
      quartos: map['quartos'] ?? 0,
      area: (map['area'] ?? 0).toDouble(),
      valor: (map['valor'] ?? 0).toDouble(),
      descricao: map['descricao'] ?? '',
      fotos: listaFotos,
      // Recupera Lat/Long (pode ser null)
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}