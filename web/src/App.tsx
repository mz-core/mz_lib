'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { AlertCircle, Check, ChevronRight, Info, TriangleAlert, X } from 'lucide-react'
import { resolveNui } from './nui'
import { applySkillCheck, clamp, createSkillCheckPlan, judgeSkillCheck, skillProgressDifficulties, type SkillProgressDifficulty, type SkillProgressOutcome } from './skillProgress'
import type { Field, MenuItem, Notice, NuiMessage } from './types'

type Overlay = { kind: string; data: Record<string, unknown> } | null
const icons = { success: Check, error: X, warning: TriangleAlert, info: Info }

export function App() {
  const [notices, setNotices] = useState<Notice[]>([])
  const [textUi, setTextUi] = useState<{ text: string; key?: string } | null>(null)
  const [progress, setProgress] = useState<{ label?: string; duration?: number; circle?: boolean } | null>(null)
  const [spinner, setSpinner] = useState<{ label?: string } | null>(null)
  const [overlay, setOverlay] = useState<Overlay>(null)

  useEffect(() => {
    function onMessage(event: MessageEvent<NuiMessage<Record<string, unknown>>>) {
      const { action, data } = event.data
      if (action === 'notify') {
        const notice = data as unknown as Notice
        setNotices((current) => [...current.filter((item) => item.id !== notice.id), notice])
        window.setTimeout(() => setNotices((current) => current.filter((item) => item.id !== notice.id)), notice.duration ?? 4000)
      } else if (action === 'textUI:show') setTextUi(data as { text: string; key?: string })
      else if (action === 'textUI:hide') setTextUi(null)
      else if (action === 'progress:show') setProgress(data as { label?: string; duration?: number; circle?: boolean })
      else if (action === 'progress:hide') setProgress(null)
      else if (action === 'spinner:show') setSpinner(data as { label?: string })
      else if (action === 'spinner:hide') setSpinner(null)
      else if (action === 'clipboard') void navigator.clipboard.writeText(String(data.value ?? ''))
      else if (action === 'skillProgress:cancel') {
        setOverlay((current) => current?.kind === 'skillProgress'
          ? { ...current, data: { ...current.data, cancelReason: data.reason ?? 'cancelled' } }
          : current)
      }
      else if (action.endsWith(':show')) setOverlay({ kind: action.split(':')[0], data })
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [])

  const resolve = useCallback((result: unknown, expectedRequestId?: string) => {
    setOverlay((current) => {
      // Guard: um timer antigo jamais responde a uma solicitacao nova.
      if (!current) return current
      if (expectedRequestId !== undefined && current.data.requestId !== expectedRequestId) return current
      resolveNui(current.data.requestId as string | undefined, result)
      return null
    })
  }, [])

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (!overlay) return
      if (event.key === 'Escape' && overlay.kind !== 'skillProgress') resolve(null)
      else if (overlay.kind === 'alert' && overlay.data.keyboard === true && event.code === 'KeyY') resolve(true)
      else if (overlay.kind === 'alert' && overlay.data.keyboard === true && event.code === 'KeyN') resolve(false)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [overlay, resolve])

  return <div className="app">
    <div className="notices" aria-live="polite">
      {notices.map((notice) => {
        const Icon = icons[notice.type] ?? AlertCircle
        return <article className={`panel notice ${notice.type}`} key={notice.id}>
          <span className="notice-icon"><Icon size={16} /></span>
          <div>{notice.title && <h3>{notice.title}</h3>}<p>{notice.description}</p></div>
        </article>
      })}
    </div>
    {textUi && <div className="panel text-ui"><span className="key">{textUi.key ?? 'E'}</span><span>{textUi.text}</span></div>}
    {progress && <div className="panel progress-wrap"><div className="progress-title"><span>{progress.label ?? 'Processando...'}</span><span>ESC</span></div><div className="track"><div className="fill" style={{ '--duration': `${progress.duration ?? 5000}ms` } as React.CSSProperties} /></div></div>}
    {spinner && <div className="panel spinner"><span className="spin"/><span>{spinner.label ?? 'Carregando...'}</span></div>}
    {overlay?.kind === 'context' && <ContextMenu data={overlay.data} resolve={resolve} />}
    {overlay?.kind === 'radial' && <ContextMenu data={overlay.data} resolve={resolve} title="Menu radial" />}
    {overlay?.kind === 'alert' && <Alert data={overlay.data} resolve={resolve} />}
    {overlay?.kind === 'input' && <InputDialog data={overlay.data} resolve={resolve} />}
    {(overlay?.kind === 'skill' || overlay?.kind === 'taskbar') && <Taskbar data={overlay.data} resolve={resolve} />}
    {overlay?.kind === 'skillProgress' && <SkillProgress key={String(overlay.data.requestId)} data={overlay.data} resolve={resolve} />}
  </div>
}

function Shell({ children }: { children: React.ReactNode }) { return <div className="modal-wrap"><section className="panel modal">{children}</section></div> }
function ContextMenu({ data, resolve, title }: { data: Record<string, unknown>; resolve: (v: unknown) => void; title?: string }) {
  const items = (data.items ?? data.options ?? []) as MenuItem[]
  return <Shell><h2>{String(data.title ?? title ?? 'Menu')}</h2>{Boolean(data.description) && <p className="muted">{String(data.description)}</p>}<div className="items">{items.map((item, index) => <button className="item" disabled={item.disabled} key={`${item.title}-${index}`} onClick={() => resolve(item.value ?? index)}><span><strong>{item.title}</strong>{item.description && <small>{item.description}</small>}</span><ChevronRight size={16}/></button>)}</div></Shell>
}
function Alert({ data, resolve }: { data: Record<string, unknown>; resolve: (v: unknown, expectedRequestId?: string) => void }) {
  const duration = Number(data.duration)
  const hasTimeout = Number.isFinite(duration) && duration > 0

  // Timeout opcional: fecha sozinho e retorna nil (nunca false, que e exclusivo de N).
  useEffect(() => {
    if (!hasTimeout) return
    const requestId = data.requestId as string | undefined
    const timer = window.setTimeout(() => resolve(null, requestId), duration)
    return () => window.clearTimeout(timer)
  }, [data, duration, hasTimeout, resolve])

  const content = (
    <>
      <h2>{String(data.title ?? 'Confirmar ação')}</h2>
      <p className="muted">{String(data.description ?? 'Deseja continuar?')}</p>
      <div className="actions">
        <button className="button" onClick={() => resolve(false)}>{data.keyboard === true && <kbd>N</kbd>}{String(data.cancelLabel ?? 'Cancelar')}</button>
        <button className="button primary" onClick={() => resolve(true)}>{data.keyboard === true && <kbd>Y</kbd>}{String(data.confirmLabel ?? 'Confirmar')}</button>
      </div>
    </>
  )

  if (data.variant === 'compact') {
    return <div className="alert-compact-wrap"><section className="panel alert-compact" role="dialog" aria-label={String(data.title ?? 'Confirmar ação')}>{content}</section></div>
  }
  return <Shell>{content}</Shell>
}
function InputDialog({ data, resolve }: { data: Record<string, unknown>; resolve: (v: unknown) => void }) {
  const fields = (data.fields ?? []) as Field[]
  const [values, setValues] = useState<Record<string, unknown>>(() => Object.fromEntries(fields.map((field) => [field.name, field.default ?? (field.type === 'checkbox' ? false : '')])))
  return <Shell><h2>{String(data.title ?? 'Formulário')}</h2><div className="fields">{fields.map((field) => <label className="field" key={field.name}><span>{field.label}</span>{field.type === 'textarea' ? <textarea onChange={(e) => setValues({...values,[field.name]:e.target.value})} /> : field.type === 'select' ? <select onChange={(e) => setValues({...values,[field.name]:e.target.value})}><option value="">Selecione</option>{field.options?.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select> : <input type={field.type === 'checkbox' ? 'checkbox' : field.type} required={field.required} onChange={(e) => setValues({...values,[field.name]:field.type === 'checkbox' ? e.target.checked : e.target.value})}/>}</label>)}</div><div className="actions"><button className="button" onClick={() => resolve(null)}>Cancelar</button><button className="button primary" onClick={() => resolve(values)}>Enviar</button></div></Shell>
}
function Taskbar({ data, resolve }: { data: Record<string, unknown>; resolve: (v: unknown) => void }) {
  const track = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const duration = Math.max(1500, Number(data.duration) || 6500)
    const timeout = window.setTimeout(() => resolve(false), duration)
    const onKey = (event: KeyboardEvent) => {
      if (event.code !== String(data.key ?? 'Space')) return
      const marker = track.current?.querySelector('.skill-marker')?.getBoundingClientRect()
      const target = track.current?.querySelector('.skill-target')?.getBoundingClientRect()
      resolve(Boolean(marker && target && marker.left >= target.left && marker.right <= target.right))
    }
    window.addEventListener('keydown', onKey)
    return () => { window.clearTimeout(timeout); window.removeEventListener('keydown', onKey) }
  }, [data, resolve])
  const target = Math.max(10, Math.min(85, Number(data.target) || 66))
  const zone = Math.max(8, Math.min(30, Number(data.zone) || 14))
  return <section className="panel taskbar" role="dialog" aria-label={String(data.title ?? 'Teste de perícia')}>
    <header><div><strong>{String(data.title ?? 'Teste de perícia')}</strong><span>{String(data.label ?? 'Acerte a zona de sucesso')}</span></div><kbd>{String(data.keyLabel ?? 'ESPAÇO')}</kbd></header>
    <div className="skill-track" ref={track} style={{ '--duration': `${Math.max(1500, Number(data.duration) || 6500)}ms` } as React.CSSProperties}>
      <span className="skill-target" style={{ left: `${target}%`, width: `${zone}%` }}/><span className="skill-marker"/>
    </div>
  </section>
}

