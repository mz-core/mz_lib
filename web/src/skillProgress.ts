export type SkillProgressOutcome = 'normal' | 'perfect' | 'miss'

export const skillProgressDifficulties = {
  easy: { revolutionMs: 4800, successDegrees: 88, perfectDegrees: 24 },
  medium: { revolutionMs: 3400, successDegrees: 64, perfectDegrees: 14 },
  hard: { revolutionMs: 2400, successDegrees: 42, perfectDegrees: 8 },
} as const

export type SkillProgressDifficulty = keyof typeof skillProgressDifficulties

export function clamp(value: number, minimum = 0, maximum = 100) {
  return Math.max(minimum, Math.min(maximum, value))
}

export function createSkillCheckPlan(count: number, random = Math.random, end = 80) {
  const total = Math.round(clamp(count, 1, 8))
  const start = 12
  const span = Math.max(20, clamp(end, 32, 80) - start)
  const segment = span / total
  return Array.from({ length: total }, (_, index) => {
    const center = start + segment * (index + 0.5)
    const jitter = (random() - 0.5) * Math.min(8, segment * 0.55)
    return clamp(center + jitter, start, start + span)
  })
}

export function isAngleInside(angle: number, center: number, size: number) {
  const distance = Math.abs(((angle - center + 540) % 360) - 180)
  return distance <= size / 2 + Number.EPSILON
}

export function judgeSkillCheck(angle: number, center: number, successDegrees: number, perfectDegrees: number): SkillProgressOutcome {
  if (isAngleInside(angle, center, perfectDegrees)) return 'perfect'
  if (isAngleInside(angle, center, successDegrees)) return 'normal'
  return 'miss'
}

export function applySkillCheck(progress: number, outcome: SkillProgressOutcome, perfectBonus: number, missPenalty: number) {
  if (outcome === 'perfect') return clamp(progress + perfectBonus)
  if (outcome === 'miss') return clamp(progress - missPenalty)
  return clamp(progress)
}
