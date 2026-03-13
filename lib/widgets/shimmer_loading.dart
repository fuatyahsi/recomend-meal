import 'package:flutter/material.dart';

/// Shimmer loading efekti - Lottie yerine daha hafif ve bağımlılık gerektirmeyen çözüm
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Yemek pişirme loading animasyonu - custom painter
class CookingLoadingAnimation extends StatefulWidget {
  final double size;
  final String? message;

  const CookingLoadingAnimation({
    super.key,
    this.size = 120,
    this.message,
  });

  @override
  State<CookingLoadingAnimation> createState() =>
      _CookingLoadingAnimationState();
}

class _CookingLoadingAnimationState extends State<CookingLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late Animation<double> _bounce;

  final _foodEmojis = ['🥕', '🥩', '🧅', '🥬', '🍅', '🧄'];
  int _currentEmoji = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bounce = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Emoji değiştirme
    _rotateController.addListener(() {
      final newIndex =
          (_rotateController.value * _foodEmojis.length).floor() %
              _foodEmojis.length;
      if (newIndex != _currentEmoji) {
        setState(() => _currentEmoji = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating circle
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 6.28,
                    child: Container(
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _DotPainter(
                          color: theme.colorScheme.primary,
                          progress: _rotateController.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Bouncing emoji
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounce.value),
                    child: Text(
                      _foodEmojis[_currentEmoji],
                      style: TextStyle(fontSize: widget.size * 0.35),
                    ),
                  );
                },
              ),
              // Pot emoji at bottom
              Positioned(
                bottom: widget.size * 0.05,
                child: const Text('🍲', style: TextStyle(fontSize: 36)),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  final Color color;
  final double progress;

  _DotPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, 0);

    // Ana nokta
    canvas.drawCircle(center, 5, paint);

    // İz noktaları
    for (int i = 1; i <= 3; i++) {
      paint.color = color.withOpacity(0.3 - i * 0.08);
      final trailAngle = -i * 0.3;
      final trailCenter = Offset(
        size.width / 2 + trailAngle * 10,
        i * 3.0,
      );
      canvas.drawCircle(trailCenter, 4.0 - i * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Match yüzdesi badge
class MatchBadge extends StatelessWidget {
  final int percentage;
  final double size;

  const MatchBadge({
    super.key,
    required this.percentage,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1,
              ),
            ),
            const Text(
              '%',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