type SkillProgressStats = { hits: number; perfects: number; misses: number }
type ActiveSkillCheck = { startedAt: number; center: number; revolutionMs: number; successDegrees: number; perfectDegrees: number }

let skillAudio: AudioContext | null = null
function playSkillTone(frequency: number, duration = 0.055) {
  try {
    skillAudio ??= new AudioContext()
    const oscillator = skillAudio.createOscillator()
    const gain = skillAudio.createGain()
    oscillator.frequency.value = frequency
    gain.gain.setValueAtTime(0.035, skillAudio.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, skillAudio.currentTime + duration)
    oscillator.connect(gain).connect(skillAudio.destination)
    oscillator.start()
    oscillator.stop(skillAudio.currentTime + duration)
  } catch { /* áudio é feedback opcional; a mecânica não depende dele */ }
}

function SkillProgress({ data, resolve }: { data: Record<string, unknown>; resolve: (v: unknown) => void }) {
  const duration = Math.max(1000, Number(data.duration) || 20000)
  const difficulty = (['easy', 'medium', 'hard'].includes(String(data.difficulty)) ? data.difficulty : 'medium') as SkillProgressDifficulty
  const tuning = skillProgressDifficulties[difficulty]
  const revolutionMs = Math.min(tuning.revolutionMs, duration * ({ easy: 0.36, medium: 0.28, hard: 0.22 }[difficulty]))
  const latestCheckProgress = clamp(88 - revolutionMs / duration * 100, 42, 78)
  const skillchecks = (data.skillchecks ?? {}) as { min?: number; max?: number }
  const minimum = Math.round(clamp(Number(skillchecks.min) || 2, 1, 8))
  const maximum = Math.round(clamp(Number(skillchecks.max) || 4, minimum, 8))
  const [plan] = useState(() => createSkillCheckPlan(minimum + Math.floor(Math.random() * (maximum - minimum + 1)), Math.random, latestCheckProgress))
  const [progress, setProgress] = useState(0)
  const [check, setCheck] = useState<ActiveSkillCheck | null>(null)
  const [pointerAngle, setPointerAngle] = useState(0)
  const [feedback, setFeedback] = useState<SkillProgressOutcome | null>(null)
  const progressRef = useRef(0)
  const checkRef = useRef<ActiveSkillCheck | null>(null)
  const statsRef = useRef<SkillProgressStats>({ hits: 0, perfects: 0, misses: 0 })
  const nextCheckRef = useRef(0)
  const nextAllowedAtRef = useRef(0)
  const startedAtRef = useRef(performance.now())
  const finishedRef = useRef(false)
  const feedbackTimerRef = useRef<number | null>(null)

  const finish = useCallback((success: boolean, cancelled: boolean, reason?: string) => {
    if (finishedRef.current) return
    finishedRef.current = true
    checkRef.current = null
    const stats = statsRef.current
    resolve({ success, cancelled, reason, ...stats, duration: Math.round(performance.now() - startedAtRef.current) })
  }, [resolve])

  const showFeedback = useCallback((outcome: SkillProgressOutcome) => {
    if (feedbackTimerRef.current) window.clearTimeout(feedbackTimerRef.current)
    setFeedback(outcome)
    feedbackTimerRef.current = window.setTimeout(() => setFeedback(null), 800)
  }, [])

  const settleCheck = useCallback((outcome: SkillProgressOutcome, now: number) => {
    if (!checkRef.current) return
    checkRef.current = null
    setCheck(null)
    setPointerAngle(0)
    const perfectBonus = Number.isFinite(Number(data.perfectBonus)) ? Number(data.perfectBonus) : 6
    const missPenalty = Number.isFinite(Number(data.missPenalty)) ? Number(data.missPenalty) : 7
    progressRef.current = applySkillCheck(progressRef.current, outcome, perfectBonus, missPenalty)
    setProgress(progressRef.current)
    if (outcome === 'perfect') statsRef.current.perfects += 1
    else if (outcome === 'normal') statsRef.current.hits += 1
    else statsRef.current.misses += 1
    nextAllowedAtRef.current = now + Math.max(900, duration * 0.06)
    showFeedback(outcome)
    playSkillTone(outcome === 'perfect' ? 880 : outcome === 'normal' ? 660 : 180, outcome === 'miss' ? 0.09 : 0.055)
  }, [data.missPenalty, data.perfectBonus, duration, showFeedback])

  useEffect(() => {
    if (data.cancelReason) finish(false, true, String(data.cancelReason))
  }, [data.cancelReason, finish])

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && data.canCancel !== false) {
        event.preventDefault()
        finish(false, true, 'cancelled')
        return
      }
      if (event.code !== 'Space' || event.repeat) return
      const active = checkRef.current
      if (!active) return
      event.preventDefault()
      const now = performance.now()
      const elapsed = now - active.startedAt
      if (elapsed >= active.revolutionMs) settleCheck('miss', now)
      else settleCheck(judgeSkillCheck((elapsed / active.revolutionMs) * 360, active.center, active.successDegrees, active.perfectDegrees), now)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [data.canCancel, finish, settleCheck])

  useEffect(() => {
    let frame = 0
    let previous = performance.now()
    const tick = (now: number) => {
      if (finishedRef.current) return
      const elapsed = Math.max(0, now - previous)
      previous = now
      progressRef.current = clamp(progressRef.current + elapsed / duration * 100)
      setProgress(progressRef.current)

      const active = checkRef.current
      if (active) {
        const checkElapsed = now - active.startedAt
        setPointerAngle(clamp(checkElapsed / active.revolutionMs, 0, 1) * 360)
        if (checkElapsed >= active.revolutionMs) settleCheck('miss', now)
      } else if (nextCheckRef.current < plan.length && progressRef.current >= plan[nextCheckRef.current] && progressRef.current < 88 && now >= nextAllowedAtRef.current) {
        const next = {
          startedAt: now,
          center: 90 + Math.random() * 210,
          revolutionMs,
          successDegrees: tuning.successDegrees,
          perfectDegrees: tuning.perfectDegrees,
        }
        nextCheckRef.current += 1
        checkRef.current = next
        setCheck(next)
        setPointerAngle(0)
        playSkillTone(520)
      }

      if (progressRef.current >= 100) finish(true, false)
      else frame = requestAnimationFrame(tick)
    }
    frame = requestAnimationFrame(tick)
    return () => {
      cancelAnimationFrame(frame)
      if (feedbackTimerRef.current) window.clearTimeout(feedbackTimerRef.current)
    }
  }, [duration, finish, plan, revolutionMs, settleCheck, tuning])

  const normalStart = check ? check.center - check.successDegrees / 2 : 0
  const perfectStart = check ? check.center - check.perfectDegrees / 2 : 0
  const stats = statsRef.current
  return <section className="panel skill-progress" role="dialog" aria-label={String(data.label ?? 'SkillProgress')}>
    <div className="skill-progress-copy">
      <div className="skill-progress-heading"><span>{String(data.label ?? 'Executando atividade')}</span><strong>{Math.round(progress)}%</strong></div>
      <div className="skill-progress-track" aria-label={`Progresso ${Math.round(progress)}%`}><span style={{ width: `${progress}%` }} /></div>
      <div className="skill-progress-meta"><span>{stats.hits} acertos</span><span>{stats.perfects} perfeitos</span><span>{stats.misses} erros</span><kbd>ESC</kbd></div>
    </div>
    {check && <div className="skill-dial" aria-label="Skillcheck ativo">
      <svg viewBox="0 0 120 120" aria-hidden="true">
        <circle className="skill-dial-ring" cx="60" cy="60" r="48" pathLength="100" />
        <circle className="skill-dial-success" cx="60" cy="60" r="48" pathLength="100" strokeDasharray={`${check.successDegrees / 3.6} 100`} transform={`rotate(${normalStart - 90} 60 60)`} />
        <circle className="skill-dial-perfect" cx="60" cy="60" r="48" pathLength="100" strokeDasharray={`${check.perfectDegrees / 3.6} 100`} transform={`rotate(${perfectStart - 90} 60 60)`} />
        <g className="skill-dial-pointer" transform={`rotate(${pointerAngle} 60 60)`}><line x1="60" y1="60" x2="60" y2="10" /><circle cx="60" cy="60" r="4" /></g>
      </svg>
      <kbd>ESPAÇO</kbd>
    </div>}
    {feedback && <div className={`skill-feedback ${feedback}`} role="status">{feedback === 'perfect' ? 'PERFEITO' : feedback === 'normal' ? 'ACERTO' : 'ERRO'}</div>}
  </section>
}
