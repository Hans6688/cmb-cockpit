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
  priority    text not null default 'mittel',
  due_date    date,
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
  add column if not exists sort_order integer not null default 0,
  add column if not exists priority text not null default 'mittel',
  add column if not exists due_date date;

-- Tagesroutinen & Ziele (eine Zeile pro Nutzer)
create table if not exists public.cockpit_extras (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null unique default auth.uid() references auth.users(id) on delete cascade,
  routines    jsonb not null default '[]'::jsonb,
  goals       jsonb not null default '[]'::jsonb,
  routine_imgs jsonb not null default '[]'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.cockpit_extras
  add column if not exists routine_imgs jsonb not null default '[]'::jsonb,
  add column if not exists money_log jsonb not null default '[]'::jsonb,
  add column if not exists header_items jsonb not null default '[]'::jsonb;

alter table public.cockpit_extras enable row level security;

drop policy if exists "extras_select_own" on public.cockpit_extras;
create policy "extras_select_own" on public.cockpit_extras
  for select using (auth.uid() = user_id);

drop policy if exists "extras_insert_own" on public.cockpit_extras;
create policy "extras_insert_own" on public.cockpit_extras
  for insert with check (auth.uid() = user_id);

drop policy if exists "extras_update_own" on public.cockpit_extras;
create policy "extras_update_own" on public.cockpit_extras
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "extras_delete_own" on public.cockpit_extras;
create policy "extras_delete_own" on public.cockpit_extras
  for delete using (auth.uid() = user_id);

-- Eingang: schnelle Notizen per Apple-Kurzbefehl
create table if not exists public.cockpit_inbox (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  content     text not null,
  created_at  timestamptz not null default now()
);

alter table public.cockpit_inbox enable row level security;

drop policy if exists "inbox_select_own" on public.cockpit_inbox;
create policy "inbox_select_own" on public.cockpit_inbox
  for select using (auth.uid() = user_id);

drop policy if exists "inbox_insert_own" on public.cockpit_inbox;
create policy "inbox_insert_own" on public.cockpit_inbox
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "inbox_update_own" on public.cockpit_inbox;
create policy "inbox_update_own" on public.cockpit_inbox
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "inbox_delete_own" on public.cockpit_inbox;
create policy "inbox_delete_own" on public.cockpit_inbox
  for delete using (auth.uid() = user_id);

-- Einwurf-Funktion für den Kurzbefehl. WICHTIG: Der echte Geheimcode wird nur
-- direkt in Supabase eingesetzt und gehört NICHT in dieses (öffentliche) Repository.
create or replace function public.cockpit_add_note(secret text, note text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid;
begin
  if secret is distinct from 'HIER-GEHEIMCODE-EINSETZEN' then
    raise exception 'not allowed';
  end if;
  if note is null or length(trim(note)) = 0 then
    raise exception 'empty note';
  end if;
  select id into uid from auth.users where email = 'HIER-DEINE-EMAIL' limit 1;
  if uid is null then
    raise exception 'user not found';
  end if;
  insert into public.cockpit_inbox (user_id, content) values (uid, left(trim(note), 4000));
end;
$$;

revoke all on function public.cockpit_add_note(text, text) from public;
grant execute on function public.cockpit_add_note(text, text) to anon;
