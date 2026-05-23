import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar fechas para español
  await initializeDateFormatting('es_AR', null);

  // Inicializar sqflite para Windows (FFI)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Sin bordes del sistema en Windows
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Google Fonts sin conexión (usa caché local)
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    const ProviderScope(
      child: LaChapitaApp(),
    ),
  );
}