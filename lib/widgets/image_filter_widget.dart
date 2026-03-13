import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Client-side görsel filtre widget'ı
/// Cloudinary transformation yerine Flutter'ın kendi filter yetenekleri
class FilteredNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final ImageFilterType filterType;

  const FilteredNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.filterType = ImageFilterType.warm,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );

    // Apply filter
    switch (filterType) {
      case ImageFilterType.warm:
        image = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.1, 0, 0, 0, 10,
            0, 1.0, 0, 0, 5,
            0, 0, 0.9, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: image,
        );
        break;
      case ImageFilterType.vivid:
        image = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.2, 0, 0, 0, 0,
            0, 1.2, 0, 0, 0,
            0, 0, 1.2, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: image,
        );
        break;
      case ImageFilterType.soft:
        image = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.9, 0.1, 0, 0, 10,
            0.05, 0.95, 0.05, 0, 10,
            0, 0.1, 0.9, 0, 10,
            0, 0, 0, 1, 0,
          ]),
          child: image,
        );
        break;
      case ImageFilterType.none:
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}

enum ImageFilterType {
  none,
  warm,   // Sıcak tonlar - yemek fotoğrafları için ideal
  vivid,  // Canlı renkler
  soft,   // Yumuşak, pastel
}

/// Yemek fotoğrafı için özel gradient overlay
class FoodPhotoOverlay extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool showVignette;

  const FoodPhotoOverlay({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.showVignette = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          child,
          if (showVignette)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
            ),
          // Subtle bottom gradient for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
