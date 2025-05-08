import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../services/permission_service.dart';

class PdfService {
  final PermissionService _permissionService = PermissionService();

  Future<void> createAndSharePdf(
    BuildContext context,
    File? image, {
    required VoidCallback onComplete,
  }) async {
    if (image == null) return;

    try {
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image.readAsBytesSync());

      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
        },
      ));

      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File("${output.path}/document_$timestamp.pdf");
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'document_$timestamp.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PDF: $e')),
      );
    } finally {
      onComplete();
    }
  }

  Future<void> savePdfToStorage(
    BuildContext context,
    File? image, {
    required VoidCallback onComplete,
  }) async {
    if (image == null) return;

    try {
      if (!await _permissionService.requestStoragePermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Storage permission required to save PDF')),
        );
        return;
      }

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image.readAsBytesSync());

      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
        },
      ));

      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory() ??
                await getApplicationDocumentsDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File("${directory.path}/document_$timestamp.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    } finally {
      onComplete();
    }
  }
}
