import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final cachedTheme = await ThemeModeNotifier.loadFromPrefs();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((_) => ThemeModeNotifier(cachedTheme)),
      ],
      child: const HanlyApp(),
    ),
  );
}
