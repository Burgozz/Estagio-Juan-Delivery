class ApiConfig {
  // IP do PC na rede Wi-Fi (rode `ipconfig` se mudar).
  // Use 'localhost' para rodar no navegador/desktop ou '10.0.2.2' no emulador Android.
  static const String host = 'localhost';
  static const int porta = 8080;

  static const String baseUrl = 'http://$host:$porta';
}
