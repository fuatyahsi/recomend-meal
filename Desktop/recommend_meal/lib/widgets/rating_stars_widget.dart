import 'package:flutter/material.dart';

class RatingStarsWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showValue;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(Icons.star, size: size, color: starColor);
          } else if (rating >= starValue - 0.5) {
            return Icon(Icons.star_half, size: size, color: starColor);
          } else {
            return Icon(Icons.star_border, size: size, color: starColor);
          }
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= currentRating ? Icons.star : Icons.star_border,
              size: size,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}
