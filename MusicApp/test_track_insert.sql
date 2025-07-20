-- Test script to verify track insertion in Supabase
-- Run this in the Supabase SQL Editor to test if tracks can be inserted

-- First, check if you have any users
SELECT id, email, artist_name FROM auth.users LIMIT 5;
SELECT id, email, artist_name FROM public.users LIMIT 5;

-- Check the structure of the tracks table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tracks'
ORDER BY ordinal_position;

-- Check if layer_id column exists
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tracks'
AND column_name = 'layer_id';

-- Try to insert a test track (replace the user_id with an actual user ID from the first query)
-- INSERT INTO public.tracks (
--     user_id,
--     layer_id,
--     track_url,
--     title,
--     metadata
-- ) VALUES (
--     'YOUR-USER-ID-HERE',  -- Replace with actual user ID
--     'test-layer-123',
--     'https://example.com/test-track.wav',
--     'Test Track',
--     '{"instrument": "All", "bpm": 120}'::jsonb
-- );

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'tracks';

-- Check if there are any tracks in the database
SELECT COUNT(*) as track_count FROM public.tracks;

-- Get the last 5 tracks (if any)
SELECT 
    id,
    user_id,
    layer_id,
    track_url,
    title,
    created_at
FROM public.tracks 
ORDER BY created_at DESC 
LIMIT 5;
