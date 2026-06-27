import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import 'app_card.dart';

class TranscriptCard extends StatelessWidget {
  const TranscriptCard({super.key, required this.transcript, required this.onCopy});

  final String transcript;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text('Transcript', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              transcript,
              style: const TextStyle(fontSize: 15.5, height: 1.55, color: AppTheme.ink),
            ),
          ],
        ),
      ),
    );
  }
}
