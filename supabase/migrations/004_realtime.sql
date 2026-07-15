-- =========================================================
-- Enable Realtime broadcast on the tables the TV display
-- and the trainer's "live session" controls depend on.
-- Run after 001-003. Safe to re-run if already applied.
-- =========================================================

do $$
begin
  alter publication supabase_realtime add table workouts;
exception when duplicate_object then
  null; -- already added, nothing to do
end $$;

do $$
begin
  alter publication supabase_realtime add table blocks;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter publication supabase_realtime add table block_exercises;
exception when duplicate_object then
  null;
end $$;
