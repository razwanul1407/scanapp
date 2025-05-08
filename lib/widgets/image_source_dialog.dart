import 'package:flutter/material.dart';

class ImageSourceDialog extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const ImageSourceDialog({
    super.key,
    required this.onCameraSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Image Source"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: onCameraSelected,
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Gallery"),
            onTap: onGallerySelected,
          ),
        ],
      ),
    );
  }
}
