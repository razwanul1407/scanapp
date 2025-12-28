import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? _scannedValue;
  BarcodeType? _barcodeType;
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue != _scannedValue) {
        setState(() {
          _scannedValue = barcode.rawValue;
          _barcodeType = barcode.type;
          _isScanning = false;
        });
        // Haptic feedback
        HapticFeedback.mediumImpact();
        // Show result bottom sheet
        _showResultBottomSheet();
      }
    }
  }

  void _showResultBottomSheet() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Result header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForBarcodeType(_barcodeType),
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scanResult,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        _getBarcodeTypeName(_barcodeType),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scanned content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                _scannedValue ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy,
                    label: l10n.copyToClipboard,
                    onTap: _copyToClipboard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: l10n.share,
                    onTap: _shareResult,
                  ),
                ),
              ],
            ),

            // Show "Open Link" button if it's a URL
            if (_isUrl(_scannedValue)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  icon: Icons.open_in_new,
                  label: l10n.openLink,
                  onTap: _openLink,
                  isPrimary: true,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Scan again button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _scannedValue = null;
                    _barcodeType = null;
                    _isScanning = true;
                  });
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.scanAgain),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      // When bottom sheet is dismissed, resume scanning
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconData _getIconForBarcodeType(BarcodeType? type) {
    switch (type) {
      case BarcodeType.url:
        return Icons.link;
      case BarcodeType.email:
        return Icons.email;
      case BarcodeType.phone:
        return Icons.phone;
      case BarcodeType.sms:
        return Icons.sms;
      case BarcodeType.wifi:
        return Icons.wifi;
      case BarcodeType.geo:
        return Icons.location_on;
      case BarcodeType.contactInfo:
        return Icons.contact_page;
      case BarcodeType.calendarEvent:
        return Icons.event;
      case BarcodeType.product:
        return Icons.shopping_bag;
      case BarcodeType.isbn:
        return Icons.book;
      default:
        return Icons.qr_code;
    }
  }

  String _getBarcodeTypeName(BarcodeType? type) {
    switch (type) {
      case BarcodeType.url:
        return 'URL';
      case BarcodeType.email:
        return 'Email';
      case BarcodeType.phone:
        return 'Phone';
      case BarcodeType.sms:
        return 'SMS';
      case BarcodeType.wifi:
        return 'WiFi';
      case BarcodeType.geo:
        return 'Location';
      case BarcodeType.contactInfo:
        return 'Contact';
      case BarcodeType.calendarEvent:
        return 'Event';
      case BarcodeType.product:
        return 'Product';
      case BarcodeType.isbn:
        return 'ISBN';
      case BarcodeType.text:
        return 'Text';
      default:
        return 'QR Code';
    }
  }

  bool _isUrl(String? value) {
    if (value == null) return false;
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('www.');
  }

  void _copyToClipboard() {
    if (_scannedValue != null) {
      Clipboard.setData(ClipboardData(text: _scannedValue!));
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.copiedToClipboard),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _shareResult() {
    if (_scannedValue != null) {
      SharePlus.instance.share(ShareParams(text: _scannedValue!));
    }
  }

  Future<void> _openLink() async {
    if (_scannedValue != null) {
      String url = _scannedValue!;
      if (url.startsWith('www.')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.qrScannerTitle),
        actions: [
          // Flash toggle button
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Camera switch button
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay
          _buildScanOverlay(),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  l10n.pointCameraAtCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: ScanOverlayPainter(
        borderColor: Theme.of(context).colorScheme.primary,
        borderWidth: 3,
        cornerLength: 30,
        cornerRadius: 12,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class ScanOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;
  final double cornerRadius;

  ScanOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    final Rect scanRect = Rect.fromLTRB(left, top, right, bottom);

    // Draw dark overlay with hole
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(scanRect, Radius.circular(cornerRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Draw corner brackets
    final Paint cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + cornerRadius)
        ..arcToPoint(
          Offset(left + cornerRadius, top),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right - cornerRadius, top)
        ..arcToPoint(
          Offset(right, top + cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - cornerLength)
        ..lineTo(right, bottom - cornerRadius)
        ..arcToPoint(
          Offset(right - cornerRadius, bottom),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(right - cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, bottom)
        ..lineTo(left + cornerRadius, bottom)
        ..arcToPoint(
          Offset(left, bottom - cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(left, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
