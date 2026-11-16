/// In-app legal text. Written to match what the app actually does; have it reviewed before a public store release.
typedef LegalSection = ({String heading, String body});

const privacyPolicy = <LegalSection>[
  (
    heading: 'Data yang kami simpan',
    body: 'Cuanly menyimpan email akunmu serta data keuangan yang kamu masukkan: dompet, transaksi, kategori, anggaran, '
        'impian, utang, investasi, perjalanan, dan data usaha. Data ini disimpan di layanan basis data Supabase atas akunmu '
        'dan hanya bisa dibaca oleh akunmu.',
  ),
  (
    heading: 'Yang tetap di perangkatmu',
    body: 'PIN, pengaturan tema, dan pengaturan struk disimpan di perangkat. PIN disimpan dalam bentuk hash terenkripsi dan tidak '
        'pernah dikirim ke server. Teks struk yang dipindai dibaca langsung di perangkat; foto struk tidak diunggah.',
  ),
  (
    heading: 'Mode pasangan',
    body: 'Jika kamu menghubungkan akun dengan pasangan, kalian hanya saling melihat ringkasan bulanan (total pengeluaran, '
        'pemasukan, dan kategori terbesar). Transaksi satu per satu tidak dibagikan. Kamu bisa mengakhiri kemitraan kapan saja.',
  ),
  (
    heading: 'Berbagi dengan pihak lain',
    body: 'Kami tidak menjual datamu dan tidak menampilkan iklan. Data hanya diproses oleh penyedia infrastruktur yang '
        'menjalankan aplikasi ini. Berkas backup dan struk yang kamu bagikan lewat menu berbagi menjadi tanggung jawabmu.',
  ),
  (
    heading: 'Hak dan kontrolmu',
    body: 'Kamu dapat mengekspor datamu lewat Backup data atau ekspor CSV/PDF, mengubah password, dan menghapus akun beserta '
        'seluruh datanya dari Pengaturan > Akun. Penghapusan bersifat permanen.',
  ),
];

const termsOfService = <LegalSection>[
  (
    heading: 'Penggunaan aplikasi',
    body: 'Cuanly adalah alat pencatatan dan perencanaan keuangan pribadi. Kamu bertanggung jawab atas keakuratan data yang '
        'kamu masukkan dan atas keamanan akun serta PIN-mu.',
  ),
  (
    heading: 'Bukan saran keuangan',
    body: 'Insight, tips, artikel, dan rekomendasi alokasi investasi bersifat informasi umum. Semuanya bukan saran keuangan, '
        'pajak, atau hukum. Keputusan keuanganmu sepenuhnya tanggung jawabmu.',
  ),
  (
    heading: 'Ketersediaan dan perubahan',
    body: 'Aplikasi diberikan apa adanya. Kami berupaya menjaganya tetap berjalan, tetapi tidak menjamin bebas gangguan atau '
        'kesalahan. Buat backup berkala. Fitur dan ketentuan ini dapat berubah; perubahan penting akan diumumkan di rilis.',
  ),
  (
    heading: 'Penghentian',
    body: 'Kamu dapat berhenti memakai Cuanly dan menghapus akun kapan saja. Akun yang dipakai untuk menyalahgunakan layanan '
        'dapat dibatasi.',
  ),
];
