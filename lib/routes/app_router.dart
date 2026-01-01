import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/screens/splash_screen.dart';
import 'package:scanapp/screens/onboarding_screen.dart';
import 'package:scanapp/screens/home_screen.dart';
import 'package:scanapp/screens/document_scanner_screen.dart';
import 'package:scanapp/screens/image_editing_screen.dart';
import 'package:scanapp/screens/document_builder_screen.dart';
import 'package:scanapp/screens/documents_list_screen.dart';
import 'package:scanapp/screens/qr_scanner_screen.dart';
import 'package:scanapp/screens/text_export_screen.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';

class AppRouter {
  // Route names for easy reference
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const camera = '/camera';
  static const ocrCamera = '/camera/ocr';
  static const imageEditing = '/edit';
  static const textExport = '/export-text';
  static const documentBuilder = '/builder';
  static const documentsList = '/documents';
  static const qrScanner = '/qr-scanner';

  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () {
            context.go(home);
          },
        ),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: camera,
        name: 'camera',
        builder: (context, state) {
          // Use native document scanner with auto edge detection
          // Allow multiple images continuously
          return DocumentScannerScreen(
            isNewSession: true, // Flag to clear previous session
            allowMultiple: true, // Allow continuous scanning
            onImagesScanned: (List<File> files) {
              if (files.isNotEmpty) {
                // Add all scanned images to document builder
                final provider = context.read<DocumentBuilderProvider>();
                for (final file in files) {
                  provider.addImage(file);
                }
                // Load first image for preview in edit screen
                context.read<ImageEditingProvider>().loadImage(files.first);
                // Replace scanner with edit screen to avoid returning to 'preparing'
                context.replace(imageEditing);
              }
            },
          );
        },
      ),
      GoRoute(
        path: ocrCamera,
        name: 'ocrCamera',
        builder: (context, state) {
          // Camera for OCR - will open directly to OCR tab
          return DocumentScannerScreen(
            isNewSession: true,
            allowMultiple: true,
            onImagesScanned: (List<File> files) {
              if (files.isNotEmpty) {
                final provider = context.read<DocumentBuilderProvider>();
                for (final file in files) {
                  provider.addImage(file);
                }
                context.read<ImageEditingProvider>().loadImage(files.first);
                // Navigate to edit screen with OCR tab open (initialTabIndex: 1)
                context.replace(
                  imageEditing,
                  extra: {'initialTab': 1},
                );
              }
            },
          );
        },
      ),
      GoRoute(
        path: imageEditing,
        name: 'imageEditing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTab = extra?['initialTab'] as int? ?? 0;
          return ImageEditingScreen(
            initialTabIndex: initialTab,
            onEditComplete: () {
              context.go(documentBuilder);
            },
          );
        },
      ),
      GoRoute(
        path: documentBuilder,
        name: 'documentBuilder',
        builder: (context, state) => DocumentBuilderScreen(
          onDocumentBuilt: () {
            // Clear happens on next scan session via isNewSession flag
            context.go(home);
          },
        ),
      ),
      GoRoute(
        path: textExport,
        name: 'textExport',
        builder: (context, state) {
          final extractedText = state.extra as String? ?? '';
          return TextExportScreen(extractedText: extractedText);
        },
      ),
      GoRoute(
        path: documentsList,
        name: 'documentsList',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: qrScanner,
        name: 'qrScanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
    ],
    // Handle redirect for first launch
    redirect: (context, state) {
      // You can add first-launch detection logic here
      // For now, we redirect from splash to onboarding after a delay
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route not found: ${state.uri}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
