import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanapp/widgets/permission_dialogs.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  List<OnboardingPage> _getPages(AppLocalizations l10n) => [
        OnboardingPage(
          title: l10n.scanDocumentsTitle,
          description: l10n.scanDocumentsDesc,
          icon: Icons.document_scanner_outlined,
          color: const Color(0xFF1F77F5),
        ),
        OnboardingPage(
          title: l10n.editEnhanceTitle,
          description: l10n.editEnhanceDesc,
          icon: Icons.tune_outlined,
          color: const Color(0xFF7C3AED),
        ),
        OnboardingPage(
          title: l10n.saveShareTitle,
          description: l10n.saveShareDesc,
          icon: Icons.share_outlined,
          color: const Color(0xFF06B6D4),
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequestingPermissions = true);

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      debugPrint('Camera permission status: ${cameraStatus.toString()}');

      if (!cameraStatus.isGranted && mounted) {
        PermissionDialogs.showPermissionDialog(
          context: context,
          title: 'Camera Access',
          description:
              'ScanApp needs camera access to scan documents and QR codes.',
          permissionName: 'Camera',
          onAllow: () async {
            // Request again after user taps allow
            await Permission.camera.request();
            if (mounted) {
              _requestPhotosPermissionStep();
            }
          },
          onDeny: () {
            // User denied, complete anyway or exit
            _completeOnboarding();
          },
        );
        return;
      }

      // Camera granted, request photos
      _requestPhotosPermissionStep();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      // Complete onboarding even if there's an error
      _completeOnboarding();
    }
  }

  Future<void> _requestPhotosPermissionStep() async {
    try {
      // For Android 11+, try photos first, fallback to storage
      PermissionStatus photosStatus;

      if (Platform.isAndroid) {
        // Try photos permission (Android 13+)
        photosStatus = await Permission.photos.status;

        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }

        debugPrint('Photos permission status: ${photosStatus.toString()}');

        // If photos denied, try storage permission (Android 11-12)
        if (photosStatus.isDenied) {
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isDenied) {
            photosStatus = await Permission.storage.request();
            debugPrint('Storage permission status: ${photosStatus.toString()}');
          } else {
            photosStatus = storageStatus;
          }
        }
      } else {
        // iOS
        photosStatus = await Permission.photos.status;
        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }
      }

      if (!photosStatus.isGranted && !photosStatus.isLimited && mounted) {
        PermissionDialogs.showPermissionDialog(
          context: context,
          title: 'Photo Library Access',
          description:
              'ScanApp needs access to your photo library to pick and save documents.',
          permissionName: 'Photos',
          onAllow: () async {
            // Request again after user taps allow
            await Permission.photos.request();
            if (mounted) {
              _completeOnboarding();
            }
          },
          onDeny: () {
            // User denied, complete anyway
            _completeOnboarding();
          },
        );
        return;
      }

      // All permissions done
      _completeOnboarding();
    } catch (e) {
      debugPrint('Error in photos permission step: $e');
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completed status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      widget.onComplete();
    }
  }

  void _nextPage() {
    // We have 3 pages (0, 1, 2), so check if we're on the last page
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _requestPermissions();
    }
  }

  void _skipOnboarding() {
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _getPages(l10n);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return OnboardingPageWidget(page: page);
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: pages[_currentPage].color,
                      dotColor: Colors.grey.withValues(alpha: 0.3),
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(l10n.back),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      if (_currentPage < pages.length - 1)
                        Expanded(
                          child: TextButton(
                            onPressed: _skipOnboarding,
                            child: Text(
                              l10n.skip,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      if (_currentPage < pages.length - 1)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isRequestingPermissions ? null : _nextPage,
                          child: _isRequestingPermissions
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentPage == pages.length - 1
                                      ? l10n.getStarted
                                      : l10n.next,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
