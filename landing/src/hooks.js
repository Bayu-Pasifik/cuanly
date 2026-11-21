import { useEffect, useRef, useState } from 'react'

export const REPO = 'Bayu-Pasifik/cuanly'

export function useReveal() {
  useEffect(() => {
    const els = document.querySelectorAll('.rv')
    const io = new IntersectionObserver(
      (es) => es.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target) } }),
      { threshold: 0.12 }
    )
    els.forEach((el) => io.observe(el))
    return () => io.disconnect()
  }, [])
}

export function useCountUp(target, run, ms = 1400) {
  const [v, setV] = useState(0)
  useEffect(() => {
    if (!run) return
    let raf, t0
    const tick = (t) => {
      t0 ??= t
      const p = Math.min((t - t0) / ms, 1)
      setV(Math.round(target * (1 - Math.pow(1 - p, 3))))
      if (p < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [target, run, ms])
  return v
}

export function useInView() {
  const ref = useRef(null)
  const [seen, setSeen] = useState(false)
  useEffect(() => {
    const io = new IntersectionObserver(([e]) => e.isIntersecting && setSeen(true), { threshold: 0.4 })
    if (ref.current) io.observe(ref.current)
    return () => io.disconnect()
  }, [])
  return [ref, seen]
}

export function useLatestRelease() {
  const [rel, setRel] = useState(null)
  useEffect(() => {
    fetch(`https://api.github.com/repos/${REPO}/releases/latest`)
      .then((r) => (r.ok ? r.json() : null))
      .then(setRel)
      .catch(() => {})
  }, [])
  return rel
}

export const rp = (n) => 'Rp ' + Math.round(n).toLocaleString('id-ID')
