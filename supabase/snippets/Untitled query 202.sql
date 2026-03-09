
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
