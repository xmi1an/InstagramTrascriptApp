import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../data/transcript_service.dart';
import '../domain/transcript_result.dart';
import '../platform/share_intent_channel.dart';
import '../utils/instagram_url_parser.dart';
import 'widgets/app_card.dart';
import 'widgets/error_card.dart';
import 'widgets/hero_header.dart';
import 'widgets/loading_card.dart';
import 'widgets/setup_notice.dart';
import 'widgets/transcript_card.dart';
import 'widgets/url_input_card.dart';

class TranscriptHomePage extends StatefulWidget {
  const TranscriptHomePage({super.key});

  @override
  State<TranscriptHomePage> createState() => _TranscriptHomePageState();
}

class _TranscriptHomePageState extends State<TranscriptHomePage> {
  static const String _apiEndpoint = String.fromEnvironment('TRANSCRIPT_API_URL');

  final TextEditingController _urlController = TextEditingController();
  final ShareIntentChannel _shareIntentChannel = const ShareIntentChannel();
  final TranscriptService _transcriptService = const TranscriptService(_apiEndpoint);

  bool _isLoading = false;
  String? _transcript;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedUrl() async {
    final String? sharedText = await _shareIntentChannel.getInitialSharedText();
    final String? url = InstagramUrlParser.firstInstagramUrl(sharedText);
    if (url == null || !mounted) return;

    _urlController.text = url;
    _generateTranscript();
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? url = InstagramUrlParser.firstInstagramUrl(data?.text);
    if (url == null) {
      setState(() => _error = 'Clipboard does not contain an Instagram Reel link.');
      return;
    }

    setState(() {
      _urlController.text = url;
      _error = null;
    });
  }

  Future<void> _copyTranscript() async {
    final String? value = _transcript;
    if (value == null || value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcript copied')),
    );
  }

  Future<void> _generateTranscript() async {
    final String? url = InstagramUrlParser.firstInstagramUrl(_urlController.text);
    if (url == null) {
      setState(() => _error = 'Paste a valid Instagram Reel URL.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _transcript = null;
    });

    try {
      final TranscriptResult result = await _transcriptService.transcribe(url);
      if (!mounted) return;
      setState(() => _transcript = result.transcript);
    } on TranscriptException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const HeroHeader(),
              const SizedBox(height: 28),
              UrlInputCard(
                controller: _urlController,
                isLoading: _isLoading,
                onPaste: _pasteFromClipboard,
                onGenerate: _generateTranscript,
              ),
              const SizedBox(height: 18),
              if (_apiEndpoint.isEmpty) const SetupNotice(),
              if (_isLoading) const LoadingCard(),
              if (_error != null) ErrorCard(message: _error!),
              if (_transcript != null) TranscriptCard(transcript: _transcript!, onCopy: _copyTranscript),
            ],
          ),
        ),
      ),
    );
  }
}
