import { useEffect, useState } from 'react'
import type { DisplayBlock } from '../types/display'

function formatClock(totalSeconds: number): string {
  const s = Math.max(0, Math.round(totalSeconds))
  const mm = Math.floor(s / 60)
  const ss = s % 60
  return `${mm.toString().padStart(2, '0')}:${ss.toString().padStart(2, '0')}`
}

/** Ticks once a second. Returns elapsed seconds since `startedAt`, or 0 if not started. */
function useElapsedSeconds(startedAt: string | null): number {
  const [elapsed, setElapsed] = useState(0)

  useEffect(() => {
    if (!startedAt) {
      setElapsed(0)
      return
    }
    const startMs = new Date(startedAt).getTime()
    const tick = () => setElapsed((Date.now() - startMs) / 1000)
    tick()
    const id = setInterval(tick, 250)
    return () => clearInterval(id)
  }, [startedAt])

  return elapsed
}

export interface TimerState {
  /** Big number on screen, e.g. "01:30" */
  primary: string
  /** Small label above/below the number, e.g. "WORK", "ROUND 3 OF 5", "TIME CAP" */
  label: string
  /** Used to color the timer: 'work' | 'rest' | 'neutral' */
  phase: 'work' | 'rest' | 'neutral'
}

/** Derives what the LED-style timer should show, based on the block's own config
 *  and how long it's been running — no server-side ticking required. */
export function useBlockTimer(block: DisplayBlock | null, startedAt: string | null): TimerState {
  const elapsed = useElapsedSeconds(startedAt)

  if (!block) {
    return { primary: '00:00', label: '', phase: 'neutral' }
  }

  if ((block.type === 'interval' || block.type === 'circuit') && block.workSeconds && block.restSeconds) {
    const cycle = block.workSeconds + block.restSeconds
    const roundIndex = Math.floor(elapsed / cycle) + 1
    const round = block.rounds ? Math.min(roundIndex, block.rounds) : roundIndex
    const phaseElapsed = elapsed % cycle
    const inWork = phaseElapsed < block.workSeconds
    const remaining = inWork ? block.workSeconds - phaseElapsed : cycle - phaseElapsed
    const roundLabel = block.rounds ? `ROUND ${round} OF ${block.rounds}` : `ROUND ${round}`
    return {
      primary: formatClock(remaining),
      label: `${inWork ? 'WORK' : 'REST'} · ${roundLabel}`,
      phase: inWork ? 'work' : 'rest',
    }
  }

  if ((block.type === 'emom' || block.type === 'amrap') && block.timeCapSeconds) {
    const remaining = block.timeCapSeconds - elapsed
    const minuteLabel = block.type === 'emom' ? `MINUTE ${Math.min(Math.floor(elapsed / 60) + 1, Math.ceil(block.timeCapSeconds / 60))}` : ''
    return {
      primary: formatClock(remaining),
      label: block.type === 'emom' ? minuteLabel : 'TIME CAP',
      phase: remaining <= 0 ? 'rest' : 'work',
    }
  }

  // warmup / straight_sets / pyramid / anything without explicit timing: count up,
  // same behavior as the physical "UP" wall clock this replaces.
  return {
    primary: formatClock(elapsed),
    label: 'ELAPSED',
    phase: 'neutral',
  }
}
