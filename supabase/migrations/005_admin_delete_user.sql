-- Oliv Films — exclusão administrativa de usuários
-- Remove a conta do Supabase Auth; o perfil é removido pela FK ON DELETE CASCADE.

create or replace function public.admin_delete_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := auth.uid();
  v_target_role text;
begin
  if v_caller_id is null then
    raise exception 'Autenticação necessária.';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = v_caller_id
      and p.status = 'approved'
      and p.role = 'admin'
  ) then
    raise exception 'Apenas um administrador aprovado pode excluir usuários.';
  end if;

  if p_user_id is null or p_user_id = v_caller_id then
    raise exception 'Não é permitido excluir a própria conta.';
  end if;

  select p.role into v_target_role
  from public.profiles p
  where p.id = p_user_id;

  if v_target_role is null then
    raise exception 'Usuário não encontrado.';
  end if;

  if v_target_role = 'admin' then
    raise exception 'Contas administrativas são protegidas contra exclusão por esta função.';
  end if;

  delete from auth.users
  where id = p_user_id;

  if not found then
    raise exception 'Conta de autenticação não encontrada.';
  end if;
end;
$$;

revoke all on function public.admin_delete_user(uuid) from public;
grant execute on function public.admin_delete_user(uuid) to authenticated;
