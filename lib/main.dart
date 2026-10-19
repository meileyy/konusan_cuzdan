import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ekran dönünce yerleşim bozulmasın diye sadece dikey kullanım.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KonusanCuzdanApp(),
    ),
  );
}

class KonusanCuzdanApp extends StatelessWidget {
  const KonusanCuzdanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konuşan Cüzdan',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
