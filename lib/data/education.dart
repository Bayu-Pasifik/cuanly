/// Short money-management articles bundled with the app. General guidance, not financial advice.
class Article {
  const Article({required this.id, required this.title, required this.summary, required this.tag, required this.body});
  final String id, title, summary, tag;
  final List<String> body;

  /// Rough reading time in minutes (at least 1).
  int get minutes {
    final words = body.join(' ').split(RegExp(r'\s+')).length;
    return (words / 180).ceil().clamp(1, 99);
  }
}

const articles = <Article>[
  Article(
    id: 'aturan-50-30-20',
    title: 'Aturan 50/30/20 untuk gaji bulanan',
    summary: 'Cara sederhana membagi pemasukan tanpa pusing.',
    tag: 'Anggaran',
    body: [
      'Bagi pemasukan bersih (setelah pajak) menjadi tiga bagian: 50% untuk kebutuhan, 30% untuk keinginan, dan 20% untuk tabungan atau pelunasan utang.',
      'Kebutuhan adalah hal yang tidak bisa ditunda: sewa atau cicilan rumah, makan pokok, listrik, transportasi kerja, dan asuransi. Keinginan adalah hiburan, makan di luar, langganan streaming, dan belanja non-esensial.',
      'Angka ini hanya titik awal. Kalau sewa di kotamu memakan 40% gaji, geser porsinya: misalnya 60/20/20. Yang penting porsi tabungan tidak jadi sisa, tapi dipindahkan lebih dulu di awal bulan.',
      'Cara memakainya di Cuanly: atur target pengeluaran bulanan di Cuan Tracker sebesar 80% pemasukan, lalu pantau progresnya tiap minggu.',
    ],
  ),
  Article(
    id: 'dana-darurat',
    title: 'Dana darurat: berapa yang cukup?',
    summary: 'Bantalan pertama sebelum menabung untuk hal lain.',
    tag: 'Menabung',
    body: [
      'Dana darurat adalah uang yang hanya dipakai saat keadaan mendesak: kehilangan pekerjaan, sakit, atau kerusakan yang tidak terduga.',
      'Targetkan 3 sampai 6 bulan pengeluaran bulanan. Jika penghasilanmu tidak tetap atau kamu menanggung keluarga, mendekati 6 sampai 12 bulan lebih aman.',
      'Mulai kecil: kumpulkan satu bulan pengeluaran dulu, lalu naikkan bertahap. Simpan di tempat yang mudah dicairkan tapi tidak menggoda untuk dipakai belanja, misalnya dompet Tabungan terpisah.',
      'Buat satu mimpi di Cuanly bernama "Dana darurat" dan setor rutin setiap gajian, supaya progresnya terlihat.',
    ],
  ),
  Article(
    id: 'melunasi-utang',
    title: 'Snowball atau avalanche: urutan melunasi utang',
    summary: 'Dua strategi populer dan kapan memakainya.',
    tag: 'Utang',
    body: [
      'Daftar semua utangmu lebih dulu: pemberi pinjaman, sisa pokok, bunga, dan jatuh tempo. Bayar minimum untuk semuanya, lalu arahkan uang ekstra ke satu utang.',
      'Avalanche: dahulukan utang dengan bunga tertinggi. Totalnya paling hemat bunga. Snowball: dahulukan utang dengan sisa terkecil. Kamu merasakan kemenangan cepat, sehingga lebih mudah konsisten.',
      'Pilih yang paling mungkin kamu jalani sampai selesai. Strategi sempurna yang ditinggal di tengah jalan kalah dari strategi biasa yang tuntas.',
      'Isi tanggal jatuh tempo di menu Utang. Cuanly akan mengingatkanmu sehari sebelum dan pada hari jatuh tempo.',
    ],
  ),
  Article(
    id: 'kartu-kredit',
    title: 'Memakai kartu kredit tanpa terjebak bunga',
    summary: 'Aturan sederhana supaya kartu jadi alat, bukan beban.',
    tag: 'Utang',
    body: [
      'Anggap kartu kredit sebagai kartu debit yang tagihannya datang belakangan. Hanya belanja sebanyak yang sudah ada uangnya.',
      'Bayar lunas tagihan setiap bulan sebelum jatuh tempo. Membayar minimum membuat sisanya berbunga tinggi dan bertumpuk.',
      'Catat kartu sebagai dompet bertipe Kartu kredit di Cuanly supaya saldo utangnya terlihat dan tidak terasa seperti uang yang bisa dipakai.',
    ],
  ),
  Article(
    id: 'kebiasaan-mencatat',
    title: 'Biasakan mencatat dalam 30 detik',
    summary: 'Kunci pencatatan yang bertahan lebih dari seminggu.',
    tag: 'Kebiasaan',
    body: [
      'Pencatatan gagal bukan karena malas, tapi karena terlalu ribet. Catat segera setelah bayar, jangan ditumpuk di akhir minggu.',
      'Gunakan kategori yang sedikit dan jelas. Delapan kategori lebih berguna daripada tiga puluh kategori yang membingungkan.',
      'Untuk struk belanja, pakai fitur Scan struk. Untuk tagihan rutin seperti sewa atau langganan, pakai Transaksi berulang supaya tercatat otomatis.',
      'Sisihkan lima menit tiap akhir pekan untuk melihat Laporan. Kebiasaan melihat angka lebih penting daripada mencatat sempurna.',
    ],
  ),
  Article(
    id: 'otomatis-menabung',
    title: 'Menabung otomatis: bayar diri sendiri dulu',
    summary: 'Pindahkan tabungan sebelum sempat terpakai.',
    tag: 'Menabung',
    body: [
      'Menabung dari sisa uang hampir selalu gagal karena sisanya jarang ada. Balik urutannya: begitu gajian, pindahkan jumlah tabungan lebih dulu, baru sisanya untuk dipakai.',
      'Jadwalkan pemindahan otomatis di hari yang sama dengan gajian. Mulai dari jumlah yang tidak terasa, lalu naikkan 1% sampai 2% tiap beberapa bulan.',
      'Beri tujuan pada setiap tabungan: liburan, dana darurat, uang muka. Tabungan yang punya nama lebih sulit diambil untuk hal sepele.',
    ],
  ),
  Article(
    id: 'mulai-investasi',
    title: 'Sebelum mulai berinvestasi',
    summary: 'Risiko, jangka waktu, dan diversifikasi dalam bahasa sederhana.',
    tag: 'Investasi',
    body: [
      'Urutan yang aman: punya dana darurat, tidak ada utang berbunga tinggi, baru investasi. Investasi memakai uang yang tidak kamu butuhkan dalam waktu dekat.',
      'Semakin tinggi potensi imbal hasil, semakin besar kemungkinan nilainya turun di jangka pendek. Reksa dana pasar uang relatif stabil, saham dan aset kripto bergejolak besar.',
      'Jangan menaruh semua uang di satu tempat. Sebarkan ke beberapa jenis aset sesuai tujuan dan lamanya waktu. Cuanly punya contoh alokasi konservatif, moderat, dan agresif di menu Investasi.',
      'Ini panduan umum, bukan saran keuangan. Pelajari produknya, dan konsultasikan ke perencana keuangan berizin bila ragu.',
    ],
  ),
  Article(
    id: 'uang-berdua',
    title: 'Mengatur uang berdua dengan pasangan',
    summary: 'Transparan tanpa harus menyatukan semua rekening.',
    tag: 'Kebiasaan',
    body: [
      'Sepakati tujuan bersama dulu: dana darurat, cicilan rumah, liburan. Baru bahas cara patungannya, apakah dibagi rata atau sebanding dengan penghasilan.',
      'Banyak pasangan memakai tiga pos: satu untuk bersama, dan satu pribadi untuk masing-masing sehingga tidak perlu melapor tiap pengeluaran kecil.',
      'Mode pasangan di Cuanly hanya membagikan total bulanan dan kategori terbesar, bukan transaksi satu per satu, jadi privasi masing-masing tetap terjaga.',
    ],
  ),
];

Article? articleById(String id) {
  for (final a in articles) {
    if (a.id == id) return a;
  }
  return null;
}

/// A tip that changes every day: the same one all day, cycling through [tips].
const tips = <String>[
  'Catat pengeluaran segera setelah bayar. Menunda membuatnya terlupa.',
  'Sebelum membeli barang non-esensial, tunggu 24 jam. Banyak keinginan hilang sendiri.',
  'Pindahkan tabungan di hari gajian, bukan di akhir bulan.',
  'Cek langganan bulananmu. Berhenti dari yang jarang dipakai.',
  'Bawa bekal dua kali seminggu dan lihat selisihnya di akhir bulan.',
  'Lunasi utang berbunga tinggi lebih dulu sebelum menambah investasi.',
  'Bandingkan harga per satuan, bukan harga kemasan.',
  'Beri nama pada tujuan tabunganmu. Tujuan yang jelas lebih sulit diganggu.',
  'Tinjau Laporan tiap akhir pekan, cukup lima menit.',
  'Dana darurat dulu, baru investasi.',
];

String tipOfTheDay(DateTime day) {
  final n = DateTime(day.year, day.month, day.day).difference(DateTime(2024)).inDays;
  return tips[n % tips.length];
}
