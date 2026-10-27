-- Gather MVP database. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  slug text not null unique,
  title text not null check (length(trim(title)) between 1 and 120),
  event_date timestamptz not null,
  location text not null check (length(trim(location)) between 1 and 200),
  description text not null default '' check (length(description) <= 1000),
  theme text not null default 'sage' check (theme in ('sage','rose','lavender','blue')),
  created_at timestamptz not null default now()
);
create index if not exists events_host_idx on public.events(host_id);

create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  guest_name text not null check (length(trim(guest_name)) between 1 and 100),
  email text check (email is null or length(email) <= 200),
  status text not null check (status in ('yes','no','maybe')),
  party_size integer not null default 1 check (party_size between 1 and 20),
  note text check (note is null or length(note) <= 500),
  created_at timestamptz not null default now()
);
create index if not exists rsvps_event_idx on public.rsvps(event_id);

alter table public.events enable row level security;
alter table public.rsvps enable row level security;

create policy "Hosts read own events" on public.events for select to authenticated using (host_id = (select auth.uid()));
create policy "Hosts create own events" on public.events for insert to authenticated with check (host_id = (select auth.uid()));
create policy "Hosts update own events" on public.events for update to authenticated using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));
create policy "Hosts delete own events" on public.events for delete to authenticated using (host_id = (select auth.uid()));
create policy "Hosts read own RSVPs" on public.rsvps for select to authenticated using (exists (select 1 from public.events e where e.id = event_id and e.host_id = (select auth.uid())));

-- Only public-safe event details are returned, never host ID or guest data.
create or replace function public.get_public_event(p_slug text)
returns table (id uuid, slug text, title text, event_date timestamptz, location text, description text, theme text)
language sql stable security definer set search_path = ''
as $$
  select e.id, e.slug, e.title, e.event_date, e.location, e.description, e.theme
  from public.events e where e.slug = p_slug limit 1;
$$;

-- Guests cannot write directly to RSVP table; only through validated RPC.
create or replace function public.submit_rsvp(p_slug text, p_name text, p_email text, p_status text, p_party_size integer, p_note text)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_event_id uuid;
begin
  if p_name is null or length(trim(p_name)) not between 1 and 100 then raise exception 'Please enter a name (up to 100 characters)'; end if;
  if p_status is null or p_status not in ('yes','no','maybe') then raise exception 'Invalid response'; end if;
  if p_party_size is null or p_party_size not between 1 and 20 then raise exception 'Party size must be between 1 and 20'; end if;
  if p_email is not null and (length(p_email) > 200 or p_email !~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then raise exception 'Please enter a valid email'; end if;
  if p_note is not null and length(p_note) > 500 then raise exception 'Message is too long'; end if;
  select e.id into v_event_id from public.events e where e.slug = p_slug;
  if v_event_id is null then raise exception 'This invitation was not found'; end if;
  insert into public.rsvps (event_id, guest_name, email, status, party_size, note)
  values (v_event_id, trim(p_name), nullif(trim(p_email),''), p_status, case when p_status = 'yes' then p_party_size else 1 end, nullif(trim(p_note),''));
end;
$$;

revoke all on function public.get_public_event(text) from public;
revoke all on function public.submit_rsvp(text,text,text,text,integer,text) from public;
grant execute on function public.get_public_event(text) to anon, authenticated;
grant execute on function public.submit_rsvp(text,text,text,text,integer,text) to anon, authenticated;

-- Before public launch: add per-IP rate limiting, bot protection/CAPTCHA,
-- email verification for guest responses, and moderation for abusive content.
