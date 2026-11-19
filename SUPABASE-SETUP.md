# Integração Supabase — Oliv Films

Esta branch contém a base inicial da integração, sem substituir ainda o mecanismo de login ou a persistência do sistema.

## Arquivos
- `supabase/schema.sql`: tabelas, trigger de perfil e políticas RLS iniciais.
- `supabase-config.js`: inicializador do cliente Supabase com a URL e a Publishable key do projeto.

## Configuração manual necessária
1. No painel Supabase, abra SQL Editor.
2. Execute o conteúdo de `supabase/schema.sql`.
3. Cadastre a conta administradora em Authentication > Users (ou pelo fluxo de cadastro do app, depois da integração de Auth).
4. Copie o UUID da conta e execute o UPDATE comentado no final do SQL, definindo role=admin e status=approved.

Novos cadastros recebem status `pending`; não terão acesso aos dados operacionais até aprovação.

## Atenção
- A chave Publishable é própria para frontend; nunca usar `service_role` ou secret key no navegador.
- As políticas RLS desta primeira etapa garantem que apenas usuários aprovados acessem dados. As regras finas por papel (admin/gerente/funcionário) devem ser ajustadas junto com a migração das ações da interface.
- O sistema ainda usa localStorage até a camada de dados ser migrada e testada. Não apague os dados locais nem desative o login atual nesta etapa.
- Os objetos JSON preservam os campos do modelo legado durante a migração, mas a integração CRUD ainda não está ativa.
