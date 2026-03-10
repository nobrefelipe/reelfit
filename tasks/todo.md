# ReelFit — Build Todo
> For every session: read CLAUDE.md and this file before touching any code.
> Full spec lives in tasks/reelfit_spec_final.md — reference it for details on any task.
> Complete tasks in order. Do not skip ahead. Mark each task [x] when done.

---

## Phase 1 — Infrastructure

### 1.1 Supabase project setup (manual — done in browser)
- [x] Create project at supabase.com
- [x] Run SQL migrations from spec Section 8 in the Supabase SQL editor
- [x] Enable Google OAuth: Auth → Providers → Google → add Client ID + Secret
- [x] Copy Project URL and anon key (Settings → API)
- [ ] Note the service role key (used in Edge Functions only — never in Flutter)

### 1.2 Environment
- [x] Add to `core/env.dart`:
  ```dart
  static const supabaseUrl     = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const supabaseRedirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');
  ```
- [x] Add `supabase_flutter` to `pubspec.yaml` — confirm version with the developer before adding any package
- [x] Run `flutter pub get`

### 1.3 Supabase init
- [x] Read `main.dart` before editing
- [x] Add `Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey)` before `runApp()`
- [x] Run `flutter analyze` — fix any issues before continuing

### 1.4 Auth repository
- [x] Read existing `data/auth_repository.dart` (or `data/auth_service.dart`) before editing
- [x] Add `signInWithGoogle()` — calls `supabase.auth.signInWithOAuth(OAuthProvider.google)`
- [x] Update `checkAuth()` — reads `supabase.auth.currentSession`, stores token via `AppCache.setToken()`
- [x] Update `signOut()` — calls `supabase.auth.signOut()` and `AppCache.clearToken()`
- [x] Run `flutter analyze` — fix any issues

### 1.5 AuthBuilder
- [x] Read `core/auth_builder.dart` before editing
- [ ] On `Authenticated`: call `historyController.migrateLocalVideos()` after token is stored — **wired in Phase 2**
- [x] On `Unauthenticated`: keep existing `resetAllAtoms()` + add `AppCache.setGuestVideoCount(0)`
- [x] Run `flutter analyze` — fix any issues

### 1.6 AppCache — guest storage
- [x] Read `core/cache/app_cache.dart` before editing
- [x] Add `getGuestVideoCount()` → returns `int` from SharedPreferences (key: `guest_video_count`)
- [x] Add `setGuestVideoCount(int count)` → saves to SharedPreferences
- [x] Add `saveGuestVideo(Map<String,dynamic>)` → appends JSON to a list in SharedPreferences (key: `guest_videos`)
- [x] Add `getGuestVideos()` → returns `List<Map<String,dynamic>>` from SharedPreferences
- [x] Add `clearGuestVideos()` → removes both guest keys from SharedPreferences
- [x] Run `flutter analyze` — fix any issues

### 1.7 Edge Function — `extract`
- [x] Create `supabase/functions/extract/index.ts`
- [x] Auth is optional — attempt JWT verification but do not return 401 if missing
- [x] Cache check first — return `{ ...cached, cached: true }` if video URL already in DB
- [x] Transcript via Supadata API (replaced youtube-caption-extractor + AssemblyAI — both blocked by YouTube on server IPs)
- [x] Groq/Llama 3.1 extraction — structured JSON prompt for workout and diet types
- [x] Enrich exercises: set `image_url = https://i.ytimg.com/vi/{videoId}/hqdefault.jpg`
- [x] Save to `videos` table always — upsert with onConflict: 'url' to handle race conditions
- [x] Save to `user_videos` table only if user JWT was valid
- [x] Add `SUPADATA_API_KEY` secret: `supabase secrets set SUPADATA_API_KEY=...`
- [x] Test locally: `supabase functions serve extract --env-file .env.local`
- [x] Test with curl: `curl -X POST http://localhost:54321/functions/v1/extract -d '{"url":"..."}'`
- [x] Deploy: `supabase functions deploy extract`

### 1.8 Edge Function — `history`
- [x] Create `supabase/functions/history/index.ts`
- [x] Auth required — return 401 if no valid JWT
- [x] `GET` → query `user_videos` joined with `videos`, ordered by `saved_at DESC`, limit 50
- [x] `POST /history/link` → insert a `user_videos` row (used for guest migration)
- [x] Test locally + deploy

### 1.9 Edge Function — `progress`
- [x] Create `supabase/functions/progress/index.ts`
- [x] Auth required — return 401 if no valid JWT
- [x] `GET ?exercise={name}` → query `progress` for this user + exercise, ordered by `logged_at ASC`
- [x] `POST` → insert a new `progress` row, return the created row
- [x] Test locally + deploy

