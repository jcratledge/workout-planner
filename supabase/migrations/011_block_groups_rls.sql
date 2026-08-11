-- NOT YET APPLIED to the live database — review before running.
-- block_groups currently has RLS disabled, meaning the anon key can
-- read/write every row. This mirrors the pattern already used for
-- blocks/block_exercises: access flows through the parent block's
-- workout -> gym_id.

alter table block_groups enable row level security;

create policy "block_groups_select" on block_groups
  for select using (
    is_admin() or block_id in (
      select b.id from blocks b
      join workouts w on w.id = b.workout_id
      where w.gym_id = my_gym_id()
    )
  );

create policy "block_groups_write" on block_groups
  for all using (
    is_admin() or block_id in (
      select b.id from blocks b
      join workouts w on w.id = b.workout_id
      where w.gym_id = my_gym_id()
    )
  );
