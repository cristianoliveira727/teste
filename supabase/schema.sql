-- Oliv Films — estrutura inicial do banco Supabase
-- Execute este arquivo no SQL Editor do projeto.
-- Não armazene senhas neste banco: a autenticação é feita pelo Supabase Auth.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'employee' check (role in ('admin','manager','employee')),
  status text not null default 'pending' check (status in ('pending','approved','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'employee',
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.is_approved_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.status = 'approved'
  );
$$;

create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'approved'
      and p.role = 'admin'
  );
$$;

-- Registros mantêm os IDs e os objetos JSON do sistema atual, facilitando
-- a migração sem descartar campos ainda não mapeados.
create table if not exists public.equipment (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.equipment_models (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.locations (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.movements (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.company_settings (
  id text primary key default 'default',
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint company_settings_singleton check (id = 'default')
);

alter table public.profiles enable row level security;
alter table public.equipment enable row level security;
alter table public.equipment_models enable row level security;
alter table public.categories enable row level security;
alter table public.locations enable row level security;
alter table public.movements enable row level security;
alter table public.company_settings enable row level security;

-- Perfil: usuário lê o próprio perfil; administradores aprovados gerenciam todos.
drop policy if exists "profile_read_self_or_admin" on public.profiles;
create policy "profile_read_self_or_admin" on public.profiles
for select to authenticated
using (id = (select auth.uid()) or public.is_admin_user());

drop policy if exists "profile_admin_update" on public.profiles;
create policy "profile_admin_update" on public.profiles
for update to authenticated
using (public.is_admin_user())
with check (public.is_admin_user());

-- Todos os dados operacionais só ficam acessíveis a usuários aprovados.
do $$
declare
  t text;
begin
  foreach t in array array['equipment','equipment_models','categories','locations','movements','company_settings']
  loop
    execute format('drop policy if exists "approved_read" on public.%I', t);
    execute format('create policy "approved_read" on public.%I for select to authenticated using (public.is_approved_user())', t);

    execute format('drop policy if exists "approved_insert" on public.%I', t);
    execute format('create policy "approved_insert" on public.%I for insert to authenticated with check (public.is_approved_user())', t);

    execute format('drop policy if exists "approved_update" on public.%I', t);
    execute format('create policy "approved_update" on public.%I for update to authenticated using (public.is_approved_user()) with check (public.is_approved_user())', t);

    execute format('drop policy if exists "approved_delete" on public.%I', t);
    execute format('create policy "approved_delete" on public.%I for delete to authenticated using (public.is_approved_user())', t);
  end loop;
end $$;

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.equipment, public.equipment_models, public.categories,
  public.locations, public.movements, public.company_settings
to authenticated;
grant select, update on public.profiles to authenticated;

-- IMPORTANTE: após cadastrar sua conta pelo Auth, promova-a a administradora
-- manualmente no SQL Editor, substituindo pelo UUID correto:
-- update public.profiles set role = 'admin', status = 'approved'
-- where id = 'UUID-DA-SUA-CONTA';
