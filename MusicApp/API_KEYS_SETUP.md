# API Keys Setup Guide

This guide explains how to properly configure your API keys in the `Secrets.plist` file.

## Setting up Secrets.plist

1. **Create or update your Secrets.plist file** in your Xcode project
2. Make sure it's added to your app target (check the target membership in Xcode)
3. The file should **NOT** be committed to git (it's already in .gitignore)

## Required Keys

Your `Secrets.plist` should contain the following keys:

### For Beatoven API:
- **Key**: `BEATOVEN_API_KEY` (recommended) or `API_KEY`
- **Value**: Your actual Beatoven API key
- **Example**: `beatoven_1234567890abcdef` (NOT a Supabase key starting with `sb_`)

### For Supabase (if needed in the future):
- **Key**: `SB_API_KEY` 
- **Value**: Your Supabase secret key
- **Example**: `sb_secret_A8h5I0nBLkil-YJ-oRXvpA_9xYAMYzh`

## Example Secrets.plist Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BEATOVEN_API_KEY</key>
    <string>your_actual_beatoven_api_key_here</string>
    <key>SB_API_KEY</key>
    <string>your_supabase_secret_key_here</string>
</dict>
</plist>
```

## Important Notes

1. **Never commit API keys to git** - The Secrets.plist file should remain local only
2. **Use the correct key for each service** - Don't mix up Beatoven and Supabase keys
3. **The app will validate keys** - It will reject Supabase keys (starting with `sb_`) when looking for Beatoven API key
4. **Check the console logs** - The app provides detailed error messages if keys are misconfigured

## Troubleshooting

If you see this error:
```
[Beatoven] ❌ ERROR: API_KEY contains a Supabase key (starts with 'sb_')
```

It means you have a Supabase key where the Beatoven key should be. Update your Secrets.plist:
1. Change `API_KEY` to contain your Beatoven API key
2. Or add a new entry `BEATOVEN_API_KEY` with your Beatoven API key
3. Move your Supabase key to `SB_API_KEY` if needed

## Current Status

- ✅ Beatoven API integration uses `BEATOVEN_API_KEY` or `API_KEY` from Secrets.plist
- ✅ Supabase is currently using the hardcoded anonymous key in `SupabaseConfig.swift`
- ✅ Code validates that Beatoven keys don't start with `sb_`
