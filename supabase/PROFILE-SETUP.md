# Complemento do perfil Supabase

Execute `supabase/profile-metadata.sql` no SQL Editor depois de `schema.sql`.

Esse complemento adiciona e preenche email/departamento em profiles e atualiza o trigger de novos cadastros. A aplicação usa esses campos para listar os membros da equipe sem consultar a tabela interna auth.users.

Depois, crie a conta administradora em Authentication > Users (Add user). Use o seu e-mail de administrador e uma senha forte. Copie o UUID exibido para a conta; ele será necessário para promover o perfil a admin aprovado com um comando SQL específico.
