-- First, let's check and fix the tracks table structure
-- Drop existing constraints that might be causing issues
ALTER TABLE public.tracks 
  DROP CONSTRAINT IF EXISTS tracks_collaboration_id_fkey;

-- Add layer_id column if it doesn't exist
ALTER TABLE public.tracks 
  ADD COLUMN IF NOT EXISTS layer_id TEXT;

-- Make sure all required columns exist and have proper types
ALTER TABLE public.tracks 
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN track_url SET NOT NULL;

-- Add back the collaboration foreign key with proper handling
ALTER TABLE public.tracks 
  ADD CONSTRAINT tracks_collaboration_id_fkey 
  FOREIGN KEY (collaboration_id) 
  REFERENCES public.collaborations(id) 
  ON DELETE SET NULL;

-- Update RLS policies for tracks to be more permissive during testing
DROP POLICY IF EXISTS "Users can create own tracks" ON public.tracks;
CREATE POLICY "Users can create own tracks" ON public.tracks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own tracks" ON public.tracks;
CREATE POLICY "Users can update own tracks" ON public.tracks
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own tracks" ON public.tracks;
CREATE POLICY "Users can delete own tracks" ON public.tracks
    FOR DELETE USING (auth.uid() = user_id);

-- Also ensure the users table has proper structure
ALTER TABLE public.users
  ALTER COLUMN artist_name SET NOT NULL;

-- Create a trigger to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, artist_name)
  VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'artist_name', 'Unknown Artist'))
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      artist_name = COALESCE(EXCLUDED.artist_name, public.users.artist_name);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also handle updates to ensure user profile stays in sync
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS trigger AS $$
BEGIN
  UPDATE public.users
  SET email = new.email,
      updated_at = NOW()
  WHERE id = new.id;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_update();
