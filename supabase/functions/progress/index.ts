import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ---------------------------------------------------------------------------
// CORS — required for browser requests from the Flutter web app
// ---------------------------------------------------------------------------

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ---------------------------------------------------------------------------
// Response helpers — wrapped in { data: ... } per ResponseInterceptor contract
// ---------------------------------------------------------------------------

function ok(payload: unknown) {
  return new Response(JSON.stringify({ data: payload }), {
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

function error(status: number, message: string) {
  return new Response(JSON.stringify({ message }), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  // Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Auth required — return 401 if no valid JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return error(401, 'Missing authorization header')

    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabase.auth.getUser(token)
    if (!user) return error(401, 'Invalid or expired token')

    const userId = user.id

    // GET ?exercise={name} — query progress for this user + exercise, ordered by logged_at ASC
    if (req.method === 'GET') {
      const url = new URL(req.url)
      const exerciseName = url.searchParams.get('exercise')
      if (!exerciseName) return error(400, 'Missing exercise query parameter')

      const { data: rows, error: dbError } = await supabase
        .from('progress')
        .select('id, exercise_name, value, unit, logged_at')
        .eq('user_id', userId)
        .eq('exercise_name', exerciseName)
        .order('logged_at', { ascending: true })

      if (dbError) {
        console.error('[progress] GET db error:', dbError)
        return error(500, 'Failed to fetch progress')
      }

      return ok(rows ?? [])
    }

    // POST — insert a new progress row, return the created row
    if (req.method === 'POST') {
      const { exercise_name, value, unit } = await req.json()

      if (!exercise_name) return error(400, 'Missing exercise_name')
      if (value === undefined || value === null) return error(400, 'Missing value')
      if (!unit) return error(400, 'Missing unit')

      const { data: row, error: dbError } = await supabase
        .from('progress')
        .insert({ user_id: userId, exercise_name, value, unit })
        .select('id, exercise_name, value, unit, logged_at')
        .single()

      if (dbError) {
        console.error('[progress] POST db error:', dbError)
        return error(500, 'Failed to log progress')
      }

      return ok(row)
    }

    return error(405, 'Method not allowed')
  } catch (err) {
    console.error('progress pipeline error:', err)
    return error(500, 'Internal server error')
  }
})
