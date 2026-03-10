import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ---------------------------------------------------------------------------
// CORS — required for browser requests from the Flutter web app
// ---------------------------------------------------------------------------

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, timezone_name, timezone_offset, accept',
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
    // Auth required — return 401 if no valid JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return error(401, 'Missing authorization header')

    const token = authHeader.replace('Bearer ', '')

    // Use anon key + user token for auth verification
    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: `Bearer ${token}` } } },
    )

    const { data: { user } } = await supabaseAuth.auth.getUser()
    if (!user) return error(401, 'Invalid or expired token')

    // Use service role for DB operations
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const userId = user.id
    const url = new URL(req.url)

    // POST /history/link — insert a user_videos row (used for guest migration)
    if (req.method === 'POST' && url.pathname.endsWith('/link')) {
      const { url: videoUrl } = await req.json()
      if (!videoUrl) return error(400, 'Missing url')

      const { error: dbError } = await supabase
        .from('user_videos')
        .upsert(
          { user_id: userId, video_url: videoUrl },
          { onConflict: 'user_id,video_url', ignoreDuplicates: true },
        )

      if (dbError) {
        console.error('[history/link] db error:', dbError)
        return error(500, 'Failed to link video')
      }

      return ok({ linked: true })
    }

    // GET — query user_videos joined with videos, ordered by saved_at DESC, limit 50
    if (req.method === 'GET') {
      const { data: rows, error: dbError } = await supabase
        .from('user_videos')
        .select('saved_at, videos(url, type, data, created_at)')
        .eq('user_id', userId)
        .order('saved_at', { ascending: false })
        .limit(50)

      if (dbError) {
        console.error('[history] db error:', dbError)
        return error(500, 'Failed to fetch history')
      }

      // Flatten join: return array of video rows with saved_at included
      const videos = (rows ?? []).map((row) => ({
        ...(row.videos as Record<string, unknown>),
        saved_at: row.saved_at,
      }))

      return ok(videos)
    }

    return error(405, 'Method not allowed')
  } catch (err) {
    console.error('history pipeline error:', err)
    return error(500, 'Internal server error')
  }
})
