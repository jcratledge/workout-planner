-- Adds sub-round / partner-track grouping within a block, and a
-- video reference on library exercises. A block can now contain
-- multiple ordered "groups" (e.g. P1/P2 partner tracks, or several
-- sub-rounds), each with its own round count and optional track label.
-- Existing block_exercises are backfilled into a single group per
-- block so nothing already published breaks.
-- Run after 001-007.

create table block_groups (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references blocks(id) on delete cascade,
  group_order int not null,
  rounds int,               -- round count for this specific group/track
  track_label text,         -- e.g. 'P1', 'P2', 'Group A'
  notes text
);

create index idx_block_groups_block on block_groups (block_id, group_order);

alter table exercises add column video_url text;

alter table block_exercises add column group_id uuid references block_groups(id);

-- Backfill: one group per existing block, carrying over that block's
-- round count, with every existing exercise assigned to it.
do $$
declare
  r record;
  v_group_id uuid;
begin
  for r in select id, rounds from blocks loop
    insert into block_groups (block_id, group_order, rounds)
    values (r.id, 1, r.rounds)
    returning id into v_group_id;

    update block_exercises
    set group_id = v_group_id
    where block_id = r.id;
  end loop;
end $$;

alter table block_exercises alter column group_id set not null;

create index idx_block_exercises_group on block_exercises (group_id, exercise_order);

-- NOTE: block_groups does not yet have Row Level Security enabled.
-- This matches current production state — see 011_block_groups_rls.sql
-- (not yet applied) before this table is queried from anywhere
-- other than the security-definer display functions.
