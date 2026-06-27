import 'package:flutter/services.dart';

class ShareIntentChannel {
  const ShareIntentChannel({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'instagram_transcript/share';

  final MethodChannel _channel;

  Future<String?> getInitialSharedText() async {
    try {
      return _channel.invokeMethod<String>('getInitialSharedText');
    } on PlatformException {
      // Android sharing is best-effort. Other platforms can safely ignore it.
      return null;
    }
  }
}
