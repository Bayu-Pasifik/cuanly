const Nav = ({ on = 0 }) => (
  <div className="m-nav">
    {['Ringkasan', 'Transaksi', 'Impian', 'Utang'].map((t, i) => (
      <span key={t} className={i === on ? 'on' : ''}>{t}</span>
    ))}
  </div>
)

const Tx = ({ color, emoji, name, sub, amt, neg }) => (
  <div className="m-row">
    <div className="m-row" style={{ justifyContent: 'flex-start' }}>
      <div className="m-dot" style={{ background: color }}>{emoji}</div>
      <div><b>{name}</b><div className="m-muted">{sub}</div></div>
    </div>
    <b style={{ color: neg ? '#e0564b' : '#2e9d6b' }}>{amt}</b>
  </div>
)

export function Dashboard() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Ringkasan</div>
      <div className="m-card" style={{ background: 'var(--yellow)', color: '#4a3426' }}>
        <div className="m-muted" style={{ color: '#4a3426' }}>Total saldo</div>
        <div className="m-big">Rp 12.480.000</div>
        <div className="m-row" style={{ marginTop: 6 }}>
          <span className="chip" style={{ background: '#7be0b0' }}>↑ Masuk 8,5jt</span>
          <span className="chip" style={{ background: '#ff8a80' }}>↓ Keluar 3,2jt</span>
        </div>
      </div>
      <div className="m-card m-row">
        <div className="donut" style={{ background: 'conic-gradient(#ff8a80 0 38%, #ffc93c 0 62%, #7be0b0 0 80%, #c9b6ff 0 100%)' }} />
        <div style={{ flex: 1 }}>
          <b>Pengeluaran</b>
          <div className="m-muted">Makan 38% · Transport 24% · Belanja 18%</div>
        </div>
      </div>
      <div className="m-card">
        <div className="m-row"><b>Anggaran bulan ini</b><span className="m-muted">64%</span></div>
        <div className="m-bar" style={{ marginTop: 6 }}><i style={{ width: '64%' }} /></div>
      </div>
      <Nav on={0} />
    </div>
  )
}

export function Transactions() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Transaksi</div>
      <div className="m-row" style={{ justifyContent: 'flex-start', gap: 6 }}>
        <span className="chip" style={{ background: '#ffc93c' }}>Semua</span>
        <span className="chip" style={{ background: 'var(--card)' }}>Masuk</span>
        <span className="chip" style={{ background: 'var(--card)' }}>Keluar</span>
      </div>
      <div className="m-card" style={{ display: 'grid', gap: 10 }}>
        <Tx color="#ff8a80" emoji="🍜" name="Makan siang" sub="Dompet tunai" amt="-Rp 32.000" neg />
        <Tx color="#7be0b0" emoji="💼" name="Gaji" sub="Rekening BCA" amt="+Rp 8.500.000" />
        <Tx color="#8ec9ff" emoji="🚌" name="Transport" sub="E-wallet" amt="-Rp 18.000" neg />
        <Tx color="#c9b6ff" emoji="🎬" name="Nonton" sub="E-wallet" amt="-Rp 55.000" neg />
        <Tx color="#ff9fcb" emoji="🛒" name="Belanja bulanan" sub="Rekening BCA" amt="-Rp 410.000" neg />
      </div>
      <Nav on={1} />
    </div>
  )
}

export function Dreams() {
  const d = [['🏍️', 'Motor baru', 62, '#ffc93c'], ['✈️', 'Liburan Jepang', 35, '#8ec9ff'], ['🏠', 'DP rumah', 12, '#ff9fcb']]
  return (
    <div className="screen fade-in">
      <div className="m-title">Impian</div>
      {d.map(([e, n, p, c]) => (
        <div className="m-card" key={n}>
          <div className="m-row"><b>{e} {n}</b><span className="chip" style={{ background: c }}>{p}%</span></div>
          <div className="m-bar" style={{ margin: '8px 0 4px' }}><i style={{ width: p + '%', background: c }} /></div>
          <div className="m-muted">Nabung Rp 500.000 / bulan</div>
        </div>
      ))}
      <Nav on={2} />
    </div>
  )
}

