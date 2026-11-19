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

## Etapa 2 — autenticação e sincronização

A branch agora contém a primeira integração no frontend:
- Login e sessão via Supabase Auth.
- Cadastro cria conta Auth e perfil pendente.
- Recuperação de senha solicita e-mail pelo Supabase.
- Perfil/role/status carregados do banco; usuários fictícios locais não são aceitos como login.
- Inventário, modelos, categorias, localizações, movimentações e configurações carregam/sincronizam nas tabelas Supabase.
- O localStorage continua como cópia local de segurança.

### SQL adicional obrigatório
Execute `supabase/migrations/002_profiles_and_permissions.sql` depois do schema inicial. Ele adiciona e-mail/departamento aos perfis e restringe exclusões a administradores/gerentes.

### Primeiro administrador
1. Cadastre sua conta real no app (ou em Authentication > Users).
2. Confirme o e-mail se a confirmação estiver habilitada.
3. Em Authentication > Users, copie o UUID.
4. No SQL Editor execute, substituindo o UUID:
   `update public.profiles set role='admin', status='approved' where id='SEU-UUID';`
5. Entre novamente no sistema.

### Importante — migração do inventário legado
A primeira autenticação carrega o banco como fonte principal. Não use o app com dados de produção antes de importar o inventário que está no navegador antigo. Faça primeiro a exportação/backup do localStorage; a importação assistida será a próxima etapa. O sistema mantém o backup local, mas não envia automaticamente dados antigos para evitar sobrescrever ou duplicar registros.
