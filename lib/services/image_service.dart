import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:scanapp/services/image_processor.dart';

class ImageService {
  File? image;
  File? croppedImage;

  Future<void> pickImage(
    BuildContext context, {
    required ImageSource source,
    required Function(File?) onImagePicked,
  }) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: false,
              resetAspectRatioEnabled: true,
            ),
          ],
        );
        image = File(pickedFile.path);
        croppedImage = croppedFile != null ? File(croppedFile.path) : null;
        onImagePicked(croppedImage);

        // if (croppedFile != null) {
        //   // Process image in background
        //   final processedFile = await ImageProcessor.applyAdjustments(
        //     File(croppedFile.path),
        //   );

        //   image = File(pickedFile.path);
        //   croppedImage = processedFile;
        //   onImagePicked(croppedImage);
        // }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void clearSelection() {
    image = null;
    croppedImage = null;
  }
}
