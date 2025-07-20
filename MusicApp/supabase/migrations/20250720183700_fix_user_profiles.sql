-- First, add the updated_at column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create an update trigger to automatically update the updated_at column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Now recreate the user creation trigger with better error handling
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    artist_name_value TEXT;
BEGIN
    -- Get artist_name from metadata, with fallback
    artist_name_value := COALESCE(
        new.raw_user_meta_data->>'artist_name',
        split_part(new.email, '@', 1),
        'Artist'
    );

    -- Insert or update user profile
    INSERT INTO public.users (
        id, 
        email, 
        artist_name, 
        bio, 
        profile_image_url, 
        created_at, 
        updated_at
    )
    VALUES (
        new.id, 
        new.email,
        artist_name_value,
        '',
        '',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        email = EXCLUDED.email,
        artist_name = CASE 
            WHEN users.artist_name IS NULL OR users.artist_name = '' 
            THEN EXCLUDED.artist_name 
            ELSE users.artist_name 
        END,
        updated_at = NOW();
    
    RETURN new;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the signup
        RAISE WARNING 'Error in handle_new_user for %: %', new.id, SQLERRM;
        RETURN new;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create a function to manually fix any missing user profiles
CREATE OR REPLACE FUNCTION public.fix_missing_user_profiles()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    fixed_count INTEGER;
BEGIN
    -- Insert missing user profiles
    WITH inserted AS (
        INSERT INTO public.users (id, email, artist_name, bio, profile_image_url, created_at, updated_at)
        SELECT 
            au.id,
            au.email,
            COALESCE(au.raw_user_meta_data->>'artist_name', split_part(au.email, '@', 1), 'Artist'),
            '',
            '',
            au.created_at,
            NOW()
        FROM auth.users au
        LEFT JOIN public.users u ON au.id = u.id
        WHERE u.id IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO fixed_count FROM inserted;
    
    RETURN fixed_count;
END;
$$;

-- Run the fix function and show how many profiles were fixed
DO $$ 
DECLARE 
    fixed_count INTEGER;
BEGIN 
    fixed_count := public.fix_missing_user_profiles();
    RAISE NOTICE 'Fixed % missing user profiles', fixed_count;
END $$;
