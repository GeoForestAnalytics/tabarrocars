import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsAppService {
  // Função estática para não precisar instanciar a classe
  static Future<void> abrirWhatsApp({
    required String numeroTelefone, // Ex: "5511999999999"
    required String mensagem,
    required BuildContext context,
  }) async {
    
    // 1. Limpar o número (remover parênteses, traços, espaços)
    final numeroLimpo = numeroTelefone.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Criar a URL do WhatsApp
    // O Uri.encodeComponent garante que espaços e acentos na mensagem não quebrem o link
    final url = Uri.parse(
      "https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}",
    );

    // 3. Tentar abrir
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Força abrir no App do Zap e não no navegador interno
        );
      } else {
        // Se falhar (ex: rodando no simulador sem zap instalado), avisa o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } catch (e) {
      print("Erro ao abrir WhatsApp: $e");
    }
  }
}