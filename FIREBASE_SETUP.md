# Firebase Setup Instructions

## Deploying Firestore Security Rules

To fix the "Missing or insufficient permissions" error when posting tracks to the discover page, you need to deploy the updated Firestore security rules.

### Prerequisites
1. Install Firebase CLI if you haven't already:
   ```bash
   npm install -g firebase-tools
   ```

2. Make sure you're logged in to Firebase:
   ```bash
   firebase login
   ```

### Deploy the Rules

1. Navigate to the project directory:
   ```bash
   cd /Users/nikhiltiwari/documents/code/XCODE/Music-CoCreation-App
   ```

2. Initialize Firebase (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your project: `ai-music-prototype`
   - Use the existing `firestore.rules` file

3. Deploy the security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Alternative: Update Rules via Firebase Console

If you prefer to update the rules manually:

1. Go to the [Firebase Console](https://console.firebase.google.com)
2. Select your project: `ai-music-prototype`
3. Navigate to Firestore Database → Rules
4. Replace the existing rules with the content from `firestore.rules`
5. Click "Publish"

## Security Rules Explanation

The updated rules allow:
- **Users collection**: Users can only read/write their own data
- **Discover collection**: 
  - Any authenticated user can read tracks
  - Users can create tracks (with their uid matching artistId)
  - Users can only update/delete their own tracks
- **Public layers**: Any authenticated user can read/write

This ensures that users can post tracks to the discover page while maintaining security.
