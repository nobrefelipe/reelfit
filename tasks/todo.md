# ReelFit — Build Todo
> For every session: read CLAUDE.md, tasks/lessons.md and this file before touching any code.
> Full spec lives in tasks/reelfit_spec_final.md — reference it for details on any task.
> Complete tasks in order. Do not skip ahead. Mark each task [x] when done.

---

## Phase 1 — Infrastructure

### 1.1 Supabase project setup (manual — done in browser)
- [x] Create project at supabase.com
- [x] Run SQL migrations from spec Section 8 in the Supabase SQL editor
- [x] Enable Google OAuth: Auth → Providers → Google → add Client ID + Secret
- [x] Copy Project URL and anon key (Settings → API)
- [x] Note the service role key (used in Edge Functions only — never in Flutter)

### 1.2 Environment
- [x] Add to `core/env.dart`
- [x] Add `supabase_flutter` to `pubspec.yaml`
- [x] Run `flutter pub get`

### 1.3 Supabase init
- [x] Add `Supabase.initialize()` before `runApp()`
- [x] Run `flutter analyze`

### 1.4 Auth repository
- [x] `signInWithGoogle()`
- [x] `checkAuth()`
- [x] `signOut()`
- [x] Run `flutter analyze`

### 1.5 AuthBuilder
- [x] On `Authenticated`: call `historyController.migrateLocalVideos()` after token is stored
- [x] On `Unauthenticated`: `resetAllAtoms()` + `AppCache.setGuestVideoCount(0)`
- [x] Run `flutter analyze`

### 1.6 AppCache — guest storage
- [x] `getGuestVideoCount()` / `setGuestVideoCount()`
- [x] `saveGuestVideo()` / `getGuestVideos()` / `clearGuestVideos()`
- [x] Run `flutter analyze`

### 1.7 Edge Function — `extract`
- [x] Full pipeline with Supadata + Groq
- [x] Optional auth, cache check, upsert, user_videos link
- [x] Tested locally + deployed

### 1.8 Edge Function — `history`
- [x] GET history + POST link
- [x] Tested locally + deployed

### 1.9 Edge Function — `progress`
- [x] GET by exercise + POST new entry
- [x] Tested locally + deployed

---

## Phase 2 — Data Layer

### 2.1 Models
- [x] `video_model.dart`
- [x] `exercise_model.dart`
- [x] `workout_model.dart`
- [x] `diet_model.dart`
- [x] `ingredient_model.dart`
- [x] `progress_model.dart`

### 2.2 Services
- [x] `extract_service.dart` — uses `post()` not `authPost()` (guest support)
- [x] `history_service.dart`
- [x] `progress_service.dart`

### 2.3 Controllers
- [x] `extract_controller.dart`
- [x] `history_controller.dart`
- [x] `progress_controller.dart`

### 2.4 Routing
- [x] `/home` → `HomeScreen`
- [x] `/workout/:videoId` → `WorkoutDetailScreen`
- [x] `/workout/:videoId/exercise` → `ExerciseDetailScreen`
- [x] `/diet/:videoId` → `DietDetailScreen`

---

## Phase 3 — UI

### 3.1 Sign-in sheet
- [x] `views/auth/sign_in_sheet.dart` — bottom sheet, UIKitBottomSheet.show()

### 3.2 HomeScreen ← REBUILD
- [x] Delete existing home_screen.dart and rewrite from scratch
- [x] Single screen — no tabs
- [x] AppBar with app title + sign in / profile button (top right)
  - Guest: "Sign in" button → opens SignInSheet
  - Authenticated: avatar/icon → sign out option
- [x] Body: list of all extracted videos
  - Guest: loaded from AppCache via historyController
  - Authenticated: loaded from history atom
  - Each item: card with thumbnail, type badge (Workout / Recipe), date
  - Tappable → navigate to `/workout/:videoId` or `/diet/:videoId`
  - Empty state: illustration + "Paste a YouTube Shorts URL to get started"
  - Loading state: skeleton cards
- [x] Guest counter banner at top of list
  - "X/3 free extracts used" — amber at 2, red at 3
  - Hidden when authenticated
- [x] FAB (FloatingActionButton) bottom right → opens ExtractSheet
- [x] Run flutter analyze after

### 3.3 ExtractSheet ← NEW
- [x] Create `views/home/extract_sheet.dart` — bottom sheet
- [x] URL text input — paste YouTube Shorts URL
- [x] "Extract" button → `extractController.extract(url)`
- [x] Renders extractResult atom:
  - Loading() → button shows spinner, input disabled
  - Success → dismiss sheet, navigate to detail screen
  - Failure('guest_limit') → dismiss sheet, open SignInSheet
  - Other Failure → error snackbar, keep sheet open
- [x] Use UIKitBottomSheet.show() — never showModalBottomSheet directly
- [x] Run flutter analyze after

### 3.4 WorkoutDetailScreen
- [x] Wired to extractResult atom
- [x] Fix: use atom as widget — never read .value directly in build() (see lessons.md)
- [x] Run flutter analyze after

### 3.5 ExerciseDetailScreen
- [x] Read existing file before editing
- [x] On mount: call `progressController.load(exercise.name)` if authenticated
- [x] Wire progress chart to real `progress` atom
  - `Loading()` → shimmer
  - `Success(entries)` → chart
  - `Empty()` → empty state with sign-in prompt if guest
- [x] Guest: empty chart + SignInSheet trigger instead of "+" button
- [x] Authenticated: "+" button → LogProgressSheet
- [x] Run flutter analyze after

### 3.6 LogProgressSheet
- [x] Create `views/workouts/log_progress_sheet.dart`
- [x] Number input for value
- [x] Unit selector (kg / lbs / reps) — `Atom<String>` for selected unit
- [x] "Save" → `progressController.log(...)` → dismiss + success snackbar
- [x] UIKitBottomSheet.show() — never showModalBottomSheet directly
- [x] Run flutter analyze after

### 3.7 DietDetailScreen
- [ ] Create `views/diet/diet_detail_screen.dart`
- [ ] Hero banner — thumbnail + fallback illustration
- [ ] Title, prep/cook time chips
- [ ] Nutrition stat boxes: calories / protein / carbs / fat
- [ ] Ingredients list with quantities
- [ ] Numbered steps
- [ ] "Watch video" button → openUrl(video.url)
- [ ] Run flutter analyze after

---

## Phase 4 — Polish

### 4.1 Empty & error states
- [x] HomeScreen — empty state when no videos yet
- [x] ExerciseDetailScreen — empty chart state for guests
- [x] ExtractSheet — clear error for invalid URLs

### 4.2 Skeleton loaders
- [x] HomeScreen video list skeleton (3 placeholder cards)
- [x] WorkoutDetailScreen skeleton while extractResult is Loading()

### 4.3 Guest upsell polish
- [x] Guest counter banner dismissible per session — `Atom<bool>` for dismissed state
- [x] Counter colour: primary → amber at 2/3 → red at 3/3

### 4.4 PWA config
- [ ] `manifest.json` in `web/`
- [ ] App icons (192×192, 512×512)
- [ ] `web/index.html` — manifest link + theme-color meta

### 4.5 Deployment
- [ ] `flutter build web` with dart-defines
- [ ] Deploy `build/web` to Vercel or Firebase Hosting
- [ ] Add production URL to Supabase Auth allowed redirects
- [ ] Smoke test: extract → sign in → migrate → log progress

---

## Reference

- Full spec: `tasks/reelfit_spec_final.md`
- Architecture rules: `CLAUDE.md`
- Corrections log: `tasks/lessons.md` ← read every session