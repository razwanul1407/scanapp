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
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';

class AppRouter {
  // Route names for easy reference
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const camera = '/camera';
  static const cameraAddMore = '/camera/add-more';
  static const imageEditing = '/edit';
  static const imageEditingAddMore = '/edit/add-more';
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
          return DocumentScannerScreen(
            isNewSession: true, // Flag to clear previous session
            onImagesScanned: (List<File> files) {
              if (files.isNotEmpty) {
                context.read<ImageEditingProvider>().loadImage(files.first);
                // Replace scanner with edit screen to avoid returning to 'preparing'
                context.replace(imageEditing);
              }
            },
          );
        },
      ),
      GoRoute(
        path: cameraAddMore,
        name: 'cameraAddMore',
        builder: (context, state) {
          // Scanner for adding more pages to existing document
          return DocumentScannerScreen(
            allowMultiple: true,
            onImagesScanned: (List<File> files) {
              if (files.isNotEmpty) {
                // Add all scanned images directly to document builder
                final provider = context.read<DocumentBuilderProvider>();
                for (final file in files) {
                  provider.addImage(file);
                }
                context.go(documentBuilder);
              }
            },
          );
        },
      ),
      GoRoute(
        path: imageEditing,
        name: 'imageEditing',
        builder: (context, state) => ImageEditingScreen(
          onEditComplete: () {
            // After editing, save image and go to document builder
            _saveEditedImageAndNavigate(context, documentBuilder);
          },
        ),
      ),
      GoRoute(
        path: imageEditingAddMore,
        name: 'imageEditingAddMore',
        builder: (context, state) => ImageEditingScreen(
          onEditComplete: () {
            // After editing, save image and add to builder
            _saveEditedImageAndNavigate(context, documentBuilder);
          },
        ),
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

  /// Helper to save the edited image and navigate
  static Future<void> _saveEditedImageAndNavigate(
    BuildContext context,
    String destination,
  ) async {
    final editProvider = context.read<ImageEditingProvider>();
    final builderProvider = context.read<DocumentBuilderProvider>();

    // Get the processed image bytes and save to a file
    final processedBytes = editProvider.processedImageBytes;
    if (processedBytes != null) {
      // Create a temporary file with the processed image
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/scan_$timestamp.jpg');
      await tempFile.writeAsBytes(processedBytes);
      builderProvider.addImage(tempFile);
    } else if (editProvider.originalImage != null) {
      // Fallback to original if no processing was done
      builderProvider.addImage(editProvider.originalImage!);
    }

    if (context.mounted) {
      context.go(destination);
    }
  }
}
