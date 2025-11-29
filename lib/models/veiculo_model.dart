class Veiculo {
  String? id;
  String modelo;
  int ano;
  double km;
  String cor;
  double valor;
  String descricao;
  List<String> fotos; // <--- Mudamos de String única para Lista

  Veiculo({
    this.id,
    required this.modelo,
    required this.ano,
    required this.km,
    required this.cor,
    required this.valor,
    required this.descricao,
    required this.fotos,
  });

  Map<String, dynamic> toMap() {
    return {
      'modelo': modelo,
      'ano': ano,
      'km': km,
      'cor': cor,
      'valor': valor,
      'descricao': descricao,
      'fotos': fotos, // Salva a lista no Firebase
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map, String id) {
    // Lógica de segurança:
    // Se tiver a lista 'fotos', usa ela.
    // Se não tiver (carro antigo), tenta pegar 'imagemUrl' e coloca numa lista.
    List<String> listaFotos = [];
    if (map['fotos'] != null) {
      listaFotos = List<String>.from(map['fotos']);
    } else if (map['imagemUrl'] != null) {
      listaFotos = [map['imagemUrl']];
    }

    return Veiculo(
      id: id,
      modelo: map['modelo'] ?? '',
      ano: map['ano'] ?? 0,
      km: (map['km'] ?? 0).toDouble(),
      cor: map['cor'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      descricao: map['descricao'] ?? '',
      fotos: listaFotos,
    );
  }
}