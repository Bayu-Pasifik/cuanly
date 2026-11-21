import { useEffect, useState } from 'react'
import { SCREENS, Phone, Dashboard, Transactions, Dreams } from './components/Screens.jsx'
import { useReveal, useCountUp, useInView, useLatestRelease, rp, REPO } from './hooks.js'
import { MARQUEE, FEATURES, TABS, MODES, STEPS, PRIVACY, QUOTES, FAQ } from './data.js'

const REL = `https://github.com/${REPO}/releases/latest`

function Nav({ theme, setTheme }) {
  const [open, setOpen] = useState(false)
  const go = () => setOpen(false)
  return (
    <header className="nav">
      <div className="nav-in">
        <a className="brand" href="#top"><img src="logo.svg" alt="" />Cuanly</a>
        <div className={`links ${open ? 'open' : ''}`}>
          <a className="l" href="#fitur" onClick={go}>Fitur</a>
          <a className="l" href="#tampilan" onClick={go}>Tampilan</a>
          <a className="l" href="#mode" onClick={go}>Mode</a>
          <a className="l" href="#privasi" onClick={go}>Privasi</a>
          <a className="l" href="#faq" onClick={go}>FAQ</a>
          <button className="icon-btn" aria-label="Ganti tema" onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>
          <a className="btn" href="#unduh" onClick={go} style={{ padding: '9px 18px' }}>Unduh</a>
          <button className="icon-btn burger" aria-label="Menu" onClick={() => setOpen(!open)}>☰</button>
        </div>
      </div>
    </header>
  )
}

function Hero() {
  return (
    <section className="hero" id="top">
      <div className="blob" style={{ width: 420, height: 420, background: 'var(--yellow)', top: -120, right: -100 }} />
      <div className="blob" style={{ width: 260, height: 260, background: 'var(--lilac)', bottom: 40, left: -90 }} />
      <div className="wrap hero-grid">
        <div>
          <span className="eyebrow rv">Pencatat keuangan pribadi · Android</span>
          <h1 className="rv">Catat uang,<br />capai <span className="hl">impian.</span></h1>
          <p className="lead rv">Cuanly bikin urusan duit jadi ringan dan menyenangkan: banyak dompet, anggaran, impian, utang, sampai scan struk. Cukup beberapa ketukan.</p>
          <div className="cta-row rv">
            <a className="btn big" href="#unduh">⬇ Unduh gratis</a>
            <a className="btn big ghost" href="#fitur">Lihat fitur</a>
          </div>
          <div className="trust rv">
            <span>Gratis</span><span>Mode gelap</span><span>Kunci PIN & biometrik</span><span>Backup data</span>
          </div>
        </div>
        <div className="hero-phone rv">
          <div className="sticker s1">🎉 Anggaran aman!</div>
          <div className="sticker s2">🧾 Scan struk</div>
          <div className="sticker s3">🌈 Impian 62%</div>
          <Phone><Dashboard /></Phone>
        </div>
      </div>
    </section>
  )
}

function Marquee() {
  const items = [...MARQUEE, ...MARQUEE]
  return (
    <div className="marquee" aria-hidden="true">
      <div className="mq-track">{items.map((m, i) => <span key={i}>{m}</span>)}</div>
    </div>
  )
}

function Stat({ n, suffix = '', label, run }) {
  const v = useCountUp(n, run)
  return <div className="stat"><b>{v}{suffix}</b><span>{label}</span></div>
}

function Stats() {
  const [ref, seen] = useInView()
  return (
    <section className="section" style={{ paddingBottom: 40 }}>
      <div className="wrap center">
        <span className="eyebrow rv">Kenapa Cuanly</span>
        <h2 className="h2 rv">Lengkap, tapi tidak ribet.</h2>
        <p className="lead rv">Semua yang kamu butuhkan buat mengatur uang harian, dalam satu app yang ramah dan enak dilihat.</p>
        <div className="stats rv" ref={ref}>
          <Stat n={13} label="fitur & mode dalam satu app" run={seen} />
          <Stat n={4} label="tab utama, mudah dijangkau" run={seen} />
          <Stat n={0} suffix=" biaya" label="tanpa langganan" run={seen} />
          <Stat n={100} suffix="%" label="scan struk dibaca di HP-mu" run={seen} />
        </div>
      </div>
    </section>
  )
}

