import 'package:flutter/material.dart';
import '../config/brand.dart';

class BrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showSubtitle;
  final double logoHeight;

  const BrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showSubtitle = false,
    this.logoHeight = 110,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle background logo stretched to center top
          Positioned.fill(
            child: Opacity(
              opacity: 0.80, // very faint
              child: Image.asset(
                'assets/logo_image.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),

          // Content: Title, Logo, optional subtitle box
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 64.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Brand.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  /*Image.asset(
                    'assets/logo_image.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),*/
                  if (showSubtitle && (subtitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: Colors.black87),
                      ),
                    ),
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