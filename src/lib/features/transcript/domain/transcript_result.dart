class TranscriptResult {
  const TranscriptResult({required this.transcript});

  final String transcript;
}

class TranscriptException implements Exception {
  const TranscriptException(this.message);

  final String message;

  @override
  String toString() => message;
}
