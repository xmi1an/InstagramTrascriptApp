import 'package:flutter/material.dart';

import '../features/transcript/presentation/transcript_home_page.dart';
import 'app_theme.dart';

class InstaTranscriptApp extends StatelessWidget {
  const InstaTranscriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insta Transcript',
      theme: AppTheme.light,
      home: const TranscriptHomePage(),
    );
  }
}
