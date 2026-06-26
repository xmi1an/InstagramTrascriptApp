import 'package:flutter/material.dart';

import 'app_card.dart';

class SetupNotice extends StatelessWidget {
  const SetupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: AppCard(
        color: Color(0xFFFFFBEB),
        child: Text(
          'Backend not configured. Run with --dart-define=TRANSCRIPT_API_URL=https://your-api.com/transcribe after deploying the backend.',
          style: TextStyle(color: Color(0xFF92400E), height: 1.45),
        ),
      ),
    );
  }
}
