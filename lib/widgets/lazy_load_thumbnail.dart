import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:scanapp/services/image_cache_service.dart';

class LazyLoadThumbnail extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const LazyLoadThumbnail({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  });

  @override
  State<LazyLoadThumbnail> createState() => _LazyLoadThumbnailState();
}

class _LazyLoadThumbnailState extends State<LazyLoadThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = ImageCacheService().getThumbnail(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: FutureBuilder<Uint8List?>(
        future: _thumbnailFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: widget.width * 0.5,
                height: widget.height * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          // Error state
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.outline,
                size: widget.width * 0.4,
              ),
            );
          }

          // Success state
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: widget.width * 0.4,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
