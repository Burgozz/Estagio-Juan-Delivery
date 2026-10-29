import 'package:flutter/material.dart';

/// Cores do app (identidade visual). Ver CLAUDE.md.
///
/// Fonte única das cores usadas em mais de uma tela. Paletas específicas de
/// uma tela (cores por categoria, por status de pedido, banners) ficam na
/// própria tela.

/// Vinho escuro: AppBar, botões principais, destaques.
const kPrimary = Color(0xFF3C0731);

/// Vinho médio: fim de gradientes e botão das telas de autenticação.
const kGradienteFim = Color(0xFF5C1151);

/// Fundo das telas.
const kBackground = Color(0xFFFAFAFA);

/// Fundo de cards e campos.
const kSurface = Color(0xFFFFFFFF);

const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);

/// Creme usado em títulos sobre fundo vinho e elementos de destaque.
const kCreme = Color(0xFFF5E6C8);

/// Lilás claro: fundo de campos preenchidos automaticamente (ex.: CEP).
const kAutoFillColor = Color(0xFFF0E8EF);

/// Vermelho de ações destrutivas e do asterisco de campo obrigatório.
const kPerigo = Color(0xFFD32F2F);

/// Vermelho dos erros inline sobre fundo escuro.
const kErroInline = Color(0xFFFF6B6B);
