import 'dart:io';

import 'package:flutter/material.dart';

class PdfPreviewWidget extends StatelessWidget {
  final File? image;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const PdfPreviewWidget({
    super.key,
    this.image,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return image != null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(image!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save PDF'),
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      onPressed: onShare,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_photo,
                size: 100,
                color: Colors.blue[200],
              ),
              const SizedBox(height: 20),
              const Text(
                'No image selected',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
  }
}
