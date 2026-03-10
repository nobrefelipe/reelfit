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
// URL utilities
// ---------------------------------------------------------------------------

function extractVideoId(url: string): string | null {
  const match = url.match(/youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/)
  return match ? match[1] : null
}

// ---------------------------------------------------------------------------
// Supadata transcript fetch
// ---------------------------------------------------------------------------

async function fetchTranscript(videoId: string): Promise<string> {
  const apiKey = Deno.env.get('SUPADATA_API_KEY')
  if (!apiKey) return ''

  try {
    const res = await fetch(
      `https://api.supadata.ai/v1/youtube/transcript?url=https://www.youtube.com/watch?v=${videoId}`,
      { headers: { 'x-api-key': apiKey } },
    )
    const json = await res.json()
    const content = json?.content
    if (!Array.isArray(content)) return ''
    return content.map((c: { text: string }) => c.text).join(' ')
  } catch (err) {
    console.error('[Supadata] fetchTranscript failed:', err)
    return ''
  }
}

// ---------------------------------------------------------------------------
// Groq / Llama 3.1 extraction
// ---------------------------------------------------------------------------

interface ExtractedWorkout {
  type: 'workout'
  data: {
    exercises: Record<string, unknown>[]
    suggested_plan: string | null
    target_muscle_groups: string[]
    difficulty: string | null
    equipment: string[]
  }
}

interface ExtractedDiet {
  type: 'diet'
  data: {
    title: string
    ingredients: { item: string; quantity: string | null }[]
    steps: string[]
    nutrition: Record<string, number> | null
    prep_time: string | null
    cook_time: string | null
    servings: number | null
  }
}

interface ExtractedUnknown {
  type: 'unknown'
  data: Record<string, unknown>
}

type Extracted = ExtractedWorkout | ExtractedDiet | ExtractedUnknown

async function extractWithGroq(transcript: string): Promise<Extracted> {
  const apiKey = Deno.env.get('GROQ_API_KEY')
  if (!apiKey) return { type: 'unknown', data: {} }

  const prompt = `You are a fitness and nutrition content analyzer. Analyze this YouTube Short transcript and extract structured data.

Determine if it is a WORKOUT video (exercises, training, fitness moves) or a DIET/RECIPE video (food, cooking, nutrition, meal prep).

Transcript:
${transcript.slice(0, 8000)}

Respond with ONLY valid JSON in one of these exact formats:

Workout:
{
  "type": "workout",
  "data": {
    "exercises": [
      {
        "name": "string",
        "sets": 3,
        "reps": 10,
        "duration": null,
        "rest": "60 seconds",
        "description": "How to perform the exercise",
        "target_muscle_group": "Chest",
        "notes": null,
        "timestamp_seconds": null
      }
    ],
    "suggested_plan": "string or null",
    "target_muscle_groups": ["Chest", "Triceps"],
    "difficulty": "Beginner | Intermediate | Advanced | null",
    "equipment": ["Dumbbells"]
  }
}

Diet/recipe:
{
  "type": "diet",
  "data": {
    "title": "Recipe name",
    "ingredients": [{ "item": "Chicken breast", "quantity": "200g" }],
    "steps": ["Step 1 ...", "Step 2 ..."],
    "nutrition": { "calories": 350, "protein": 30, "carbs": 20, "fat": 10 },
    "prep_time": "10 mins",
    "cook_time": "20 mins",
    "servings": 2
  }
}

Unknown:
{ "type": "unknown", "data": {} }

Rules:
- Use JSON null (never the string 'null') for truly unknown optional fields
- Cap exercises at 20 max, steps at 20 max
- Return ONLY the JSON object — no explanation, no markdown
- For exercises, always try to infer missing values:
  * sets: default to 3 if not mentioned, only null if clearly a one-off move
  * reps: infer from exercise type if not stated —
    strength moves (press, squat, deadlift, row, curl): 8-12
    bodyweight/endurance (push-up, lunge, sit-up, raise): 15-20
    isometric/timed (plank, wall sit, hold): set duration instead, null reps
  * description: write 1-2 sentences on how to perform it using any
    technique cues from the transcript — never use generic placeholder text,
    use null if no cues exist
  * notes: only real coaching cues from the transcript, null if none`

  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
      temperature: 0.1,
      max_tokens: 4096,
    }),
  })

  const groqData = await res.json()
  const content = groqData.choices?.[0]?.message?.content ?? '{}'

  try {
    return JSON.parse(content) as Extracted
  } catch {
    return { type: 'unknown', data: {} }
  }
}

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

async function linkUserVideo(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  videoUrl: string,
) {
  await supabase
    .from('user_videos')
    .upsert(
      { user_id: userId, video_url: videoUrl },
      { onConflict: 'user_id,video_url', ignoreDuplicates: true },
    )
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
    const { url } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 1. Validate URL
    const videoId = extractVideoId(url)
    if (!videoId) return error(400, 'Invalid YouTube Shorts URL')

    // 2. Attempt optional auth — no 401 if missing
    let userId: string | null = null
    const authHeader = req.headers.get('Authorization')
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '')
      const { data: { user } } = await supabase.auth.getUser(token)
      userId = user?.id ?? null
    }

    // 3. Cache check — return immediately if already processed
    const { data: cached } = await supabase
      .from('videos')
      .select('url, type, data, created_at')
      .eq('url', url)
      .maybeSingle()

    if (cached) {
      if (userId) await linkUserVideo(supabase, userId, url)
      return ok({ ...cached, cached: true })
    }

    // 4. Fetch transcript via Supadata
    const transcript = await fetchTranscript(videoId)
    console.log(`[extract] transcript length: ${transcript.trim().length}`)

    if (!transcript) return error(422, 'Could not extract transcript')

    // 5. Groq / Llama 3.1 extraction
    const extracted = await extractWithGroq(transcript)

    // 6. Enrich exercises with YouTube thumbnail
    if (extracted.type === 'workout' && Array.isArray(extracted.data.exercises)) {
      const thumb = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
      extracted.data.exercises = extracted.data.exercises.map((e) => ({
        ...e,
        image_url: thumb,
      }))
    }

    // 7. Save to videos table (always) — upsert guards against race conditions
    //    when two requests process the same URL simultaneously
    const { data: saved } = await supabase
      .from('videos')
      .upsert(
        { url, type: extracted.type, data: extracted.data },
        { onConflict: 'url', ignoreDuplicates: true },
      )
      .select('url, type, data, created_at')
      .single()

    // 8. Save to user_videos (only when authenticated)
    if (userId) await linkUserVideo(supabase, userId, url)

    // 9. Return result
    return ok({
      ...(saved ?? { url, type: extracted.type, data: extracted.data, created_at: new Date().toISOString() }),
      cached: false,
    })
  } catch (err) {
    console.error('extract pipeline error:', err)
    return error(500, 'Internal server error')
  }
})
