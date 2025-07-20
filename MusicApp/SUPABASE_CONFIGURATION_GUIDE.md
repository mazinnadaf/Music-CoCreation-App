# Complete Supabase Configuration Guide

## Overview
This guide will help you set up real Supabase authentication for the Music Co-Creation App. Currently, the app is running in mock mode, but with these steps, you can connect it to a real Supabase backend.

## Current Implementation Status

The app now has:
- ✅ Real Supabase authentication code (with fallback to mock mode)
- ✅ Sign up with email/password
- ✅ Sign in with email/password
- ✅ Logout functionality with confirmation
- ✅ Session persistence
- ✅ User profile creation

## Setup Steps

### 1. Update Your Supabase Configuration

Open `/MusicApp/MusicApp/Config/SupabaseConfig.swift` and replace the placeholders:

```swift
enum SupabaseConfig {
    static let url = "https://mpuzozdhltxfcozxsawo.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wdXpvemRobHR4ZmNvenhzYXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI3MDk1NDEsImV4cCI6MjA2ODI4NTU0MX0.IGxVrzFSTcJsaPjiNQ70XQjmkiKP1--UB8dzaasF728"
}
```

### 2. How the Authentication Works

1. **Sign Up Flow**:
   - User enters email, password, and artist name
   - Creates auth user in Supabase Auth
   - Creates profile in `profiles` table
   - Automatically signs in the user

2. **Sign In Flow**:
   - User enters email and password
   - Authenticates with Supabase
   - Fetches user profile from database
   - Updates app state

3. **Logout Flow**:
   - User taps logout button in Profile tab
   - Confirmation alert appears
   - Signs out from Supabase
   - Clears local session
   - Returns to login screen

### 3. Testing Without Supabase

The app will work in mock mode if Supabase is not configured:
- Any email/password combination will work
- Data is stored locally using UserDefaults
- No real authentication happens

### 4. Features Implemented

- **Logout Button**: Located in the Profile tab (top right, red icon)
- **Session Persistence**: Users stay logged in between app launches
- **Error Handling**: Shows alerts for authentication errors
- **Loading States**: Shows progress indicators during auth operations
- **Secure Storage**: Uses Supabase's built-in session management

### 5. Next Steps

To fully integrate Supabase:
1. Create tables for collaborations, tracks, messages, etc.
2. Implement real-time features using Supabase Realtime
3. Set up storage buckets for audio files
4. Add social authentication providers

## Important Notes

- The app gracefully falls back to mock mode if Supabase is not configured
- All authentication errors are handled and displayed to the user
- The logout button is always visible in the Profile tab
- Session tokens are managed automatically by the Supabase SDK
