import 'package:flutter/material.dart';

import '../data/legal.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.sections});
  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          for (final s in sections) ...[
            Text(s.heading, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 18),
          ],
        ]),
      );
}
