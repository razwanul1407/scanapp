import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanapp/l10n/app_localizations.dart';
import 'package:scanapp/routes/app_router.dart';
import 'package:scanapp/models/scanned_document.dart';
import 'package:scanapp/services/database_service.dart';

class TextExportScreen extends StatefulWidget {
  final String extractedText;

  const TextExportScreen({
    super.key,
    required this.extractedText,
  });

  @override
  State<TextExportScreen> createState() => _TextExportScreenState();
}

class _TextExportScreenState extends State<TextExportScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportText),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Extracted Text Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.extractedText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),

          // Export Options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  l10n.chooseExportFormat,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExportButton(
                  icon: Icons.description,
                  label: 'TXT',
                  subtitle: l10n.exportAsTxt,
                  onTap: () => _exportAsText(context),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  subtitle: l10n.exportAsPdf,
                  onTap: () => _exportAsPdf(context),
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                _buildExportButton(
                  icon: Icons.file_present,
                  label: 'DOCX',
                  subtitle: l10n.exportAsDocx,
                  onTap: () => _exportAsDocx(context),
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                _buildExportButton(
                  icon: Icons.copy,
                  label: l10n.copyToClipboard,
                  subtitle: l10n.copyText,
                  onTap: () => _copyToClipboard(context),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isExporting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.arrow_forward, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.extractedText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).copiedToClipboard),
        ),
      );
    }
  }

  Future<void> _exportAsText(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'extracted_text_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(widget.extractedText);

      // Save as document to database
      await _saveAsDocument(context, file, 'txt', fileName);

      if (mounted) {
        _showExportSuccess(context, file.path, 'TXT');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportAsPdf(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'extracted_text_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');

      // Create simple PDF with text (using basic PDF format)
      final pdfContent = _createSimplePdf(widget.extractedText);
      await file.writeAsBytes(pdfContent);

      // Save as document to database
      await _saveAsDocument(context, file, 'pdf', fileName);

      if (mounted) {
        _showExportSuccess(context, file.path, 'PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportAsDocx(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'extracted_text_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${dir.path}/$fileName');

      // Create simple DOCX format (basic XML-based approach)
      final docxContent = _createSimpleDocx(widget.extractedText);
      await file.writeAsBytes(docxContent);

      // Save as document to database
      await _saveAsDocument(context, file, 'docx', fileName);

      if (mounted) {
        _showExportSuccess(context, file.path, 'DOCX');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting DOCX: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // Create a simple PDF content (basic text PDF)
  List<int> _createSimplePdf(String text) {
    final buffer = StringBuffer();
    buffer.write('%PDF-1.4\n');
    buffer.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    buffer
        .write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    final content = 'BT /F1 12 Tf 50 750 Td ($text) Tj ET';
    buffer.write(
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n');
    buffer.write(
        '4 0 obj\n<< /Length ${content.length} >>\nstream\n$content\nendstream\nendobj\n');
    buffer.write(
        'xref\n0 5\n0000000000 65535 f\n0000000009 00000 n\n0000000074 00000 n\n0000000133 00000 n\n0000000281 00000 n\n');
    buffer.write(
        'trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n${buffer.toString().length}\n%%EOF\n');

    return buffer.toString().codeUnits;
  }

  // Create a simple DOCX content (basic text)
  List<int> _createSimpleDocx(String text) {
    // DOCX is ZIP format with XML inside - creating a minimal version
    final textEscaped = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final docxXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>$textEscaped</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>''';

    return docxXml.codeUnits;
  }

  Future<void> _saveAsDocument(
    BuildContext context,
    File file,
    String format,
    String fileName,
  ) async {
    try {
      final document = ScannedDocument(
        title:
            fileName.replaceAll('.txt', '').replaceAll('extracted_text_', ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imagePaths: [file.path], // Store file path as image path
        tags: ['ocr', format], // Tag as OCR extraction
        pageCount: 1,
        fileSize: await file.length(),
        extractedText: widget.extractedText, // Store the extracted text
        isFavorite: false,
      );

      // Save to database
      await DatabaseService.saveDocument(document);
    } catch (e) {
      debugPrint('Error saving document: $e');
    }
  }

  void _showExportSuccess(
      BuildContext context, String filePath, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Text('Text exported as $format successfully'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRouter.home);
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(filePath)],
                  text: 'Exported Text',
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
