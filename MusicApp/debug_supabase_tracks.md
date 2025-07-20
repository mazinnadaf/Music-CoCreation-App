# Debugging Supabase Track Saving

## Summary of Changes Made

1. **Fixed the track URL issue**: The code was saving local file paths instead of remote Beatoven URLs. Now it correctly saves the remote URL from the Beatoven API response.

2. **Key code changes in AudioModels.swift**:
   - Removed unnecessary variable declaration
   - Modified the track saving logic to extract the correct remote URL from the API response
   - Added proper metadata including prompt and duration

## How Track Saving Works Now

1. When a track is generated through Beatoven API, the response contains URLs in the `meta` object
2. The code extracts the appropriate URL based on the selected instrument:
   - For "All" instrument: uses `meta.track_url`
   - For specific instruments (bass, melody, etc.): uses `meta.stems_url.[instrument]`
3. This remote URL is then saved to Supabase along with metadata

## Debugging Steps

If tracks are still not saving:

1. **Check Console Logs**: Look for these log messages:
   ```
   [Supabase] Saving track with:
   [Supabase]   - User ID: ...
   [Supabase]   - Layer ID: ...
   [Supabase]   - Track URL: ...
   [Supabase] Track saved successfully
   ```
   Or error messages:
   ```
   [Supabase] Failed to save track to Supabase: ...
   ```

2. **Verify User Authentication**:
   - Ensure you're logged in before creating tracks
   - Check if `currentUser` is not nil in SupabaseManager

3. **Check Database Permissions**:
   - Run this SQL in Supabase SQL Editor to verify RLS policies:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'tracks';
   ```

4. **Test Direct Insert**:
   - Try inserting a track directly in Supabase SQL Editor:
   ```sql
   INSERT INTO public.tracks (user_id, layer_id, track_url, metadata)
   VALUES (
     (SELECT id FROM auth.users LIMIT 1),
     'test-layer-id',
     'https://example.com/test.wav',
     '{"test": true}'::jsonb
   );
   ```

5. **Check Network Tab**:
   - In Xcode, monitor network requests to Supabase
   - Look for POST requests to `/rest/v1/tracks`
   - Check response status and body

## Expected Behavior

After generating a track through the Beatoven API:
1. The track should play locally from the downloaded file
2. The remote URL should be saved to Supabase
3. You should see the track in your Supabase dashboard under the `tracks` table

## Common Issues and Solutions

1. **"Auth required" error**: Make sure you're logged in
2. **"Invalid data" error**: Check if all required fields are being sent
3. **Network errors**: Verify Supabase URL and anon key are correct
4. **RLS policy errors**: User might not have permission to insert tracks

## Next Steps

1. Run the app and generate a new track
2. Check the Xcode console for any error messages
3. Verify in Supabase dashboard if the track was saved
4. If still having issues, check the network logs for the exact error response
