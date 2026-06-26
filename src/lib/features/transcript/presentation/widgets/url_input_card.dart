import 'package:flutter/material.dart';

import 'app_card.dart';

class UrlInputCard extends StatelessWidget {
  const UrlInputCard({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onPaste,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onPaste;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                  onPressed: isLoading ? null : onGenerate,
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