---

## Phase 2 — Data Layer

### 2.1 Models
> All models: use `Helper.get*()` — never raw casts. `fromJson` accepts `dynamic`. Always include `toString()`.

- [x] Create `models/video_model.dart`
  - Fields: `url`, `type`, `data`, `createdAt`, `cached`
  - Computed: `videoId` (regex from url), `thumbnailUrl` (i.ytimg.com)
  - Getters: `asWorkout`, `asDiet`
  - `fromJson`, `fromJsonToList`

- [x] Create `models/exercise_model.dart`
  - Fields: `name`, `sets?`, `reps?`, `duration?`, `rest?`, `notes?`, `description`, `targetMuscleGroup`, `timestampSeconds?`, `imageUrl?`
  - `fromJson`, `fromJsonToList`

- [x] Create `models/workout_model.dart`
  - Fields: `url`, `exercises`, `suggestedPlan?`, `targetMuscleGroups`, `difficulty?`, `equipment`
  - `fromJson`

- [x] Create `models/diet_model.dart`
  - Fields: `title`, `ingredients`, `steps`, `nutrition?`, `prepTime?`, `cookTime?`, `servings?`, `url`
  - `fromJson`

- [x] Create `models/ingredient_model.dart`
  - Fields: `item`, `quantity?`
  - `fromJson`, `fromJsonToList`

- [x] Create `models/progress_model.dart`
  - Fields: `id`, `exerciseName`, `value`, `unit`, `loggedAt`
  - `fromJson`, `fromJsonToList`

- [x] Run `flutter analyze` — fix any issues

### 2.2 Services
> All services extend `APIRequest`. Arrow syntax only. No async/await. No logic. Document each method with HTTP verb and path.

- [x] Create `data/extract_service.dart`
  - `extract({required String url})` → `authPost('/functions/v1/extract', VideoModel.fromJson, body: {'url': url})`

- [x] Create `data/history_service.dart`
  - `getHistory()` → `authGet('/functions/v1/history', VideoModel.fromJsonToList)`
  - `linkVideo({required String url})` → `authPost('/functions/v1/history/link', VideoModel.fromJson, body: {'url': url})`

- [x] Create `data/progress_service.dart`
  - `getProgress({required String exerciseName})` → `authGet('/functions/v1/progress?exercise=$exerciseName', ProgressModel.fromJsonToList)`
  - `logProgress({required String exerciseName, required double value, required String unit})` → `authPost('/functions/v1/progress', ProgressModel.fromJson, body: {...})`

- [x] Run `flutter analyze` — fix any issues

### 2.3 Controllers
> Atom defined at top of file. Global variable. Never created inside a widget or method. No try/catch. No BuildContext.

- [x] Create `controllers/extract_controller.dart`
  - `extractResult = AsyncAtom<VideoModel>()`
  - `guestCount = Atom(0)`
  - `isGuest` getter — checks `authState`
  - `hasReachedGuestLimit` getter
  - `init()` — loads guest count from `AppCache`
  - `extract(String url)` — blocks + emits `Failure('guest_limit')` if limit reached; saves to local if guest; refreshes history if authenticated
  - `reset()` — emits `Idle()`

- [x] Create `controllers/history_controller.dart`
  - `history = AsyncAtom<List<VideoModel>>()`
  - `load()` — local storage path for guest, DB path for authenticated, cache-first
  - `refresh({bool showLoading = true})`
  - `migrateLocalVideos()` — links each local URL to DB, clears local storage

- [x] Create `controllers/progress_controller.dart`
  - `progress = AsyncAtom<List<ProgressModel>>()`
  - `load(String exerciseName)`
  - `log({required String exerciseName, required double value, required String unit})` → returns `Result<ProgressModel>`, silently reloads chart on success

- [x] Run `flutter analyze` — fix any issues

### 2.4 Routing
- [x] Read `router.dart` before editing
- [x] Add routes:
  - `/home` → `HomeScreen`
  - `/workout/:videoId` → `WorkoutDetailScreen`
  - `/workout/:videoId/exercise` → `ExerciseDetailScreen` (exercise via `state.extra`)
  - `/diet/:videoId` → `DietDetailScreen`
- [x] Default route should be `/home` — no auth redirect on app start
- [x] Run `flutter analyze` — fix any issues

---

## Phase 3 — UI

