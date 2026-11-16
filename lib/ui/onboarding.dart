import 'package:flutter/material.dart';

import 'theme.dart';

typedef OnboardingStep = ({IconData icon, String title, String body, Color color});

const onboardingSteps = <OnboardingStep>[
  (
    icon: Icons.account_balance_wallet_rounded,
    title: 'Catat semua uangmu',
    body: 'Buat dompet, catat pemasukan dan pengeluaran, atau foto struk dan biarkan nominalnya terisi sendiri.',
    color: C.yellow,
  ),
  (
    icon: Icons.donut_small_rounded,
    title: 'Lihat ke mana uangmu pergi',
    body: 'Laporan, Cuan Tracker, dan insight menunjukkan pola belanjamu dan memperingatkan sebelum anggaran jebol.',
    color: C.mint,
  ),
  (
    icon: Icons.flag_rounded,
    title: 'Capai tujuanmu',
    body: 'Tabung untuk impian, lunasi utang tepat waktu, dan tantang dirimu hemat lewat Tantangan hemat.',
    color: C.pink,
  ),
  (
    icon: Icons.lock_rounded,
    title: 'Aman dan milikmu',
    body: 'Kunci dengan PIN, backup kapan saja, dan hapus akunmu kalau perlu. Datamu hanya bisa dibaca akunmu.',
    color: C.sky,
  ),
];

/// First-run walkthrough. [onDone] is called when the user finishes or skips it.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  bool get _last => _page == onboardingSteps.length - 1;

  void _next() {
    if (_last) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: widget.onDone, child: const Text('Lewati')),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final s in onboardingSteps)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: C.fg(context), width: 3),
                          ),
                          child: Icon(s.icon, size: 60, color: C.ink),
                        ),
                        const SizedBox(height: 28),
                        Text(s.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(s.body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
                      ]),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < onboardingSteps.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? C.yellow : C.fg(context).withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text(_last ? 'Mulai' : 'Lanjut')),
              ),
            ),
          ]),
        ),
      );
}
