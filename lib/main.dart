import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/theme.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

class AgrocomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  HttpOverrides.global = AgrocomHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await ApiService().init();

  runApp(const AgrocomApp());
}

class AgrocomApp extends StatelessWidget {
  const AgrocomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGROCOM',
      debugShowCheckedModeBanner: false,
      theme: AgriTheme.theme,
      home: const SplashScreen(),
    );
  }
}
