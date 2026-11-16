import 'package:flutter/material.dart';

import '../data/education.dart';
import 'theme.dart';

class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tips & artikel')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          PastelCard(
            color: C.yellow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tips hari ini', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(tipOfTheDay(DateTime.now()), style: const TextStyle(fontSize: 16)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          for (final a in articles)
            Card(
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(article: a))),
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${a.summary}\n${a.tag}  -  ${a.minutes} menit baca'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
        ]),
      );
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(article.tag)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(article.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${article.minutes} menit baca'),
          const SizedBox(height: 16),
          for (final p in article.body)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(p, style: const TextStyle(fontSize: 16, height: 1.5))),
          const Text('Panduan umum, bukan saran keuangan.', style: TextStyle(fontSize: 12)),
        ]),
      );
}
