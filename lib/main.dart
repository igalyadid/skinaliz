import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/clients_list_screen.dart';

late List<CameraDescription> appCameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appCameras = await availableCameras();
  runApp(const SkinalizApp());
}

class SkinalizApp extends StatelessWidget {
  const SkinalizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skinaliz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('he'),
        Locale('ru'),
      ],
      home: const ClientsListScreen(),
    );
  }
}
