-- OLIV FILMS — limpeza dos dados fictícios de demonstração
-- Execute no SQL Editor do Supabase após confirmar que deseja iniciar o inventário vazio.
-- Esta limpeza NÃO remove usuários, perfis, permissões, tabelas ou funções.
-- Preserva integralmente sua conta administradora em public.profiles.

begin;

truncate table
  public.equipment,
  public.equipment_models,
  public.categories,
  public.locations,
  public.movements,
  public.company_settings;

commit;

-- Conferência: todas as contagens abaixo devem retornar zero.
select 'equipment' as tabela, count(*) as registros from public.equipment
union all select 'equipment_models', count(*) from public.equipment_models
union all select 'categories', count(*) from public.categories
union all select 'locations', count(*) from public.locations
union all select 'movements', count(*) from public.movements
union all select 'company_settings', count(*) from public.company_settings;

-- O perfil administrador é preservado. Confira seu usuário:
select id, email, full_name, role, status
from public.profiles
where role = 'admin';
