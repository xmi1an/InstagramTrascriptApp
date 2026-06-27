import 'package:flutter/material.dart';

import 'app_card.dart';

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: AppCard(
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
