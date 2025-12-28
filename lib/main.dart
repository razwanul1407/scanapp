import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:scanapp/services/database_service.dart';
import 'package:scanapp/theme/app_theme.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/providers/language_provider.dart';
import 'package:scanapp/l10n/app_localizations.dart';
import 'package:scanapp/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database in background to prevent frame skips
  DatabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DocumentsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ImageEditingProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentBuilderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp.router(
            title: 'ScanApp - Document Scanner',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            locale: languageProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLanguages
                .map((lang) => lang.locale)
                .toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Integrate Upgrader with GoRouter
            builder: (context, child) {
              return UpgradeAlert(
                navigatorKey: AppRouter.router.routerDelegate.navigatorKey,
                upgrader: Upgrader(
                  languageCode: languageProvider.currentLocale.languageCode,
                  durationUntilAlertAgain: const Duration(days: 1),
                  debugLogging: false,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