### 3.1 Login / Sign-in sheet
- [x] Create `views/auth/sign_in_sheet.dart` — bottom sheet (not a full screen)
  - Title and subtitle passed as parameters (different upsell contexts use different copy)
  - `UIKButton` "Continue with Google" → calls `authController.signInWithGoogle()`
  - Dismiss button
  - Use `UIKitBottomSheet.show()` — never `showModalBottomSheet` directly

### 3.2 HomeScreen
- [x] Create `views/home/home_screen.dart`
  - Two tabs: Extract / History
  - **Extract tab:**
    - URL text input (use form builder or raw field — check CLAUDE.md rule)
    - "Extract" button → `extractController.extract(url)`
    - Renders `extractResult` atom:
      - `Loading()` → spinner
      - `Success(video)` → navigate to `/workout/:id` or `/diet/:id`
      - `Failure('guest_limit')` → show `SignInSheet` with upsell copy
      - Other `Failure` → show error snackbar via `UIKShowSnackBar`
    - Guest counter chip: "3/3 free extracts used" (visible when guest)
  - **History tab:**
    - Renders `history` atom
    - Guest: shows local videos + sign-in banner at top
    - Authenticated: shows cloud history
    - `Loading()` → skeleton loader
    - `Empty()` → empty state illustration
    - Each item tappable → navigate to detail screen

### 3.3 WorkoutDetailScreen
- [ ] Read existing `views/workouts/workout_detail_screen.dart` before editing
- [ ] Replace `WorkoutController.findById(videoId)` with data from `extractResult` atom
  - `final video = (extractResult.value as Success<VideoModel>).value`
  - `final workout = video.asWorkout`
- [ ] Each `_ExerciseCard` navigates to `/workout/$videoId/exercise` with `extra: exercise`
- [ ] Run `flutter analyze` — fix any issues

### 3.4 ExerciseDetailScreen
- [ ] Read existing `views/workouts/exercise_detail_screen.dart` before editing
- [ ] On mount: call `progressController.load(exercise.name)` if authenticated
- [ ] Wire progress chart to real `progress` atom data instead of dummy data
  - `progress` atom: `Loading()` → shimmer, `Success(entries)` → chart, `Empty()` → empty state
- [ ] If guest: show empty chart with prompt + `SignInSheet` trigger instead of "+" button
- [ ] If authenticated: show "+" button → log progress bottom sheet
- [ ] Run `flutter analyze` — fix any issues

### 3.5 Log Progress bottom sheet
- [ ] Create `views/workouts/log_progress_sheet.dart`
  - Number input for value (e.g. weight in kg)
  - Unit selector (kg / lbs / reps) — `Atom<String>` for selected unit
  - "Save" button → `progressController.log(...)` → on success dismiss sheet + show success snackbar
  - Use `UIKitBottomSheet.show()` to present it

### 3.6 DietDetailScreen
- [ ] Create `views/diet/diet_detail_screen.dart`
  - Hero banner with video thumbnail + fallback illustration
  - Title, prep time, cook time chips
  - Nutrition card: calories / protein / carbs / fat in stat boxes
  - Ingredients section — each item + quantity
  - Steps section — numbered list
  - "Watch video" button → `openUrl(video.url)`

---

## Phase 4 — Polish

### 4.1 Empty & error states
- [ ] `HomeScreen` history tab — empty state when no videos yet
- [ ] `ExerciseDetailScreen` — empty chart state with sign-in prompt for guests
- [ ] `HomeScreen` extract tab — clear error messaging for invalid URLs

### 4.2 Skeleton loaders
- [ ] History feed skeleton (3 placeholder cards while loading)
- [ ] WorkoutDetailScreen skeleton while `extractResult` is `Loading()`

### 4.3 Guest upsell polish
- [ ] Guest counter chip on HomeScreen extract tab (e.g. "2 of 3 free extracts used")
- [ ] Counter turns amber at 2/3, red at 3/3
- [ ] History tab sign-in banner — dismissible per session (store dismissed state in `Atom<bool>`)

### 4.4 PWA config
- [ ] Add `manifest.json` to `web/` — name, short_name, icons, theme_color, display: standalone
- [ ] Add app icons (192x192, 512x512) to `web/icons/`
- [ ] Update `web/index.html` with manifest link and theme-color meta tag

### 4.5 Deployment
- [ ] Run `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=SUPABASE_REDIRECT_URL=...`
- [ ] Deploy `build/web` to Vercel or Firebase Hosting
- [ ] Add the production URL as an allowed redirect URL in Supabase Auth settings
- [ ] Smoke test: extract a video, sign in, verify migration, log progress

---

## Reference

- Full spec: `tasks/reelfit_spec_final.md`
- Architecture rules: `CLAUDE.md`
- After any correction: log the pattern in `tasks/lessons.md`