function Features() {
  return (
    <section className="section" id="fitur">
      <div className="wrap">
        <span className="eyebrow rv">Fitur</span>
        <h2 className="h2 rv">Satu app, banyak jurus.</h2>
        <p className="lead rv">Dari mencatat jajan harian sampai memantau portofolio investasi. Semua ada tanpa harus pindah-pindah aplikasi.</p>
        <div className="bento">
          {FEATURES.map((f) => (
            <article key={f.t} className={`bcard rv ${f.cls}`}>
              <div className="ico">{f.ico}</div>
              <h3>{f.t}</h3>
              <p>{f.p}</p>
              {f.tags && <div className="tags">{f.tags.map((t) => <span key={t}>{t}</span>)}</div>}
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

function Showcase() {
  const [i, setI] = useState(0)
  const Screen = SCREENS[TABS[i].k]
  return (
    <section className="section showcase" id="tampilan">
      <div className="wrap">
        <span className="eyebrow rv">Intip tampilannya</span>
        <h2 className="h2 rv">Rapi, berwarna, dan ramah.</h2>
        <div className="show-grid">
          <div className="tabs rv">
            {TABS.map((t, k) => (
              <button key={t.k} className={`tab ${k === i ? 'on' : ''}`} onClick={() => setI(k)} onMouseEnter={() => setI(k)}>
                <h4><span>{t.e}</span>{t.t}</h4>
                <p>{t.p}</p>
              </button>
            ))}
          </div>
          <div className="show-phone rv">
            <Phone><Screen key={i} /></Phone>
          </div>
        </div>
      </div>
    </section>
  )
}

function Modes() {
  return (
    <section className="section" id="mode">
      <div className="wrap center">
        <span className="eyebrow rv">Mode spesial</span>
        <h2 className="h2 rv">Uang bukan cuma urusan sendiri.</h2>
        <p className="lead rv">Atur bareng pasangan, bagi rata biaya trip, atau jalankan usaha kecil langsung dari Cuanly.</p>
        <div className="modes" style={{ textAlign: 'left' }}>
          {MODES.map((m) => (
            <article key={m.t} className={`mode rv ${m.cls}`}>
              <div className="big-emoji">{m.e}</div>
              <h3>{m.t}</h3>
              <ul>{m.items.map((x) => <li key={x}>{x}</li>)}</ul>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

function Steps() {
  return (
    <section className="section" style={{ paddingTop: 40 }}>
      <div className="wrap center">
        <span className="eyebrow rv">Cara pakai</span>
        <h2 className="h2 rv">Mulai dalam 4 langkah.</h2>
        <div className="steps" style={{ textAlign: 'left' }}>
          {STEPS.map((s, n) => (
            <div key={s.t} className="step rv">
              <span className="n">{n + 1}</span>
              <h4>{s.t}</h4>
              <p>{s.p}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function Calc() {
  const [goal, setGoal] = useState(15000000)
  const [save, setSave] = useState(1000000)
  const months = Math.ceil(goal / save)
  const pct = Math.min(100, (save * 6 / goal) * 100)
  return (
    <section className="section" style={{ paddingTop: 40 }}>
      <div className="wrap">
        <span className="eyebrow rv">Coba sendiri</span>
        <h2 className="h2 rv">Kapan impianmu tercapai?</h2>
        <p className="lead rv">Geser slider, lihat berapa bulan sampai target. Persis semangat Planner impian di Cuanly.</p>
        <div className="calc rv">
          <div>
            <label>Target impian: <b>{rp(goal)}</b></label>
            <input type="range" min="1000000" max="100000000" step="500000" value={goal} onChange={(e) => setGoal(+e.target.value)} />
            <label>Nabung per bulan: <b>{rp(save)}</b></label>
            <input type="range" min="100000" max="10000000" step="50000" value={save} onChange={(e) => setSave(+e.target.value)} />
          </div>
          <div className="out">
            <span className="m-muted" style={{ fontWeight: 700 }}>Tercapai dalam</span>
            <b>{months >= 12 ? `${Math.floor(months / 12)} th ${months % 12} bln` : `${months} bulan`}</b>
            <div className="pbar"><i style={{ width: pct + '%' }} /></div>
            <div className="val"><span>Setelah 6 bulan</span><span>{Math.round(pct)}%</span></div>
          </div>
        </div>
      </div>
    </section>
  )
}

function Theme({ theme, setTheme }) {
  return (
    <section className="section" style={{ paddingTop: 40 }}>
      <div className="wrap">
        <div className="theme-demo">
          <div>
            <span className="eyebrow rv">Terang & gelap</span>
            <h2 className="h2 rv">Nyaman dilihat siang dan malam.</h2>
            <p className="lead rv">Pilih Terang, Gelap, atau ikuti Sistem. Palet krem hangat dan kuning cerah tetap terasa di keduanya.</p>
            <div className="cta-row rv">
              <button className="btn" onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>{theme === 'dark' ? '☀️ Coba mode terang' : '🌙 Coba mode gelap'}</button>
            </div>
          </div>
          <div className="phones-pair rv">
            <Phone className="fixed-light"><Transactions /></Phone>
            <Phone className="fixed-dark"><Dreams /></Phone>
          </div>
        </div>
      </div>
    </section>
  )
}

function Privacy() {
  return (
    <section className="section" id="privasi" style={{ paddingTop: 40 }}>
      <div className="wrap">
        <div className="privacy">
          <span className="eyebrow rv">Privasi & kendali</span>
          <h2 className="h2 rv">Datamu, aturanmu.</h2>
          <p className="lead rv">Uang itu urusan pribadi. Cuanly dirancang supaya kamu tetap memegang kendali.</p>
          <div className="p-grid">
            {PRIVACY.map((p) => (
              <div key={p.t} className="p-item rv">
                <div style={{ fontSize: '1.8rem' }}>{p.e}</div>
                <h4>{p.t}</h4>
                <p>{p.p}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

function Quotes() {
  return (
    <section className="section" style={{ paddingTop: 40 }}>
      <div className="wrap center">
        <span className="eyebrow rv">Cocok untuk siapa</span>
        <h2 className="h2 rv">Dari freelancer sampai pemilik kedai.</h2>
        <p className="lead rv">Contoh persona ilustratif, bukan testimoni pengguna sungguhan.</p>
        <div className="quotes" style={{ textAlign: 'left' }}>
          {QUOTES.map((q) => (
            <figure key={q.n} className={`quote rv ${q.cls}`}>
              <div className="stars">★★★★★</div>
              <p>“{q.q}”</p>
              <figcaption className="who"><span className="avatar">{q.e}</span>{q.n}</figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  )
}

function Faq() {
  const [open, setOpen] = useState(0)
  return (
    <section className="section" id="faq" style={{ paddingTop: 40 }}>
      <div className="wrap center">
        <span className="eyebrow rv">FAQ</span>
        <h2 className="h2 rv">Pertanyaan yang sering muncul.</h2>
        <div className="faq" style={{ textAlign: 'left' }}>
          {FAQ.map(([q, a], i) => (
            <div key={q} className="rv">
              <div className={`qa ${open === i ? 'open' : ''}`}>
                <button onClick={() => setOpen(open === i ? -1 : i)} aria-expanded={open === i}>
                  {q}<span className="plus">+</span>
                </button>
                <div className="ans"><div><p>{a}</p></div></div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

const ABI = { 'arm64-v8a': 'HP modern (disarankan)', 'armeabi-v7a': 'HP lama 32-bit', x86_64: 'Emulator / x86' }

function Download() {
  const rel = useLatestRelease()
  const apks = (rel?.assets || []).filter((a) => a.name.endsWith('.apk'))
  const arm = apks.find((a) => a.name.includes('arm64'))
  return (
    <section className="section" id="unduh" style={{ paddingTop: 40 }}>
      <div className="wrap">
        <div className="download">
          <span className="deco" style={{ top: 30, left: 40 }}>🪙</span>
          <span className="deco" style={{ bottom: 40, right: 50, animationDelay: '-2s' }}>💰</span>
          <span className="deco" style={{ top: 50, right: 90, animationDelay: '-4s' }}>✨</span>
          <span className="eyebrow">Gratis · Android</span>
          <h2 className="h2">Mulai atur uangmu hari ini.</h2>
          <p className="lead">Unduh Cuanly {rel ? `versi ${rel.tag_name}` : ''} dan rasakan catat keuangan yang tidak membosankan.</p>
          <div className="dl-list">
            <a className="btn big main" href={arm ? arm.browser_download_url : REL}>⬇ Unduh APK{arm ? ' (arm64)' : ''}</a>
            <a className="btn big" href={REL}>Semua rilis</a>
          </div>
          {apks.length > 1 && (
            <div className="dl-list" style={{ marginTop: 14 }}>
              {apks.map((a) => {
                const abi = Object.keys(ABI).find((k) => a.name.includes(k))
                return <a key={a.id} className="btn" style={{ padding: '8px 16px', fontSize: '.88rem' }} href={a.browser_download_url}>{abi || a.name} · {ABI[abi] || ''}</a>
              })}
            </div>
          )}
          <p className="small">Izinkan "instal dari sumber tidak dikenal" saat memasang APK. Perbarui nanti lewat Pengaturan, Tentang, Periksa pembaruan.</p>
        </div>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer>
      <div className="wrap">
        <div className="foot">
          <div>
            <a className="brand" href="#top"><img src="logo.svg" alt="" />Cuanly</a>
            <p style={{ color: 'var(--muted)', marginTop: 10, maxWidth: 300 }}>Catat uang, capai impian.</p>
          </div>
          <nav>
            <a href="#fitur">Fitur</a><a href="#mode">Mode</a><a href="#privasi">Privasi</a><a href="#faq">FAQ</a>
            <a href={`https://github.com/${REPO}`} target="_blank" rel="noreferrer">GitHub</a>
            <a href={REL} target="_blank" rel="noreferrer">Rilis</a>
          </nav>
        </div>
        <p className="copy">© {new Date().getFullYear()} Cuanly. Dibuat dengan Flutter & Supabase. Konten edukasi adalah panduan umum, bukan saran keuangan.</p>
      </div>
    </footer>
  )
}

export default function App() {
  const [theme, setTheme] = useState(() => {
    try { return localStorage.getItem('theme') || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') } catch { return 'light' }
  })
  useEffect(() => {
    document.documentElement.dataset.theme = theme
    try { localStorage.setItem('theme', theme) } catch { /* ignore */ }
  }, [theme])
  useReveal()
  return (
    <>
      <Nav theme={theme} setTheme={setTheme} />
      <main>
        <Hero />
        <Marquee />
        <Stats />
        <Features />
        <Showcase />
        <Modes />
        <Steps />
        <Calc />
        <Theme theme={theme} setTheme={setTheme} />
        <Privacy />
        <Quotes />
        <Faq />
        <Download />
      </main>
      <Footer />
    </>
  )
}
