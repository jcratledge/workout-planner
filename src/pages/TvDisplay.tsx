import { useEffect, useState, useCallback, useRef } from 'react'
import { useParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { groupDisplayRows, type DisplayRow, type DisplayWorkout } from '../types/display'
import { useBlockTimer } from '../lib/useBlockTimer'
import { blockAccentVar } from '../lib/blockAccent'

export default function TvDisplay() {
  const { token } = useParams<{ token: string }>()
  const [workout, setWorkout] = useState<DisplayWorkout | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchWorkout = useCallback(async () => {
    if (!token) return
    const { data, error } = await supabase.rpc('get_display_workout', { token })
    if (error) {
      setError(error.message)
      setLoading(false)
      return
    }
    setWorkout(groupDisplayRows((data ?? []) as DisplayRow[]))
    setError(null)
    setLoading(false)
  }, [token])

  useEffect(() => {
    fetchWorkout()
  }, [fetchWorkout])

  // Remote control: a Chromecast/Fire Stick D-pad sends ordinary key events
  // to whatever's focused in the browser, so the TV can be driven directly
  // by its own remote — no phone, no trainer login required. Some TV
  // browsers instead move a focus cursor and fire a click on Enter/Select,
  // so this container is also focusable and click-advances as a fallback.
  const containerRef = useRef<HTMLDivElement>(null)
  const lastPressRef = useRef(0)

  const sendAdvance = useCallback(
    (direction: 'next' | 'previous') => {
      if (!token) return
      const now = Date.now()
      if (now - lastPressRef.current < 400) return // debounce rapid/held presses
      lastPressRef.current = now
      supabase.rpc('advance_display_session', { token, direction }).then(({ error }) => {
        if (error) setError(error.message)
      })
    },
    [token]
  )

  useEffect(() => {
    containerRef.current?.focus()
  }, [workout])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === 'Enter') {
        e.preventDefault()
        sendAdvance('next')
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault()
        sendAdvance('previous')
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [sendAdvance])

  // Realtime: any change to workouts, blocks, or their exercises re-pulls the
  // display. Simple and correct at this scale (a handful of gyms) — no need
  // to track gym_id ahead of time to scope the subscription.
  useEffect(() => {
    const channel = supabase
      .channel('tv-display-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'workouts' }, fetchWorkout)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'blocks' }, fetchWorkout)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'block_exercises' }, fetchWorkout)
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [fetchWorkout])

  if (loading) return <CenteredMessage>Loading today's workout…</CenteredMessage>
  if (error) return <CenteredMessage>Couldn't load the display: {error}</CenteredMessage>
  if (!workout) return <CenteredMessage>No workout published yet for today.</CenteredMessage>

  const isLive = workout.sessionStatus === 'in_progress' && workout.currentBlockId
  const activeBlock = isLive ? workout.blocks.find((b) => b.id === workout.currentBlockId) ?? null : null

  return (
    <div
      ref={containerRef}
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'ArrowRight' || e.key === 'Enter') sendAdvance('next')
        else if (e.key === 'ArrowLeft') sendAdvance('previous')
      }}
      onClick={() => sendAdvance('next')}
      className="min-h-screen flex flex-col p-10 outline-none"
    >
      <Header gymName={workout.gymName} date={workout.date} />
      {activeBlock ? (
        <LiveBlockView block={activeBlock} startedAt={workout.currentBlockStartedAt} />
      ) : (
        <OverviewView workout={workout} />
      )}
      <BrandFooter />
    </div>
  )
}

function BrandFooter() {
  return (
    <div className="flex items-center gap-2 justify-end pt-4 opacity-40">
      <img src="/lz-icon.png" alt="" className="w-4 h-4" />
      <span className="text-xs tracking-wide" style={{ color: 'var(--color-ink-muted)' }}>
        Powered by Leading Zero
      </span>
    </div>
  )
}

function Header({ gymName, date }: { gymName: string; date: string }) {
  const formatted = new Date(date + 'T00:00:00').toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  })
  return (
    <div className="flex items-baseline justify-between pb-8 border-b" style={{ borderColor: 'var(--color-panel-line)' }}>
      <span className="uppercase tracking-widest text-sm" style={{ color: 'var(--color-ink-muted)', fontFamily: 'var(--font-body)' }}>
        {gymName}
      </span>
      <span className="text-sm" style={{ color: 'var(--color-ink-muted)' }}>{formatted}</span>
    </div>
  )
}

