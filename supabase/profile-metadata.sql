-- Oliv Films — complementação do perfil para integração da interface
-- Execute após schema.sql. Seguro para execução repetida.

alter table public.profiles
  add column if not exists email text,
  add column if not exists department text;

update public.profiles p
set email = u.email,
    full_name = coalesce(nullif(p.full_name, ''), u.raw_user_meta_data ->> 'full_name', ''),
    department = coalesce(p.department, u.raw_user_meta_data ->> 'department')
from auth.users u
where u.id = p.id
  and (p.email is distinct from u.email or p.department is null);

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
    new.raw_user_meta_data ->> 'department',
    'employee',
    'pending'
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name),
        department = coalesce(public.profiles.department, excluded.department);
  return new;
end;
$$;

-- A função de trigger não deve ser invocada diretamente pelo navegador.
revoke all on function public.handle_new_user() from public, anon, authenticated;
