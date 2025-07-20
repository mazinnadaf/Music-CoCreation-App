-- Ensure UUID extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- Drop existing functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_update() CASCADE;

-- Create improved trigger function for new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, artist_name, bio, profile_image_url, created_at, updated_at)
  VALUES (
    new.id, 
    new.email,
    COALESCE(new.raw_user_meta_data->>'artist_name', 'Artist'),
    COALESCE(new.raw_user_meta_data->>'bio', ''),
    COALESCE(new.raw_user_meta_data->>'profile_image_url', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    artist_name = COALESCE(EXCLUDED.artist_name, users.artist_name),
    updated_at = NOW();
  
  RETURN new;
END;
$$;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Function to handle user updates
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the users table when auth.users is updated
  UPDATE public.users
  SET 
    email = new.email,
    updated_at = NOW()
  WHERE id = new.id;
  
  RETURN new;
END;
$$;

-- Create trigger for user updates
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_update();

-- Ensure all required columns exist with proper defaults
ALTER TABLE public.users
  ALTER COLUMN artist_name SET DEFAULT 'Artist',
  ALTER COLUMN bio SET DEFAULT '',
  ALTER COLUMN profile_image_url SET DEFAULT '';

-- Make sure tracks table has all required columns
ALTER TABLE public.tracks
  ADD COLUMN IF NOT EXISTS title TEXT,
  ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;

-- Create collaboration_participants table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.collaboration_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collaboration_id UUID NOT NULL REFERENCES public.collaborations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'collaborator',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collaboration_id, user_id)
);

-- Enable RLS on collaboration_participants
ALTER TABLE public.collaboration_participants ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for collaboration_participants
DROP POLICY IF EXISTS "Users can view collaboration participants" ON public.collaboration_participants;
CREATE POLICY "Users can view collaboration participants" ON public.collaboration_participants
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Collaboration owners can manage participants" ON public.collaboration_participants;
CREATE POLICY "Collaboration owners can manage participants" ON public.collaboration_participants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.id = collaboration_participants.collaboration_id
            AND collaborations.creator_id = auth.uid()
        )
    );

-- Update storage policies to be more permissive
DROP POLICY IF EXISTS "Anyone can view audio files" ON storage.objects;
CREATE POLICY "Anyone can view audio files" ON storage.objects
    FOR SELECT USING (bucket_id = 'audio-files');

DROP POLICY IF EXISTS "Authenticated users can upload audio" ON storage.objects;
CREATE POLICY "Authenticated users can upload audio" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'audio-files' 
        AND auth.uid() IS NOT NULL
    );

DROP POLICY IF EXISTS "Users can update own audio files" ON storage.objects;
CREATE POLICY "Users can update own audio files" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'audio-files' 
        AND auth.uid() IS NOT NULL
    );

DROP POLICY IF EXISTS "Users can delete own audio files" ON storage.objects;
CREATE POLICY "Users can delete own audio files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'audio-files' 
        AND auth.uid() IS NOT NULL
    );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role;

-- For authenticated users, grant appropriate permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tracks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.collaborations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.collaboration_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.friendships TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.friend_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.starred_tracks TO authenticated;

-- For anon users, grant limited permissions
GRANT SELECT ON public.users TO anon;
GRANT SELECT ON public.tracks TO anon;
GRANT SELECT ON public.collaborations TO anon;
