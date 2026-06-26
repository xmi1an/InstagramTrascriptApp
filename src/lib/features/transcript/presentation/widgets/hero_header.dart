import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.closed_caption_rounded, color: AppTheme.brand, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Instagram Transcript',
          style: TextStyle(fontSize: 32, height: 1.05, fontWeight: FontWeight.w800, color: AppTheme.ink),
        ),
        const SizedBox(height: 10),
        const Text(
          'Paste or share a Reel link. Get a clean transcript you can copy in seconds.',
          style: TextStyle(fontSize: 16, height: 1.45, color: AppTheme.muted),
        ),
      ],
    );
  }
}
