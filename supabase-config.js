/* Oliv Films — configuração pública do Supabase.
   A Publishable key pode estar no frontend. Nunca coloque service_role/secret aqui. */
(() => {
  const SUPABASE_URL = 'https://nkhyqaehczeshqcqowom.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_gFzH0JyM36WEZsW_LFZ-9g_e_zQYE4g';

  if (!window.supabase?.createClient) {
    console.error('[Oliv Films] Biblioteca Supabase não foi carregada.');
    return;
  }

  window.olivSupabase = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    }
  );
  console.info('[Oliv Films] Cliente Supabase inicializado.');
})();