export function Debts() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Utang</div>
      <div className="m-card" style={{ background: '#ff8a80', color: '#4a3426' }}>
        <b>Utangmu</b>
        <div className="m-big">Rp 750.000</div>
        <div className="m-muted" style={{ color: '#4a3426' }}>Jatuh tempo 3 hari lagi</div>
      </div>
      <div className="m-card" style={{ background: '#7be0b0', color: '#4a3426' }}>
        <b>Piutangmu</b>
        <div className="m-big">Rp 1.200.000</div>
      </div>
      <div className="m-card">
        <div className="m-row"><b>Dina</b><span>Rp 300.000</span></div>
        <div className="m-bar" style={{ margin: '6px 0 2px' }}><i style={{ width: '40%' }} /></div>
        <div className="m-muted">Dibayar 40% · riwayat tersimpan</div>
      </div>
      <Nav on={3} />
    </div>
  )
}

export function Scan() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Scan struk</div>
      <div className="m-card" style={{ textAlign: 'center', background: '#fff', color: '#4a3426', fontFamily: 'monospace', fontSize: 10.5 }}>
        <b>WARUNG BU SARI</b>
        <div style={{ borderTop: '1px dashed #4a3426', margin: '6px 0' }} />
        <div className="m-row"><span>Nasi ayam</span><span>25.000</span></div>
        <div className="m-row"><span>Es teh</span><span>5.000</span></div>
        <div className="m-row"><span>Kerupuk</span><span>2.000</span></div>
        <div style={{ borderTop: '1px dashed #4a3426', margin: '6px 0' }} />
        <div className="m-row"><b>TOTAL</b><b>32.000</b></div>
      </div>
      <div className="m-card" style={{ background: '#c9b6ff', color: '#4a3426' }}>
        <div className="m-muted" style={{ color: '#4a3426' }}>Terbaca otomatis</div>
        <div className="m-big">Rp 32.000</div>
        <div className="m-muted" style={{ color: '#4a3426' }}>Teks dibaca di HP-mu. Foto tidak dikirim.</div>
      </div>
      <div className="chip" style={{ background: '#ffc93c', textAlign: 'center', padding: 10, borderRadius: 14, fontSize: 12 }}>📷 Ambil foto struk</div>
      <Nav on={1} />
    </div>
  )
}

export function Trip() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Patungan perjalanan</div>
      <div className="m-card">
        <div className="m-muted">Total pengeluaran · Trip Bali</div>
        <div className="m-big">Rp 4.800.000</div>
        <div className="m-muted">Rp 1.200.000 per orang (4 orang)</div>
      </div>
      <div className="m-card" style={{ display: 'grid', gap: 7 }}>
        <b>Cara melunasi</b>
        <div className="m-row"><span>Rina ➜ Andi</span><b>Rp 350.000</b></div>
        <div className="m-row"><span>Budi ➜ Andi</span><b>Rp 200.000</b></div>
        <div className="m-row"><span>Budi ➜ Citra</span><b>Rp 150.000</b></div>
      </div>
      <div className="chip" style={{ background: '#8ec9ff', textAlign: 'center', padding: 10, borderRadius: 14, fontSize: 12 }}>+ Tambah pengeluaran</div>
      <Nav on={1} />
    </div>
  )
}

export function Biz() {
  return (
    <div className="screen fade-in">
      <div className="m-title">Mode usaha</div>
      <div className="m-card" style={{ display: 'grid', gap: 7 }}>
        <b>Keranjang</b>
        <div className="m-row"><span>Kopi susu x 3</span><span>Rp 54.000</span></div>
        <div className="m-row"><span>Roti bakar x 2</span><span>Rp 36.000</span></div>
        <div className="m-row"><b>Bayar</b><b>Rp 90.000</b></div>
        <div className="m-muted">Kembalian Rp 10.000</div>
      </div>
      <div className="m-card" style={{ background: '#7be0b0', color: '#4a3426' }}>
        <b>Produk terlaris</b>
        <div className="m-row"><span>Kopi susu</span><span>42 terjual</span></div>
      </div>
      <div className="chip" style={{ background: '#ffc93c', textAlign: 'center', padding: 10, borderRadius: 14, fontSize: 12 }}>🧾 Bagikan struk</div>
      <Nav on={0} />
    </div>
  )
}

export const SCREENS = { Dashboard, Transactions, Dreams, Debts, Scan, Trip, Biz }

export function Phone({ children, className = '' }) {
  return <div className={`phone ${className}`}>{children}</div>
}
