# Cuanly

Personal finance tracker (Flutter + Supabase): wallets, transactions, monthly budget, dream planner, debts.

## Setup
1. Create a Supabase project and run `supabase/schema.sql` in the SQL editor.
2. Run the app with your project keys:
   `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key`
3. For quick testing, disable "Confirm email" in Supabase Auth settings.
