-- Oliv Films — consulta pública e restrita para QR Code de Achados e Perdidos
-- Execute no SQL Editor do Supabase uma única vez.

create or replace function public.lookup_equipment_for_found_item(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', e.data ->> 'id',
    'code', e.data ->> 'code',
    'name', e.data ->> 'name',
    'serialNumber', e.data ->> 'serialNumber',
    'photos', coalesce(e.data -> 'photos', '[]'::jsonb)
  )
  from public.equipment e
  where upper(coalesce(e.data ->> 'code', '')) = upper(trim(p_code))
  limit 1;
$$;

revoke all on function public.lookup_equipment_for_found_item(text) from public;
grant execute on function public.lookup_equipment_for_found_item(text) to anon, authenticated;
