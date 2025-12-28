import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanapp/widgets/permission_dialogs.dart';
import 'package:scanapp/services/permission_service.dart';

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

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Scan Documents',
      description:
          'Capture crisp, clear scans of documents, receipts, and more using your camera.',
      icon: Icons.document_scanner_outlined,
      color: const Color(0xFF1F77F5),
    ),
    OnboardingPage(
      title: 'Edit & Enhance',
      description:
          'Adjust brightness, contrast, and more. Auto-enhance for perfect results every time.',
      icon: Icons.tune_outlined,
      color: const Color(0xFF7C3AED),
    ),
    OnboardingPage(
      title: 'Save & Share',
      description:
          'Export as PDF, PNG, or JPEG. Share instantly with anyone via email, messaging, or cloud storage.',
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
      final permissionService = PermissionService();

      // Request camera permission
      final cameraStatus = await permissionService.requestCameraPermission();
      if (!cameraStatus.isGranted && mounted) {
        PermissionDialogs.showPermissionDialog(
          context: context,
          title: 'Camera Access',
          description:
              'ScanApp needs camera access to scan documents and QR codes.',
          permissionName: 'Camera',
          onAllow: () async {
            await permissionService.requestCameraPermission();
          },
          onDeny: () {},
        );
        return;
      }

      // Request photos permission
      final photosStatus = await permissionService.requestPhotosPermission();
      if (!photosStatus.isGranted && mounted) {
        PermissionDialogs.showPermissionDialog(
          context: context,
          title: 'Photo Library Access',
          description:
              'ScanApp needs access to your photo library to pick and save documents.',
          permissionName: 'Photos',
          onAllow: () async {
            await permissionService.requestPhotosPermission();
          },
          onDeny: () {},
        );
        return;
      }

      // Save onboarding completed status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      if (mounted) {
        widget.onComplete();
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermissions = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
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
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
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
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      if (_currentPage < pages.length - 1)
                        Expanded(
                          child: TextButton(
                            onPressed: _skipOnboarding,
                            child: const Text(
                              'Skip',
                              style: TextStyle(color: Colors.grey),
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
                                      ? 'Get Started'
                                      : 'Next',
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