function CenteredMessage({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex items-center justify-center text-center px-12">
      <p className="text-2xl" style={{ color: 'var(--color-ink-muted)', fontFamily: 'var(--font-body)' }}>
        {children}
      </p>
    </div>
  )
}

function LiveBlockView({
  block,
  startedAt,
}: {
  block: DisplayWorkout['blocks'][number]
  startedAt: string | null
}) {
  const timer = useBlockTimer(block, startedAt)
  const accent = blockAccentVar(block.label)
  const timerColor =
    timer.phase === 'work' ? accent : timer.phase === 'rest' ? 'var(--color-ink-muted)' : accent

  return (
    <div className="flex-1 flex flex-col justify-center gap-10 py-10">
      <div className="flex flex-col items-center gap-3">
        <span
          className="uppercase font-semibold tracking-wide text-2xl"
          style={{ color: accent, fontFamily: 'var(--font-display)' }}
        >
          {block.label}
        </span>
        <span
          className="text-[8rem] leading-none font-bold tabular-nums"
          style={{ color: timerColor, fontFamily: 'var(--font-mono)' }}
        >
          {timer.primary}
        </span>
        {timer.label && (
          <span className="uppercase tracking-widest text-lg" style={{ color: 'var(--color-ink-muted)' }}>
            {timer.label}
          </span>
        )}
        {startedAt === null && (
          <span className="text-sm" style={{ color: 'var(--color-ink-muted)' }}>
            Press ▶ on the remote to start the clock
          </span>
        )}
      </div>

      <div className="flex flex-col gap-4 max-w-3xl mx-auto w-full">
        {block.exercises.map((ex) => (
          <div
            key={ex.id}
            className="flex items-baseline justify-between rounded-lg px-6 py-4"
            style={{ backgroundColor: 'var(--color-panel)' }}
          >
            <span className="text-2xl font-medium" style={{ fontFamily: 'var(--font-body)' }}>
              {ex.name}
            </span>
            <span className="text-xl" style={{ color: 'var(--color-ink-muted)' }}>
              {formatExerciseMeta(ex)}
            </span>
          </div>
        ))}
      </div>

      {block.displayMessage && (
        <div
          className="max-w-3xl mx-auto w-full rounded-lg px-6 py-4 text-center text-xl italic"
          style={{ backgroundColor: 'var(--color-panel)', borderLeft: `4px solid ${accent}`, fontFamily: 'var(--font-body)' }}
        >
          {block.displayMessage}
        </div>
      )}
    </div>
  )
}

function OverviewView({ workout }: { workout: DisplayWorkout }) {
  return (
    <div className="flex-1 flex flex-col gap-8 py-10 max-w-3xl mx-auto w-full">
      <p className="text-center uppercase tracking-widest text-sm" style={{ color: 'var(--color-ink-muted)' }}>
        Press Next or OK on the remote to start
      </p>
      {workout.blocks.map((block) => {
        const accent = blockAccentVar(block.label)
        return (
          <div key={block.id}>
            <div className="flex items-center gap-3 mb-3">
              <span className="w-2 h-2 rounded-full" style={{ backgroundColor: accent }} />
              <span
                className="uppercase font-semibold tracking-wide text-xl"
                style={{ color: accent, fontFamily: 'var(--font-display)' }}
              >
                {block.label}
              </span>
            </div>
            <div className="flex flex-col gap-2 pl-5">
              {block.exercises.map((ex) => (
                <div key={ex.id} className="flex items-baseline justify-between">
                  <span className="text-lg" style={{ fontFamily: 'var(--font-body)' }}>{ex.name}</span>
                  <span className="text-base" style={{ color: 'var(--color-ink-muted)' }}>
                    {formatExerciseMeta(ex)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )
      })}
    </div>
  )
}

function formatExerciseMeta(ex: DisplayWorkout['blocks'][number]['exercises'][number]): string {
  const parts: string[] = []
  if (ex.reps) parts.push(ex.reps)
  if (ex.repsRight || ex.repsLeft) parts.push([ex.repsRight, ex.repsLeft].filter(Boolean).join(' / '))
  if (ex.tempo) parts.push(`tempo ${ex.tempo}`)
  if (ex.sets) parts.push(`${ex.sets} sets`)
  return parts.join(' · ')
}
