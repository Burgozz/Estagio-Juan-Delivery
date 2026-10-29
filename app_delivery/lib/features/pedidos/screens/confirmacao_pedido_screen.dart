import 'package:flutter/material.dart';
import 'detalhes_pedido_screen.dart';
import '../../../core/theme/app_colors.dart';

/// Tela exibida logo após a criação bem-sucedida do pedido.
class ConfirmacaoPedidoScreen extends StatelessWidget {
  final int pedidoId;

  const ConfirmacaoPedidoScreen({super.key, required this.pedidoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: kCreme, size: 120),
              const SizedBox(height: 28),
              const Text(
                'Pedido Realizado!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seu pedido foi recebido e está sendo processado',
                textAlign: TextAlign.center,
                style: TextStyle(color: kCreme, fontSize: 15),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => DetalhesPedidoScreen(pedidoId: pedidoId)),
                  ),
                  child: const Text(
                    'VER DETALHES DO PEDIDO',
                    style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
