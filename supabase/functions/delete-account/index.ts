// supabase/functions/delete-account/index.ts
//
// NOT deployed automatically by anything in this repo. This is Deno/
// TypeScript code that runs on Supabase's Edge Function infrastructure,
// separate entirely from the Flutter app. Deploy it yourself with:
//
//   supabase functions deploy delete-account
//
// Why this can't be done directly from the Flutter app: deleting an
// auth.users row requires the Supabase service_role key, which has full
// admin privileges and must NEVER be embedded in a client app (anyone
// could extract it from the compiled app and delete arbitrary accounts).
// The service_role key lives only here, server-side, as an Edge Function
// secret — never in supabase_service.dart or anywhere in lib/.
//
// The Flutter side (account_screen.dart) just calls:
//   supabase.functions.invoke('delete-account')
// which hits this function using the CALLING USER'S OWN auth token,
// so the function below deletes the calling user's own account only.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Client the function uses to identify WHO is calling (their own
    // token, not the service key) — this is how we know which account
    // to delete without trusting a user-supplied id.
    const authClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )
    const { data: { user }, error: userError } = await authClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), { status: 401 })
    }

    // Admin client, service_role key — only usable server-side, only
    // reachable from within this deployed function.
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Deleting auth.users cascades to family_members, medicines,
    // medicine_schedule, medicine_history, and prescriptions via the
    // `on delete cascade` foreign keys already set up in the SQL
    // migrations (002–005) — no manual per-table cleanup needed here.
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), { status: 500 })
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
