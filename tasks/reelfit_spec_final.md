# ReelFit — Product & Engineering Specification
**Version:** 3.0  
**Date:** March 2026  
**Status:** Active  

---

## Table of Contents
1. [Product Overview](#1-product-overview)
2. [Goals & Success Criteria](#2-goals--success-criteria)
3. [System Architecture](#3-system-architecture)
4. [User Flows](#4-user-flows)
5. [Screen Map](#5-screen-map)
6. [Feature Descriptions](#6-feature-descriptions)
7. [Out of Scope (v1)](#7-out-of-scope-v1)
8. [Database Schema](#8-database-schema)
9. [Supabase Edge Functions](#9-supabase-edge-functions)
10. [Flutter App Structure](#10-flutter-app-structure)
11. [Models](#11-models)
12. [Services](#12-services)
13. [Controllers](#13-controllers)
14. [Routing](#14-routing)
15. [Auth Integration](#15-auth-integration)
16. [Environment Variables](#16-environment-variables)
17. [Build Roadmap](#17-build-roadmap)
18. [Key Technical Decisions](#18-key-technical-decisions)
19. [Known Risks & Mitigations](#19-known-risks--mitigations)

---

## 1. Product Overview

ReelFit is a web application that extracts structured fitness and diet data from YouTube Shorts. Users paste a short video URL, and ReelFit returns a clean, actionable breakdown — exercises with sets/reps/descriptions, recipes with ingredients and macros, and a personal progress tracker tied to each exercise.

The product solves a real friction point: fitness and recipe content on short-form video is rich but unstructured. Watching a 60-second workout Short gives you the moves, but you can't save it, reference it later, or track your performance against it. ReelFit turns passive content consumption into an active, trackable fitness record.

### Core Value Proposition
- **Zero friction** — paste a URL, get structured data in seconds. No account required to try it.
- **Shared cache** — each video is processed once for all users, making repeat lookups instant
- **Progress tracking** — log your weight/reps per exercise and watch your chart grow over time
- **Clean UI** — dark, fitness-forward design that feels native to the content

### Target User
Someone who follows fitness creators on YouTube Shorts and wants to actually use the workouts — not just watch them. They copy URLs from the YouTube app and want a structured reference they can bring to the gym.

### Guest vs Authenticated
The app is not behind an auth wall. Anyone can extract and view up to 3 videos without an account — results are saved to local storage on their device. Signing in with Google unlocks unlimited history saved to the cloud, cross-device access, and progress tracking. The limit and the benefits are surfaced clearly in the UI so users understand what they get by signing up.

---

## 2. Goals & Success Criteria

### v1 Goals
- **Any user** (guest or authenticated) can paste a YouTube Shorts URL and receive structured workout or diet data
- **Guest users** can extract up to 3 videos — results saved to local storage on their device
- **Authenticated users** get unlimited history saved to the cloud, synced across devices
- A signed-in user can log progress (weight, reps) on any exercise and see it on a chart
- The app works on web (desktop + mobile browser)
- Zero infrastructure to manage — fully serverless
- The value of signing up is always visible but never forced

### Success Metrics (qualitative for v1)
- Extraction works reliably on fitness and recipe Shorts with captions
- AssemblyAI fallback handles Shorts without auto-captions
- Page loads fast — cached results return in < 500ms
- The UI feels polished enough to share with people

---

## 3. System Architecture

### Overview

```
┌─────────────────────────────────────────┐
│         Flutter Web App                 │
│   (Firebase Hosting / Vercel)           │
│                                         │
│  View → Controller → Service → API      │
│              ↓                          │
│         atom.emit(result)               │
│              ↓                          │
│         View rebuilds via atom()        │
└──────────────┬──────────────────────────┘
               │ HTTP (Bearer JWT)
               ▼
┌─────────────────────────────────────────┐
│              Supabase                   │
│                                         │
│  ┌──────────────┐  ┌─────────────────┐  │
│  │  Auth        │  │  PostgreSQL DB  │  │
│  │  Google SSO  │  │  videos         │  │
│  │  JWT tokens  │  │  user_videos    │  │
│  └──────────────┘  │  progress       │  │
│                    └─────────────────┘  │
│  ┌──────────────────────────────────┐   │
│  │  Edge Functions (Deno/TypeScript)│   │
│  │  /extract  /history  /progress  │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│           External APIs                  │
│  youtube-caption-extractor (npm)         │
│  AssemblyAI  (audio transcription)       │
│  Groq / Llama 3.1  (JSON extraction)    │
│  i.ytimg.com  (YouTube thumbnails)       │
└──────────────────────────────────────────┘
```

### Why This Stack

| Choice | Reason |
|--------|--------|
| **Supabase** | Replaces Dart Frog backend entirely — DB, auth, storage, and serverless functions in one platform. Free tier is generous. Zero servers to manage. |
| **Edge Functions (Deno)** | Run the yt-dlp-free pipeline serverlessly. `youtube-caption-extractor` npm package works natively in Deno with no binaries. |
| **Flutter Web** | Reuses all existing components — `core/`, `UIKButton`, `AsyncAtom`, `DesignTokens`. Single codebase. |
| **`APIRequest` for all HTTP** | Supabase SDK is used only for auth (SSO + session). All data calls go through the existing `APIRequest` base class — zero changes to `core/`. |
| **YouTube thumbnails** | `i.ytimg.com/vi/{id}/hqdefault.jpg` — free, permanent, no API key, no CORS. Replaces the ffmpeg screenshot approach from the POC. |

---

## 4. User Flows

### 4.1 Guest — First Extract
```
User visits app (no account)
  → Home screen loads immediately — no login wall
  → User pastes YouTube Shorts URL
  → Taps "Extract"
  → extractController.extract(url) called (no auth token)
  → Edge Function processes without user linkage
  → Result returned and displayed normally
  → VideoModel saved to local storage (AppCache)
  → Guest video count incremented (1/3)
```

### 4.2 Guest — Hits the 3 Video Limit
```
User tries to extract a 4th video
  → extractController checks guest count before calling API
  → Count == 3 → extraction blocked
  → Upsell bottom sheet shown:
      "You've used your 3 free extracts.
       Sign in with Google to save unlimited workouts
       and track your progress."
      [Continue with Google]  [Maybe later]
  → "Maybe later" dismisses sheet — user can still browse their 3 saved videos
  → "Continue with Google" → sign in flow → on success, local videos migrated to DB
```

### 4.3 Guest — Tries to Log Progress
```
ExerciseDetailScreen
  → User taps "+" to log a progress entry
  → progressController checks auth state
  → Not authenticated → upsell bottom sheet:
      "Sign in to track your progress over time."
      [Continue with Google]  [Not now]
```

### 4.4 Sign In (from any upsell or menu)
```
  → Google OAuth popup
  → Supabase stores session → JWT issued
  → Token saved to AppCache
  → Local storage videos (≤3) migrated to DB via historyController.migrateLocalVideos()
  → Local storage cleared
  → authState emits Authenticated()
  → Router refreshes → user stays on current screen (no jarring redirect)
```

### 4.5 Authenticated — Extract a Video
```
Home screen
  → User pastes YouTube Shorts URL into input field
  → Taps "Extract" button
  → extractController.extract(url) called (with Bearer JWT)
  → extractResult emits Loading() → UI shows loading state

Edge Function pipeline:
  1. Validate URL → extract video ID
  2. Check videos table → if cached, return immediately (< 500ms)
  3. youtube-caption-extractor → get captions
  4. If no captions → AssemblyAI fallback
  5. Groq/Llama 3.1 → structured JSON
  6. Enrich exercises with YouTube thumbnail URL
  7. Save to videos + user_videos tables
  8. Return result

  → extractResult emits Success(VideoModel)
  → UI navigates to WorkoutDetailScreen or DietDetailScreen
  → historyController silently refreshes
```

### 4.6 Browse History
```
Home screen (History tab)
  → If guest: renders local storage videos (up to 3) with a banner:
      "Sign in to sync your history across devices"
  → If authenticated: historyController.load() fetches from DB
  → User taps a video → navigates to detail screen
```

### 4.7 View Exercise Detail & Track Progress
```
WorkoutDetailScreen
  → User taps an exercise card
  → Navigates to ExerciseDetailScreen

ExerciseDetailScreen
  → If authenticated: progressController.load(exercise.name) → chart shows real data
  → If guest: chart shows empty state with prompt to sign in
  → Authenticated user taps "+" → bottom sheet → logs entry → chart refreshes
```

### 4.8 Sign Out
```
  → Supabase session cleared
  → AppCache token cleared
  → resetAllAtoms() called
  → Local storage guest state reset (count = 0)
  → Router redirects to Home (still usable as guest)
```


---

## 5. Screen Map

```
HomeScreen (no auth wall — accessible to everyone)
  ├── [Extract tab]
  │     URL input field
  │       → loading state (spinner)
  │       → WorkoutDetailScreen
  │             └── ExerciseDetailScreen
  │                   ├── Progress chart (auth only — upsell if guest)
  │                   └── Log Progress bottom sheet (auth only)
  │       → DietDetailScreen
  │
  ├── [History tab]
  │     Guest:         local storage videos (≤3) + sign-in banner
  │     Authenticated: cloud history feed
  │       ├── WorkoutDetailScreen
  │       └── DietDetailScreen
  │
  └── Sign in entry point (menu / upsell sheet)
        └── Google OAuth → back to previous screen
```


---

## 6. Feature Descriptions

### 6.1 URL Extraction (Guest + Authenticated)
The primary feature. Available to everyone. User pastes any YouTube Shorts URL. The system:
- Validates it's a Shorts URL
- Checks the shared cache first (instant if already processed by any user)
- Falls back to full pipeline: captions → transcription → LLM extraction
- Returns typed structured data (`workout` or `diet`)

**Guest behaviour:** Result saved to `AppCache` local storage. Counter incremented. At 3/3, extraction is blocked and the upsell sheet is shown instead.  
**Auth behaviour:** Result saved to Supabase DB and linked to the user's account.

**Supported URL formats:**
- `https://youtube.com/shorts/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

### 6.2 Workout Detail (Guest + Authenticated)
Displays the extracted workout with:
- Exercise list — each card shows name, sets/reps/duration, muscle group badge, description
- Equipment tags, difficulty indicator, suggested plan
- Each exercise card is tappable → Exercise Detail

### 6.3 Exercise Detail (Guest + Authenticated)
Displays a single exercise with:
- YouTube thumbnail as the hero banner (with illustrated athlete fallback)
- Frosted-glass stat boxes: Sets / Reps / Duration / Rest
- Full description with Read more/less toggle
- Notes card (if present)
- Progress chart — **authenticated only.** Guests see an empty chart with a sign-in prompt.
- Log progress button — **authenticated only.**

### 6.4 Diet Detail (Guest + Authenticated)
Displays the extracted recipe with:
- Title and prep/cook time
- Ingredients list with quantities
- Step-by-step instructions
- Nutrition card: calories, protein, carbs, fat

### 6.5 History (Guest + Authenticated, different behaviour)
**Guest:** Shows up to 3 locally saved videos. A persistent banner reads: *"Sign in to sync your history across devices and unlock unlimited extracts."*  
**Authenticated:** Full cloud history, newest first, paginated.

### 6.6 Upsell Entry Points
Three natural moments where the sign-in prompt appears — never interruptive, always contextual:
1. **4th extract attempt** — "You've used your 3 free extracts."
2. **Log progress tap** — "Sign in to track your progress over time."
3. **History banner** — persistent but dismissible, not a blocker.

Each upsell shows a single CTA: **Continue with Google**. Users can always dismiss and keep browsing.

### 6.7 Local → Cloud Migration
When a guest signs in, their locally saved videos (≤3) are automatically migrated to the DB via `historyController.migrateLocalVideos()`. Local storage is cleared after successful migration. The user never notices — their history just appears in the History tab.

### 6.8 Progress Tracking (Authenticated only)
Per-exercise progress chart. Each data point = a user-logged entry with a value (e.g. 47.5kg). Chart draws in on load with a cubic bezier animated line, green gradient fill, dumbbell icons on peaks.

---

## 7. Out of Scope (v1)
- TikTok support
- Native mobile apps (iOS / Android)
- Social features (sharing, following, comments)
- AI-generated workout plans
- Video playback within the app
- Apple SSO (requires Apple Developer account — add in v2)
- Notifications / push
- Monetisation / paywall
- Localisation / translations

---

## 8. Database Schema

Run in Supabase SQL editor. All tables have RLS enabled.

```sql
-- Videos — shared cache, one row per URL across all users
CREATE TABLE videos (
  url         TEXT PRIMARY KEY,
  type        TEXT NOT NULL CHECK (type IN ('workout', 'diet', 'unknown')),
  data        JSONB NOT NULL DEFAULT '{}',
  transcript  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Links a user to videos they have submitted
CREATE TABLE user_videos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  video_url   TEXT NOT NULL REFERENCES videos(url) ON DELETE CASCADE,
  saved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, video_url)
);

-- Per-user, per-exercise progress entries
CREATE TABLE progress (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  value         NUMERIC NOT NULL,
  unit          TEXT NOT NULL DEFAULT 'kg',
  logged_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE videos      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress    ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "videos_public_read"  ON videos      FOR SELECT USING (true);
CREATE POLICY "user_videos_own"     ON user_videos USING (auth.uid() = user_id);
CREATE POLICY "progress_own"        ON progress    USING (auth.uid() = user_id);
```

### Schema Design Notes
- `videos.data` is `JSONB` not `TEXT` — enables future querying inside JSON (filter by muscle group, calories, etc.)
- `auth.users` is managed by Supabase Auth — no separate users table needed
- `progress.exercise_name` is a plain string — simple, flexible, no FK to an exercises table
- Videos table is intentionally write-protected from Flutter — only Edge Functions write to it via service role key

---

## 9. Supabase Edge Functions

### 9.1 `extract` — Full Pipeline

**Endpoint:** `POST /functions/v1/extract`  
**Auth:** Optional — guests can call this without a JWT. User linkage only happens when authenticated.

```
Request:  { "url": "https://youtube.com/shorts/ABC123" }
Response: { url, type, data, created_at, cached: bool }
```

**Pipeline:**
```
1. Validate URL → extract videoId
2. Auth → attempt to verify JWT (optional — no 401 if missing)
3. Cache check → return immediately if video already in DB
4. youtube-caption-extractor → get captions (no binary, no API key)
5. AssemblyAI fallback if no captions available
6. Groq/Llama 3.1 → structured JSON extraction
7. Enrich: set image_url on exercises = i.ytimg.com thumbnail
8. Save to videos table (always)
9. Save to user_videos table (only if authenticated)
10. Return result
```

**Error responses:**

| Status | Reason |
|--------|--------|
| 400 | Invalid or unsupported URL |
| 401 | Missing/invalid auth token |
| 422 | Could not extract transcript |
| 500 | Internal pipeline error |

```typescript
// supabase/functions/extract/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getSubtitles } from 'npm:youtube-caption-extractor'

serve(async (req) => {
  const { url } = await req.json()
  const authHeader = req.headers.get('Authorization')!

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const videoId = extractVideoId(url)
  if (!videoId) return error(400, 'Invalid YouTube URL')

  const { data: { user } } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (!user) return error(401, 'Unauthorized')

  // Cache hit
  const { data: cached } = await supabase
    .from('videos').select().eq('url', url).single()
  if (cached) {
    await linkUserVideo(supabase, user.id, url)
    return ok({ ...cached, cached: true })
  }

  // Captions
  let transcript = ''
  try {
    const subtitles = await getSubtitles({ videoID: videoId, lang: 'en' })
    transcript = subtitles.map((s: any) => s.text).join(' ')
  } catch (_) {
    transcript = await transcribeWithAssemblyAI(videoId)
  }
  if (!transcript) return error(422, 'Could not extract transcript')

  // Groq
  const extracted = await extractWithGroq(transcript)

  // Enrich with thumbnail
  if (extracted.type === 'workout') {
    const thumb = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
    extracted.data.exercises = extracted.data.exercises.map((e: any) => ({
      ...e, image_url: thumb,
    }))
  }

  // Persist
  await supabase.from('videos').insert({ url, ...extracted, transcript })
  await linkUserVideo(supabase, user.id, url)

  return ok({ url, ...extracted, cached: false })
})
```

### 9.2 `history`

**Endpoint:** `GET /functions/v1/history`  
**Auth:** Required

Returns the authenticated user's processed videos, newest first, limit 50.

### 9.3 `progress`

**Endpoint:** `GET /functions/v1/progress?exercise={name}` — fetch entries for chart  
**Endpoint:** `POST /functions/v1/progress` — log a new entry  
**Auth:** Required

---

## 10. Flutter App Structure

Only new files listed. Nothing in `core/` changes.

```
lib/
  models/
    video_model.dart
    workout_model.dart
    exercise_model.dart
    diet_model.dart
    ingredient_model.dart
    progress_model.dart

  data/
    extract_service.dart      # POST /functions/v1/extract
    history_service.dart      # GET  /functions/v1/history
    progress_service.dart     # GET/POST /functions/v1/progress

  controllers/
    extract_controller.dart   # extractResult atom + ExtractController
    history_controller.dart   # history atom + HistoryController
    progress_controller.dart  # progress atom + ProgressController

  views/
    auth/
      login_screen.dart
    home/
      home_screen.dart              # URL input + history tab
    workouts/
      workout_detail_screen.dart    # already built — wire to real data
      exercise_detail_screen.dart   # already built — wire to real data
    diet/
      diet_detail_screen.dart       # new

  router.dart                       # add ReelFit routes
  main.dart                         # add Supabase.initialize()
```

---

## 11. Models

All models use `Helper.get*()` — never raw casts. `fromJson` accepts `dynamic`. `fromJsonToList` guards against null and non-List.

### `VideoModel`
```dart
class VideoModel {
  final String url;
  final String type;       // 'workout' | 'diet' | 'unknown'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool cached;

  WorkoutModel? get asWorkout =>
      type == 'workout' ? WorkoutModel.fromJson(data) : null;

  DietModel? get asDiet =>
      type == 'diet' ? DietModel.fromJson(data) : null;

  String get videoId { /* regex extract from url */ }

  String get thumbnailUrl =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  static VideoModel fromJson(dynamic json) => VideoModel(...)
  static List<VideoModel> fromJsonToList(dynamic json) { ... }
}
```

### `ExerciseModel`
Fields: `name`, `sets?`, `reps?`, `duration?`, `rest?`, `notes?`, `description`, `targetMuscleGroup`, `timestampSeconds?`, `imageUrl?`

### `WorkoutModel`
Fields: `url`, `exercises`, `suggestedPlan?`, `targetMuscleGroups`, `difficulty?`, `equipment`

### `DietModel`
Fields: `title`, `ingredients`, `steps`, `nutrition?`, `prepTime?`, `cookTime?`, `servings?`, `url`

### `IngredientModel`
Fields: `item`, `quantity?`

### `ProgressModel`
Fields: `id`, `exerciseName`, `value`, `unit`, `loggedAt`

---

## 12. Services

All extend `APIRequest`. Arrow syntax, no async/await, no logic.

```dart
class ExtractService extends APIRequest {
  /// POST /functions/v1/extract
  Future<Result<VideoModel>> extract({required String url}) =>
      authPost('/functions/v1/extract', VideoModel.fromJson, body: {'url': url});
}

class HistoryService extends APIRequest {
  /// GET /functions/v1/history
  Future<Result<List<VideoModel>>> getHistory() =>
      authGet('/functions/v1/history', VideoModel.fromJsonToList);
}

class ProgressService extends APIRequest {
  /// GET /functions/v1/progress?exercise={name}
  Future<Result<List<ProgressModel>>> getProgress({required String exerciseName}) =>
      authGet('/functions/v1/progress?exercise=$exerciseName', ProgressModel.fromJsonToList);

  /// POST /functions/v1/progress
  Future<Result<ProgressModel>> logProgress({
    required String exerciseName,
    required double value,
    required String unit,
  }) =>
      authPost('/functions/v1/progress', ProgressModel.fromJson, body: {
        'exercise_name': exerciseName,
        'value': value,
        'unit': unit,
      });
}
```

---

## 13. Controllers

### `extract_controller.dart`
```dart
// Guest limit constant
const _guestVideoLimit = 3;

final extractResult = AsyncAtom<VideoModel>();
final guestCount = Atom(0); // loaded from AppCache on init

class ExtractController {
  final _service = ExtractService();

  Future<void> init() async {
    guestCount.emit(await AppCache.getGuestVideoCount());
  }

  bool get isGuest => authState.value is! Authenticated;
  bool get hasReachedGuestLimit =>
      isGuest && guestCount.value >= _guestVideoLimit;

  Future<void> extract(String url) async {
    // Block and show upsell if guest limit reached
    if (hasReachedGuestLimit) {
      extractResult.emit(Failure('guest_limit'));
      return;
    }

    extractResult.emit(Loading());
    final result = await _service.extract(url: url);
    extractResult.emit(result);

    if (result is Success<VideoModel>) {
      if (isGuest) {
        // Save to local storage
        await AppCache.saveGuestVideo(result.value);
        guestCount.emit(guestCount.value + 1);
      } else {
        // Authenticated — history refresh
        historyController.refresh(showLoading: false);
      }
    }
  }

  void reset() => extractResult.emit(Idle());
}

final extractController = ExtractController();
```

### `history_controller.dart`
```dart
final history = AsyncAtom<List<VideoModel>>();

class HistoryController {
  final _service = HistoryService();

  bool get isGuest => authState.value is! Authenticated;

  Future<void> load() async {
    if (isGuest) {
      // Load from local storage
      final local = await AppCache.getGuestVideos();
      history.emit(local.isEmpty ? Empty() : Success(local));
      return;
    }
    final current = history.value;
    if (current is Success<List<VideoModel>> && current.value.isNotEmpty) {
      _service.getHistory().then((r) => history.emit(r));
      return;
    }
    history.emit(Loading());
    history.emit(await _service.getHistory());
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) history.emit(Loading());
    history.emit(await _service.getHistory());
  }

  /// Called after sign-in — migrates local guest videos to the user's DB account.
  Future<void> migrateLocalVideos() async {
    final local = await AppCache.getGuestVideos();
    if (local.isEmpty) return;
    for (final video in local) {
      await _service.linkVideo(url: video.url); // POST /functions/v1/history/link
    }
    await AppCache.clearGuestVideos();
    await AppCache.setGuestVideoCount(0);
    guestCount.emit(0);
    refresh(showLoading: false);
  }
}

final historyController = HistoryController();
```

### `progress_controller.dart`
```dart
final progress = AsyncAtom<List<ProgressModel>>();

class ProgressController {
  final _service = ProgressService();

  Future<void> load(String exerciseName) async {
    progress.emit(Loading());
    progress.emit(await _service.getProgress(exerciseName: exerciseName));
  }

  Future<Result<ProgressModel>> log({
    required String exerciseName,
    required double value,
    required String unit,
  }) async {
    final result = await _service.logProgress(
      exerciseName: exerciseName,
      value: value,
      unit: unit,
    );
    if (result is Success<ProgressModel>) load(exerciseName);
    return result;
  }
}

final progressController = ProgressController();
```

---

## 14. Routing

Additions to `router.dart`:

```dart
GoRoute(path: '/home',      builder: (_, __) => const HomeScreen()),
GoRoute(path: '/workout/:videoId', builder: (_, state) =>
    WorkoutDetailScreen(videoId: state.pathParameters['videoId']!)),
GoRoute(path: '/workout/:videoId/exercise', builder: (_, state) =>
    ExerciseDetailScreen(exercise: state.extra as ExerciseModel)),
GoRoute(path: '/diet/:videoId', builder: (_, state) =>
    DietDetailScreen(videoId: state.pathParameters['videoId']!)),
```

Navigation from workout → exercise:
```dart
context.push('/workout/$videoId/exercise', extra: exercise);
```

---

## 15. Auth Integration

Supabase handles Google SSO. The resulting JWT is stored in `AppCache` and picked up automatically by `APIRequest` on every request — no changes to `core/`.

The app is **not behind an auth wall.** The router defaults to `HomeScreen` for everyone. Auth state only controls feature availability within screens.

### `AuthRepository` additions
```dart
Future<Result<bool>> signInWithGoogle() async {
  await Supabase.instance.client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: Env.supabaseRedirectUrl,
  );
  return Success(true); // actual auth arrives via onAuthStateChange
}

Future<Result<bool>> checkAuth() async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return Failure('No session');
  await AppCache.setToken(session.accessToken);
  return Success(true);
}

Future<void> signOut() async {
  await Supabase.instance.client.auth.signOut();
  await AppCache.clearToken();
}
```

### `AuthBuilder` additions
After `Authenticated` fires, trigger local → cloud migration:
```dart
} else if (currentAuthState is Authenticated) {
  await AppCache.setToken(session.accessToken);
  await historyController.migrateLocalVideos(); // migrate guest videos silently
}
```

### `main.dart` addition
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

### Router behaviour
- Default route `/home` — always accessible, no redirect
- No `LoginScreen` as a standalone route — sign-in is triggered via upsell sheets and a menu button
- After sign-in OAuth callback, router returns the user to wherever they were

---

## 16. Environment Variables

### Flutter (injected via `--dart-define` at build time)
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_REDIRECT_URL=https://yourapp.com/auth/callback
```

### Edge Functions (set in Supabase dashboard → Project Settings → Edge Functions)
```
GROQ_API_KEY=gsk_...
ASSEMBLYAI_API_KEY=...
SUPABASE_SERVICE_ROLE_KEY=eyJ...   # auto-available in Edge Functions
```

---

## 17. Build Roadmap

### Phase 1 — Infrastructure (no UI changes)
- [ ] Create Supabase project (supabase.com → New project)
- [ ] Run SQL migrations in Supabase SQL editor
- [ ] Enable Google OAuth in Supabase Auth → Providers → Google
- [ ] Add Supabase credentials to `Env`
- [ ] Add `Supabase.initialize()` to `main.dart`
- [ ] Update `AuthRepository` with SSO + token storage
- [ ] Write + deploy `extract` Edge Function
- [ ] Write + deploy `history` Edge Function
- [ ] Write + deploy `progress` Edge Function
- [ ] Test all functions locally with `supabase functions serve`

### Phase 2 — Data Layer
- [ ] Write all 6 models
- [ ] Write all 3 services
- [ ] Write all 3 controllers
- [ ] Add routes to `router.dart`

### Phase 3 — UI Wiring
- [ ] `LoginScreen` — Google SSO button
- [ ] `HomeScreen` — URL input + extract call + tab for history
- [ ] `WorkoutDetailScreen` — wire to real `WorkoutModel` from atom
- [ ] `ExerciseDetailScreen` — wire to real `ProgressModel`
- [ ] `DietDetailScreen` — new screen

### Phase 4 — Polish
- [ ] Log progress entry from `ExerciseDetailScreen` (bottom sheet)
- [ ] Empty states + error states + retry buttons
- [ ] Skeleton loaders on history feed
- [ ] PWA config (manifest + icons)
- [ ] Deploy to Vercel / Firebase Hosting

---

## 18. Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend | Supabase Edge Functions | No server to manage, scales to zero, free tier covers v1 |
| Transcription | `youtube-caption-extractor` npm | Pure HTTP, no binary, works in Deno — replaces yt-dlp entirely |
| Transcription fallback | AssemblyAI | Handles Shorts without auto-captions; paid only when needed |
| LLM | Groq / Llama 3.1 8B | Fast, free tier, JSON mode, good extraction quality |
| Database | Supabase PostgreSQL (JSONB) | Flexible schema for workout vs diet, queryable, co-located |
| Auth | Supabase Auth — Google SSO | Built-in, handles token refresh, RLS integration |
| Screenshots | YouTube thumbnails (`i.ytimg.com`) | Free, permanent, no API key, no CORS, no ffmpeg needed |
| Guest local storage | `AppCache` (SharedPreferences) | Already in `core/cache/` — stores up to 3 `VideoModel` JSON blobs + a count integer. Zero new dependencies. |
| Guest → cloud migration | On first sign-in, `migrateLocalVideos()` links each local URL to the new user account silently | Seamless UX — user never loses their 3 videos |
| Auth wall | None — home screen accessible to everyone | Lowers friction for new users; upsell is contextual not forced |
| Caching | DB-level shared across all users | Zero cost for repeat videos regardless of who processed it first |
| State management | Existing `AsyncAtom` / `Atom` | No new patterns introduced |

---

## 19. Known Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `youtube-caption-extractor` breaks (YouTube layout change) | Medium | Library is actively maintained; pin to a known version and monitor releases |
| Shorts without captions → AssemblyAI cost at scale | Low (v1 volume is tiny) | Caption-first flow minimises paid calls; add usage cap if needed |
| Groq rate limits on free tier | Low (v1 volume) | Retry with exponential backoff; upgrade tier if needed |
| Edge Function cold start latency | Low | Supabase keeps functions warm; cache hits avoid the pipeline entirely |
| YouTube thumbnail missing (`hqdefault` 404) | Very low | `Image.network` `errorBuilder` falls back to `_AthletePainter` illustration |
| JSONB data growing large | Low | Cap at 20 exercises / 20 steps in Groq prompt; transcript truncated at 8k chars |
| Supabase free tier limits (500MB DB, 5GB bandwidth) | Very low for v1 | Monitor in dashboard; upgrade is straightforward |