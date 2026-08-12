import { useEffect, useState } from 'react'
import { useAuth } from '../lib/auth'
import { supabase } from '../lib/supabase'

type Block = {
  id: string
  label: string
  block_order: number
  block_type: string
}

type WorkoutSummary = {
  id: string
  workout_date: string
  status: string
  blocks: Block[]
}

export default function BuilderHome() {
  const { profile, signOut } = useAuth()
  const [gymName, setGymName] = useState<string | null>(null)
  const [workout, setWorkout] = useState<WorkoutSummary | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!profile) return

    async function load() {
      if (profile!.gym_id) {
        const { data: gym } = await supabase.from('gyms').select('name').eq('id', profile!.gym_id).single()
        setGymName(gym?.name ?? null)
      }

      const today = new Date().toISOString().slice(0, 10)

      const { data: workoutRow } = await supabase
        .from('workouts')
        .select('id, workout_date, status')
        .eq('gym_id', profile!.gym_id)
        .eq('workout_date', today)
        .maybeSingle()

      if (workoutRow) {
        const { data: blocks } = await supabase
          .from('blocks')
          .select('id, label, block_order, block_type')
          .eq('workout_id', workoutRow.id)
          .order('block_order')

        setWorkout({ ...workoutRow, blocks: blocks ?? [] })
      } else {
        setWorkout(null)
      }

      setLoading(false)
    }

    load()
  }, [profile])

  if (!profile) return null

  if (!profile.gym_id) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4">
        <p style={{ color: 'var(--color-ink-muted)' }}>
          Your account isn't assigned to a gym yet. Gym switching for admins is coming in a later sprint.
        </p>
      </div>
    )
  }

  const today = new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })

  return (
    <div className="min-h-screen px-4 py-8 max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <p className="text-sm" style={{ color: 'var(--color-ink-muted)' }}>{gymName ?? 'Your gym'}</p>
          <h1 className="text-2xl" style={{ fontFamily: 'var(--font-display)', color: 'var(--color-ink)' }}>{today}</h1>
        </div>
        <button
          onClick={signOut}
          className="text-sm px-3 py-1.5 rounded"
          style={{ border: '1px solid var(--color-panel-line)', color: 'var(--color-ink-muted)' }}
        >
          Sign out
        </button>
      </div>

      {loading ? (
        <p style={{ color: 'var(--color-ink-muted)' }}>Loading...</p>
      ) : workout ? (
        <div className="rounded-lg p-5" style={{ backgroundColor: 'var(--color-panel)', border: '1px solid var(--color-panel-line)' }}>
          <div className="flex items-center justify-between mb-4">
            <span
              className="text-xs uppercase tracking-wide px-2 py-1 rounded"
              style={{
                backgroundColor: workout.status === 'published' ? 'var(--color-connection)' : 'var(--color-panel-line)',
                color: workout.status === 'published' ? 'var(--color-graphite)' : 'var(--color-ink-muted)',
              }}
            >
              {workout.status}
            </span>
          </div>

          {workout.blocks.length === 0 ? (
            <p style={{ color: 'var(--color-ink-muted)' }}>No blocks yet — add-from-library is next.</p>
          ) : (
            <ul className="space-y-2">
              {workout.blocks.map((block) => (
                <li key={block.id} className="px-3 py-2 rounded" style={{ backgroundColor: 'var(--color-graphite)' }}>
                  <span style={{ color: 'var(--color-ink)' }}>{block.label}</span>
                  <span className="text-xs ml-2" style={{ color: 'var(--color-ink-muted)' }}>{block.block_type}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : (
        <div className="rounded-lg p-8 text-center" style={{ backgroundColor: 'var(--color-panel)', border: '1px dashed var(--color-panel-line)' }}>
          <p style={{ color: 'var(--color-ink-muted)' }}>No workout started for today yet. Creating a new workout comes next.</p>
        </div>
      )}
    </div>
  )
}
