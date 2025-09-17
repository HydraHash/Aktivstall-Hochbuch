import 'package:flutter/material.dart';
import '../config/brand.dart';

class BrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showSubtitle;

  /// If you want explicit control you can pass logoRatio (0..1) to override.
  final double? logoRatio;

  const BrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showSubtitle = false,
    this.logoRatio,
  });

  @override
  Widget build(BuildContext context) {
    // screen height available (excluding status bar)
    final mq = MediaQuery.of(context);
    final double screenH = mq.size.height - mq.padding.top - mq.padding.bottom;

    // choose a logo height ratio relative to screen height (tweak these to taste)
    final double ratio = logoRatio ?? 0.22; // ~14% of screen height as default
    final double logoHeight = (screenH * ratio).clamp(64.0, 220.0);

    // paddings scale with screen height too
    final double topPadding = (screenH * 0.03).clamp(8.0, 40.0);
    final double between = (screenH * 0.012).clamp(6.0, 22.0);

    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // subtle background logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/subtle_logo_image.png',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, topPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Brand.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenH * 0.03).clamp(18.0, 26.0),
                      ),
                    ),
                    SizedBox(height: between),
                  ],
                  // Center logo image with constrained height
                  Image.asset(
                    'assets/logo_image.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                  if (showSubtitle && (subtitle?.isNotEmpty ?? false)) ...[
                    SizedBox(height: between + 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: Colors.black87),
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}