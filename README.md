# ReelFit

> Turn any YouTube fitness Short into a structured, trackable workout.

Paste a YouTube Shorts URL. Get back a clean breakdown of every exercise — sets, reps, muscle groups, descriptions — or a full recipe with ingredients and macros. No account required to try it.

---

## What it does

Short-form fitness content is everywhere but impossible to use. You watch a 60-second workout, forget half the exercises by the time you get to the gym, and have no way to track your progress against it.

ReelFit fixes that. Paste the URL, get the workout structured and saved, log your weights each session, watch your progress chart grow.

---

## Features

- **Instant extraction** — paste a YouTube Shorts URL, get structured data in seconds
- **Workout & diet support** — exercises with sets/reps/descriptions, or recipes with ingredients and macros
- **Shared cache** — every video is processed once and cached for all users. Repeat lookups are instant.
- **Progress tracking** — log your performance per exercise and track it over time on a chart
- **Try before you sign up** — extract up to 3 videos as a guest, results saved locally. Sign in with Google to unlock unlimited history and progress tracking across devices.

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web |
| Backend | Supabase Edge Functions (Deno / TypeScript) |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth — Google SSO |
| Transcription | `youtube-caption-extractor` → AssemblyAI fallback |
| LLM extraction | Groq / Llama 3.1 8B |
| State management | Custom `AsyncAtom` / `Atom` primitives |

Fully serverless — no server to manage or pay for at rest.

---

## Project structure

```
lib/
  core/                  # Reusable infrastructure — atoms, HTTP, cache, UI kit
  models/                # Plain Dart data classes
  data/                  # Services — HTTP calls only, no logic
  controllers/           # State + business logic
  views/                 # Screens and widgets
  router.dart
  main.dart

supabase/
  functions/
    extract/             # Full pipeline: captions → transcription → LLM → DB
    history/             # User video history
    progress/            # Exercise progress logging

tasks/
  todo.md                # Step-by-step build plan
  reelfit_spec_final.md  # Full product & engineering spec
  SETUP.md               # Environment setup guide
```

---

## Architecture

```
View → Controller → Service → Supabase Edge Function
           ↓
      atom.emit(result)
           ↓
      View rebuilds
```

- **Views** render atoms and call controller methods — no logic
- **Controllers** orchestrate service calls and manage atom state
- **Services** extend `APIRequest` and return `Result<T>` — HTTP only
- **Atoms** are the single source of truth — `Atom<T>` for local state, `AsyncAtom<T>` for async data

See `CLAUDE.md` for the full architecture rules.

---

## core/ — custom state management

The state management in this project is not a third-party package. `core/` is a custom infrastructure layer built from scratch after years of working with Provider, Riverpod, Bloc, and GetX — and finding that each one solved the demo case well and created friction at scale.

The result is three small primitives that cover everything:

**`Atom<T>`** — a reactive value that calls `emit()` to update and is itself a valid widget builder. No `ValueListenableBuilder` boilerplate, no `Consumer`, no `context.watch()`.

**`AsyncAtom<T>`** — wraps `Result<T>` for async data. Self-registers in a global registry on creation and resets automatically on logout. Callable as a widget with named parameters for each state — `success`, `loading`, `failure`, `empty`.

**`Result<T>`** — a sealed class with five states: `Idle`, `Loading`, `Success`, `Failure`, `Empty`. Every async operation in the app returns one of these. The compiler enforces exhaustive handling — you cannot forget the error case.

Together they make the right pattern the path of least resistance. Following the architecture takes less code than fighting it.

→ See [`core/README.md`](./lib/core/README.md) for the full writeup.

---

## Extraction pipeline

```
1. Validate YouTube Shorts URL
2. Check shared cache → return instantly if already processed
3. youtube-caption-extractor → get auto-captions (no API key needed)
4. AssemblyAI fallback → if no captions available
5. Groq / Llama 3.1 → extract structured JSON
6. Enrich exercises with YouTube thumbnail
7. Save to DB + link to user
8. Return result
```

---

## Guest vs authenticated

| Feature | Guest | Authenticated |
|---------|-------|---------------|
| Extract videos | ✅ up to 3 | ✅ unlimited |
| View workout / diet detail | ✅ | ✅ |
| History | ✅ local only (3 max) | ✅ cloud, all devices |
| Progress tracking | ❌ | ✅ |
| Data persists across devices | ❌ | ✅ |

When a guest signs in, their local videos are automatically migrated to their account.

---

## Getting started

See **[SETUP.md](./SETUP.md)** for the full environment setup guide including:
- Supabase project creation and SQL migrations
- Google OAuth configuration
- CLI installation (Supabase, Deno)
- API keys (Groq, AssemblyAI)
- Local `.env` setup

### Run locally

```bash
# Flutter app
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=SUPABASE_REDIRECT_URL=http://localhost:3000/auth/callback

# Edge Functions
supabase functions serve --env-file .env.local
```

### Deploy

```bash
# Build Flutter web
flutter build web \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=SUPABASE_REDIRECT_URL=https://yourapp.com/auth/callback

# Deploy Edge Functions
supabase functions deploy extract
supabase functions deploy history
supabase functions deploy progress
```

---

## Environment variables

### Flutter (passed via `--dart-define` at build time)

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon/public key |
| `SUPABASE_REDIRECT_URL` | OAuth callback URL |

### Edge Functions (set via `supabase secrets set`)

| Variable | Description |
|----------|-------------|
| `GROQ_API_KEY` | Groq API key — [console.groq.com](https://console.groq.com) |
| `ASSEMBLYAI_API_KEY` | AssemblyAI API key — [assemblyai.com](https://www.assemblyai.com) |

---

## Roadmap

- [x] POC — Dart Frog backend + Flutter UI
- [x] Serverless architecture design
- [x] Supabase Edge Functions pipeline
- [ ] Flutter auth + guest mode
- [ ] Full UI wiring
- [ ] Progress tracking
- [ ] PWA config
- [ ] Production deployment
- [ ] Apple SSO
- [ ] TikTok support