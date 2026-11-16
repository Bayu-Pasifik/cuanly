import 'package:flutter/material.dart';

typedef WalletType = ({String code, String label, IconData icon});

/// Kinds of wallet. `wallets.type` is free text, so older rows with an unknown type still load as "Reguler".
const walletTypes = <WalletType>[
  (code: 'regular', label: 'Reguler', icon: Icons.account_balance_wallet_rounded),
  (code: 'saving', label: 'Tabungan', icon: Icons.savings_rounded),
  (code: 'credit_card', label: 'Kartu kredit', icon: Icons.credit_card_rounded),
  (code: 'investment', label: 'Investasi', icon: Icons.trending_up_rounded),
  (code: 'business', label: 'Usaha', icon: Icons.storefront_rounded),
  (code: 'debt_book', label: 'Buku utang', icon: Icons.menu_book_rounded),
];

WalletType walletType(String? code) => walletTypes.firstWhere((t) => t.code == code, orElse: () => walletTypes.first);
