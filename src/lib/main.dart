import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

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

class AppTheme {
  static const Color ink = Color(0xFF121316);
  static const Color muted = Color(0xFF6B7280);
  static const Color brand = Color(0xFFE4405F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F8);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: brand,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: brand,
          onPrimary: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class TranscriptHomePage extends StatefulWidget {
  const TranscriptHomePage({Key? key}) : super(key: key);

  @override
  _TranscriptHomePageState createState() => _TranscriptHomePageState();
}

class _TranscriptHomePageState extends State<TranscriptHomePage> {
  static const MethodChannel _shareChannel = MethodChannel('instagram_transcript/share');
  static const String _apiEndpoint = String.fromEnvironment('TRANSCRIPT_API_URL');

  final TextEditingController _urlController = TextEditingController();
  final TranscriptService _transcriptService = TranscriptService(_apiEndpoint);

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
    try {
      final String? sharedText = await _shareChannel.invokeMethod<String>('getInitialSharedText');
      final String? url = InstagramUrlParser.firstInstagramUrl(sharedText);
      if (url != null && mounted) {
        _urlController.text = url;
        unawaited(_generateTranscript(autoStarted: true));
      }
    } on PlatformException {
      // Sharing is best-effort and currently implemented for Android.
    }
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? url = InstagramUrlParser.firstInstagramUrl(data == null ? null : data.text);
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

  Future<void> _generateTranscript({bool autoStarted = false}) async {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _HeroHeader(),
              const SizedBox(height: 28),
              _UrlInputCard(
                controller: _urlController,
                isLoading: _isLoading,
                onPaste: _pasteFromClipboard,
                onGenerate: _generateTranscript,
              ),
              const SizedBox(height: 18),
              if (_apiEndpoint.isEmpty) const _SetupNotice(),
              if (_isLoading) const _LoadingCard(),
              if (_error != null) _ErrorCard(message: _error!),
              if (_transcript != null) _TranscriptCard(transcript: _transcript!, onCopy: _copyTranscript),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({Key? key}) : super(key: key);

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

class _UrlInputCard extends StatelessWidget {
  const _UrlInputCard({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.onPaste,
    required this.onGenerate,
  }) : super(key: key);

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onPaste;
  final Future<void> Function({bool autoStarted}) onGenerate;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            decoration: const InputDecoration(
              hintText: 'https://www.instagram.com/reel/...',
              labelText: 'Instagram Reel URL',
            ),
            onSubmitted: (_) => onGenerate(),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onPaste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Paste'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => onGenerate(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(isLoading ? 'Transcribing' : 'Generate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: _Card(
        color: Color(0xFFFFFBEB),
        child: Text(
          'Backend not configured. Run with --dart-define=TRANSCRIPT_API_URL=https://your-api.com/transcribe after deploying the backend.',
          style: TextStyle(color: Color(0xFF92400E), height: 1.45),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: _Card(
        child: Row(
          children: <Widget>[
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            SizedBox(width: 14),
            Expanded(child: Text('Downloading audio and generating transcript...')),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _Card(
        color: const Color(0xFFFEF2F2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF991B1B), height: 1.45))),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({Key? key, required this.transcript, required this.onCopy}) : super(key: key);

  final String transcript;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _Card(
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
            SelectableText(transcript, style: const TextStyle(fontSize: 15.5, height: 1.55, color: AppTheme.ink)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({Key? key, required this.child, this.color = Colors.white}) : super(key: key);

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

class InstagramUrlParser {
  static final RegExp _urlPattern = RegExp(r'https?:\/\/(?:www\.)?instagram\.com\/[^\s]+', caseSensitive: false);

  static String? firstInstagramUrl(String? text) {
    if (text == null) return null;
    final Match? match = _urlPattern.firstMatch(text.trim());
    final String? candidate = match == null ? text.trim() : match.group(0);
    if (candidate == null || candidate.isEmpty) return null;
    return isValid(candidate) ? candidate : null;
  }

  static bool isValid(String url) {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();
    return (host == 'instagram.com' || host == 'www.instagram.com') &&
        (path.contains('/reel/') || path.contains('/p/') || path.contains('/tv/'));
  }
}

class TranscriptResult {
  TranscriptResult({required this.transcript});

  final String transcript;
}

class TranscriptException implements Exception {
  TranscriptException(this.message);

  final String message;
}

class TranscriptService {
  TranscriptService(this.endpoint);

  final String endpoint;

  Future<TranscriptResult> transcribe(String url) async {
    if (endpoint.trim().isEmpty) {
      throw TranscriptException('Backend URL is missing. Deploy the backend and pass TRANSCRIPT_API_URL at build time.');
    }

    final Uri? uri = Uri.tryParse(endpoint);
    if (uri == null) {
      throw TranscriptException('Backend URL is invalid.');
    }

    final http.Response response = await http
        .post(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, String>{'url': url}),
        )
        .timeout(const Duration(minutes: 3));

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Non-JSON error responses are handled below.
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String transcript = (body['transcript'] ?? body['text'] ?? '').toString().trim();
      if (transcript.isEmpty) throw TranscriptException('No speech was found in this Reel.');
      return TranscriptResult(transcript: transcript);
    }

    final String message = (body['detail'] ?? body['error'] ?? 'Could not generate transcript.').toString();
    throw TranscriptException(message);
  }
}
