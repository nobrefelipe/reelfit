# ReelFit — Setup Guide

Everything you need to do before writing a single line of code.
Complete each step in order and tick the checklist at the bottom before opening Claude Code.

---

## Step 1 — Supabase Account & Project

1. Go to [supabase.com](https://supabase.com) → Sign up (free)
2. Click **New Project**
3. Fill in:
   - **Name:** `reelfit`
   - **Database password:** generate a strong one and save it somewhere safe
   - **Region:** pick closest to you (Europe West for UK)
4. Wait ~2 minutes for the project to provision

---

## Step 2 — Get Your Keys

Once the project is ready, go to **Settings → API** and copy these three values:

| Key | Where you will use it |
|-----|-----------------------|
| **Project URL** | `SUPABASE_URL` in Flutter + Edge Functions |
| **anon / public key** | `SUPABASE_ANON_KEY` in Flutter |
| **service_role / secret key** | Edge Functions only — never put this in Flutter |

Save all three somewhere safe. A `.env.local` file works fine (see Step 10).

---

## Step 3 — Run the Database Migrations

1. In the Supabase dashboard → **SQL Editor** → **New query**
2. Paste the entire SQL block below
3. Click **Run**
4. Go to **Table Editor** and confirm you see three tables: `videos`, `user_videos`, `progress`

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

---

## Step 4 — Enable Google OAuth

### In Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (or use an existing one)
3. Navigate to **APIs & Services → Credentials → Create Credentials → OAuth client ID**
4. Set **Application type** to **Web application**
5. Under **Authorised redirect URIs**, add:
   ```
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```
   *(Your project ref is the subdomain in your Supabase Project URL — e.g. `abcdefgh` from `https://abcdefgh.supabase.co`)*
6. Click **Create** — copy the **Client ID** and **Client Secret**

### In Supabase

1. Go to **Auth → Providers → Google**
2. Toggle **Enable Google provider** on
3. Paste in your **Client ID** and **Client Secret**
4. Save

---

## Step 5 — Install the Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Verify installation
supabase --version
```

Then log in:

```bash
supabase login
```

This opens a browser window to authenticate with your Supabase account.

---

## Step 6 — Link the CLI to Your Project

Run these commands from inside your Flutter project root:

```bash
supabase init    # creates a supabase/ folder in your project
supabase link    # select your reelfit project from the list
```

---

## Step 7 — Install Deno

Deno is required to run and test Edge Functions locally.

```bash
# macOS
brew install deno

# Verify installation
deno --version
```

---

## Step 8 — Get Your Third-Party API Keys

You need two external API keys before writing the Edge Functions.

### Groq (LLM extraction — free)

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up and go to **API Keys → Create API Key**
3. Copy the key (starts with `gsk_`)

### AssemblyAI (audio transcription fallback — free tier)

1. Go to [assemblyai.com](https://www.assemblyai.com)
2. Sign up → dashboard shows your **API Key** immediately
3. Copy the key

---

## Step 9 — Set Edge Function Secrets

These secrets are injected into your Edge Functions at runtime. Run from your project root:

```bash
supabase secrets set GROQ_API_KEY=gsk_your_key_here
supabase secrets set ASSEMBLYAI_API_KEY=your_key_here
```

Inside Edge Functions they are accessed as:
```typescript
Deno.env.get('GROQ_API_KEY')
Deno.env.get('ASSEMBLYAI_API_KEY')
```

---

## Step 10 — Create a `.env.local` File

Create this file at your **project root** for local development.
**Never commit this file to git.**

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_REDIRECT_URL=http://localhost:3000/auth/callback
GROQ_API_KEY=gsk_...
ASSEMBLYAI_API_KEY=...
```

Then add it to `.gitignore`:

```bash
echo ".env.local" >> .gitignore
```

---

## Step 11 — Install the Supabase Flutter Package

Add to `pubspec.yaml` under `dependencies` (confirm latest version at [pub.dev/packages/supabase_flutter](https://pub.dev/packages/supabase_flutter)):

```yaml
dependencies:
  supabase_flutter: ^2.x.x
```

Then run:

```bash
flutter pub get
```

---

## Pre-Build Checklist

Complete every item before opening Claude Code.

### Supabase
- [ ] Supabase project created
- [ ] Project URL, anon key, and service role key saved
- [ ] SQL migrations ran successfully — 3 tables visible in Table Editor
- [ ] Google OAuth configured (Client ID + Secret added to Supabase Auth)

### Local tooling
- [ ] `supabase` CLI installed — `supabase --version` works
- [ ] CLI linked to project — `supabase link` completed
- [ ] `deno` installed — `deno --version` works

### API keys
- [ ] Groq API key obtained from console.groq.com
- [ ] AssemblyAI API key obtained from assemblyai.com
- [ ] Both secrets set via `supabase secrets set`

### Project files
- [ ] `.env.local` created at project root with all 5 values
- [ ] `.env.local` added to `.gitignore`
- [ ] `supabase_flutter` added to `pubspec.yaml` and `flutter pub get` run

---

## Starting Claude Code

Once the checklist is complete, open Claude Code from your project root:

```bash
claude
```

Start every session with:

```
Read CLAUDE.md and tasks/todo.md before doing anything.
```

For tasks that involve the Edge Functions or data layer, also add:

```
Read tasks/reelfit_spec_final.md Section [X] before writing any code.
```

The first coding task is **todo.md Phase 1, task 1.2** — adding Supabase credentials to `Env`.
Tasks 1.1 is the manual Supabase setup you just completed.