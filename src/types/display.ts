// Mirrors the columns returned by the `get_display_workout(token)` Postgres
// function defined in 003_live_session.sql. One row per exercise; blocks and
// the workout itself repeat across their exercise rows (a denormalized join),
// so we reshape this into nested objects in `groupDisplayRows`.

export type BlockType =
  | 'warmup'
  | 'straight_sets'
  | 'circuit'
  | 'pyramid'
  | 'emom'
  | 'amrap'
  | 'interval'

export type SessionStatus = 'not_started' | 'in_progress' | 'complete'

export interface DisplayRow {
  workout_id: string
  workout_date: string
  gym_name: string
  session_status: SessionStatus
  current_block_id: string | null
  current_block_started_at: string | null

  block_id: string
  block_label: string
  block_order: number
  block_type: BlockType
  rounds: number | null
  time_cap_seconds: number | null
  work_seconds: number | null
  rest_seconds: number | null
  block_notes: string | null
  display_message: string | null

  exercise_id: string | null
  exercise_name: string | null
  freetext_name: string | null
  exercise_order: number | null
  sets: number | null
  reps: string | null
  reps_right: string | null
  reps_left: string | null
  tempo: string | null
  ex_rest_seconds: number | null
  ex_notes: string | null
}

export interface DisplayExercise {
  id: string
  name: string
  order: number
  sets: number | null
  reps: string | null
  repsRight: string | null
  repsLeft: string | null
  tempo: string | null
  restSeconds: number | null
  notes: string | null
}

export interface DisplayBlock {
  id: string
  label: string
  order: number
  type: BlockType
  rounds: number | null
  timeCapSeconds: number | null
  workSeconds: number | null
  restSeconds: number | null
  notes: string | null
  displayMessage: string | null
  exercises: DisplayExercise[]
}

export interface DisplayWorkout {
  id: string
  date: string
  gymName: string
  sessionStatus: SessionStatus
  currentBlockId: string | null
  currentBlockStartedAt: string | null
  blocks: DisplayBlock[]
}

/** Reshapes the flat RPC rows into a nested workout -> blocks -> exercises tree. */
export function groupDisplayRows(rows: DisplayRow[]): DisplayWorkout | null {
  if (rows.length === 0) return null

  const first = rows[0]
  const blockMap = new Map<string, DisplayBlock>()

  for (const row of rows) {
    let block = blockMap.get(row.block_id)
    if (!block) {
      block = {
        id: row.block_id,
        label: row.block_label,
        order: row.block_order,
        type: row.block_type,
        rounds: row.rounds,
        timeCapSeconds: row.time_cap_seconds,
        workSeconds: row.work_seconds,
        restSeconds: row.rest_seconds,
        notes: row.block_notes,
        displayMessage: row.display_message,
        exercises: [],
      }
      blockMap.set(row.block_id, block)
    }

    if (row.exercise_order !== null) {
      block.exercises.push({
        id: row.exercise_id ?? `freetext-${row.block_id}-${row.exercise_order}`,
        name: row.exercise_name ?? row.freetext_name ?? 'Unnamed exercise',
        order: row.exercise_order,
        sets: row.sets,
        reps: row.reps,
        repsRight: row.reps_right,
        repsLeft: row.reps_left,
        tempo: row.tempo,
        restSeconds: row.ex_rest_seconds,
        notes: row.ex_notes,
      })
    }
  }

  const blocks = Array.from(blockMap.values())
    .map((b) => ({ ...b, exercises: b.exercises.sort((a, c) => a.order - c.order) }))
    .sort((a, b) => a.order - b.order)

  return {
    id: first.workout_id,
    date: first.workout_date,
    gymName: first.gym_name,
    sessionStatus: first.session_status,
    currentBlockId: first.current_block_id,
    currentBlockStartedAt: first.current_block_started_at,
    blocks,
  }
}
