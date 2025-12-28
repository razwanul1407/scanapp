import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

/// Quality presets for image compression
enum CompressionQuality {
  high(quality: 95, maxWidth: 2048, label: 'High Quality'),
  medium(quality: 80, maxWidth: 1600, label: 'Medium'),
  low(quality: 60, maxWidth: 1200, label: 'Low (Smaller Size)');

  const CompressionQuality({
    required this.quality,
    required this.maxWidth,
    required this.label,
  });

  final int quality;
  final int maxWidth;
  final String label;
}

class PdfService {
  /// Create PDF from single image with metadata and optional compression
  static Future<Uint8List> createPdfFromImage({
    required File imageFile,
    String title = 'Scanned Document',
    String author = 'ScanApp',
    CompressionQuality compression = CompressionQuality.high,
  }) async {
    try {
      final pdf = pw.Document();

      // Compress image before adding to PDF
      final compressedBytes = await _compressImage(
        imageFile.readAsBytesSync(),
        compression,
      );
      final pdfImage = pw.MemoryImage(compressedBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      print('Error creating PDF: $e');
      rethrow;
    }
  }

  /// Create multi-page PDF from multiple images with compression
  static Future<Uint8List> createMultiPagePdf({
    required List<File> imageFiles,
    String title = 'Scanned Document',
    String author = 'ScanApp',
    CompressionQuality compression = CompressionQuality.high,
  }) async {
    try {
      final pdf = pw.Document();

      for (final imageFile in imageFiles) {
        // Compress each image before adding to PDF
        final compressedBytes = await _compressImage(
          imageFile.readAsBytesSync(),
          compression,
        );
        final pdfImage = pw.MemoryImage(compressedBytes);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Image(
                  pdfImage,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      print('Error creating multi-page PDF: $e');
      rethrow;
    }
  }

  /// Compress image based on quality preset
  static Future<Uint8List> _compressImage(
    Uint8List imageBytes,
    CompressionQuality compression,
  ) async {
    try {
      var image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Resize if larger than max width
      if (image.width > compression.maxWidth) {
        final ratio = compression.maxWidth / image.width;
        final newHeight = (image.height * ratio).round();
        image = img.copyResize(
          image,
          width: compression.maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode with quality setting
      return Uint8List.fromList(
        img.encodeJpg(image, quality: compression.quality),
      );
    } catch (e) {
      print('Error compressing image: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  /// Estimate PDF size based on images and compression
  static Future<int> estimatePdfSize({
    required List<File> imageFiles,
    CompressionQuality compression = CompressionQuality.high,
  }) async {
    int totalSize = 0;
    for (final file in imageFiles) {
      final compressed = await _compressImage(
        file.readAsBytesSync(),
        compression,
      );
      totalSize += compressed.length;
    }
    // Add ~10% overhead for PDF structure
    return (totalSize * 1.1).round();
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Save PDF to device storage
  static Future<File> savePdf({
    required Uint8List pdfBytes,
    String filename = 'document.pdf',
  }) async {
    try {
      Directory directory;

      if (Platform.isAndroid) {
        // Try Documents folder first, fallback to Downloads
        directory = Directory('/storage/emulated/0/Documents');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = (await getExternalStorageDirectory()) ??
                (await getApplicationDocumentsDirectory());
          }
        }
      } else {
        // iOS uses app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      await directory.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename = '${filename.replaceAll('.pdf', '')}_$timestamp.pdf';
      final file = File('${directory.path}/$finalFilename');

      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Share PDF via system share sheet (from bytes)
  static Future<void> sharePdfBytes({
    required Uint8List pdfBytes,
    String filename = 'document.pdf',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename = '${filename.replaceAll('.pdf', '')}_$timestamp.pdf';

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: finalFilename,
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Share PDF file via system share sheet
  static Future<void> sharePdf(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Scanned Document',
      );
    } catch (e) {
      print('Error sharing PDF file: $e');
      rethrow;
    }
  }

  /// Export image as PNG
  static Future<Uint8List> exportAsPng(File imageFile) async {
    try {
      final imageBytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(imageBytes);

      if (image == null) throw Exception('Failed to decode image');

      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      print('Error exporting PNG: $e');
      rethrow;
    }
  }

  /// Export image as JPEG with quality control
  static Future<Uint8List> exportAsJpeg(
    File imageFile, {
    int quality = 90,
  }) async {
    try {
      final imageBytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(imageBytes);

      if (image == null) throw Exception('Failed to decode image');

      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      print('Error exporting JPEG: $e');
      rethrow;
    }
  }

  /// Save exported file to device
  static Future<File> saveExportFile({
    required Uint8List fileBytes,
    required String filename,
    required String extension, // 'pdf', 'png', 'jpg'
  }) async {
    try {
      Directory directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = (await getExternalStorageDirectory()) ??
                (await getApplicationDocumentsDirectory());
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      await directory.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename =
          '${filename.replaceAll(extension, '')}_$timestamp.$extension';
      final file = File('${directory.path}/$finalFilename');

      await file.writeAsBytes(fileBytes);
      return file;
    } catch (e) {
      print('Error saving export file: $e');
      rethrow;
    }
  }

  /// Get PDF file size in bytes
  static int getPdfSize(Uint8List pdfBytes) {
    return pdfBytes.length;
  }
}
