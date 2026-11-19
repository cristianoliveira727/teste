-- Oliv Films — ajuste dos perfis e permissões administrativas
-- Execute após supabase/schema.sql.

alter table public.profiles
  add column if not exists email text,
  add column if not exists department text;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, department, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'department', 'Equipe Externa'),
    'employee',
    'pending'
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name,
    department = excluded.department;
  return new;
end;
$$;

-- Atualiza e-mails dos perfis existentes a partir do Auth (executado pelo SQL Editor).
update public.profiles p
set email = u.email
from auth.users u
where u.id = p.id and p.email is distinct from u.email;

-- A função administrativa nunca confia em user_metadata; a role vem da tabela protegida.
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

-- Funcionários aprovados não podem excluir registros. Exclusões são administrativas.
do $$
declare t text;
begin
  foreach t in array array['equipment','equipment_models','categories','locations','movements','company_settings']
  loop
    execute format('drop policy if exists "approved_delete" on public.%I', t);
    execute format('drop policy if exists "manager_delete" on public.%I', t);
    execute format(
      'create policy "manager_delete" on public.%I for delete to authenticated using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = ''approved'' and p.role in (''admin'',''manager'')))',
      t
    );
  end loop;
end $$;


-- Restringe cadastros estruturais e configurações a administradores/gerentes.
create or replace function public.can_manage_inventory()
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
      and p.role in ('admin','manager')
  );
$$;

do $$
declare t text;
begin
  foreach t in array array['equipment_models','categories','locations','company_settings']
  loop
    execute format('drop policy if exists "approved_insert" on public.%I', t);
    execute format('drop policy if exists "manager_insert" on public.%I', t);
    execute format('create policy "manager_insert" on public.%I for insert to authenticated with check (public.can_manage_inventory())', t);

    execute format('drop policy if exists "approved_update" on public.%I', t);
    execute format('drop policy if exists "manager_update" on public.%I', t);
    execute format('create policy "manager_update" on public.%I for update to authenticated using (public.can_manage_inventory()) with check (public.can_manage_inventory())', t);
  end loop;

  execute 'drop policy if exists "approved_insert" on public.equipment';
  execute 'drop policy if exists "manager_insert" on public.equipment';
  execute 'create policy "manager_insert" on public.equipment for insert to authenticated with check (public.can_manage_inventory())';
end $$;
