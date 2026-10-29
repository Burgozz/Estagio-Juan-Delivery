import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/carrinho/controllers/carrinho_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider.value(
      value: CarrinhoController.instance,
      child: const MyApp(),
    ),
  );
}
