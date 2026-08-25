-- CMB Projekt-Cockpit: Datenbank-Einrichtung
-- Einmalig im Supabase SQL-Editor ausführen (Projekt: content-pipeline).
-- Legt die Projekt-Tabelle an und sorgt dafür, dass jeder Nutzer
-- ausschließlich seine eigenen Daten sehen und bearbeiten kann.

create table if not exists public.cockpit_projects (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null,
  sub         text not null default '',
  status      text not null default 'aktiv',
  category    text not null default 'cmb',
  sort_order  integer not null default 0,
  data        jsonb not null default '{"todos":[],"notes":[],"docs":[],"transcripts":[]}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.cockpit_projects enable row level security;

drop policy if exists "cockpit_select_own" on public.cockpit_projects;
create policy "cockpit_select_own" on public.cockpit_projects
  for select using (auth.uid() = user_id);

drop policy if exists "cockpit_insert_own" on public.cockpit_projects;
create policy "cockpit_insert_own" on public.cockpit_projects
  for insert with check (auth.uid() = user_id);

drop policy if exists "cockpit_update_own" on public.cockpit_projects;
create policy "cockpit_update_own" on public.cockpit_projects
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cockpit_delete_own" on public.cockpit_projects;
create policy "cockpit_delete_own" on public.cockpit_projects
  for delete using (auth.uid() = user_id);

-- Nachrüstung für bestehende Installationen (harmlos, wenn schon vorhanden):
alter table public.cockpit_projects
  add column if not exists category text not null default 'cmb',
  add column if not exists sort_order integer not null default 0;
