# Firestore Troubleshooting Guide - PDF Leaflets

## Overview
This guide will help you troubleshoot why your PDF leaflets are not appearing in the app.

## Step 1: Use the Debug Page
I've created a debug page that you can access by:
1. Running the app
2. Going to the "Leaflet Informasi Gizi" page
3. Clicking the red bug icon (🔧) in the bottom right corner

The debug page will show you:
- Firebase initialization status
- Firestore connection status
- All documents in the 'leaflets' collection
- Any permission errors
- Allow you to add test documents

## Step 2: Check Firestore Collection Structure

### Expected Collection Name
```
Collection: "leaflets"
```

### Expected Document Fields
Each document should have these fields:
- `title` (string) - Title of the leaflet
- `description` (string) - Description of the leaflet
- `url` (string) - URL to the PDF file
- `createdAt` (timestamp) - Optional creation date

### Example Document
```json
{
  "title": "Panduan Gizi Seimbang",
  "description": "Leaflet tentang prinsip-prinsip gizi seimbang untuk keluarga",
  "url": "https://your-domain.com/pdfs/gizi-seimbang.pdf",
  "createdAt": "2024-08-24T10:00:00Z"
}
```

## Step 3: Check Firestore Rules

### Required Firestore Rules
Go to Firebase Console → Firestore Database → Rules and ensure you have:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to leaflets collection
    match /leaflets/{leaflet} {
      allow read: if true; // Allow all users to read
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```

## Step 4: Common Issues and Solutions

### Issue 1: No Documents Found
**Symptoms:** "Belum ada leaflet tersedia" message appears
**Solutions:**
1. Check if the 'leaflets' collection exists in Firestore
2. Add at least one test document using the debug page
3. Verify collection name is exactly "leaflets" (case-sensitive)

### Issue 2: Permission Denied
**Symptoms:** Error message about permissions
**Solutions:**
1. Update Firestore rules as shown above
2. Wait 1-2 minutes for rules to propagate
3. Check if you're using the correct Firebase project

### Issue 3: Invalid Field Names
**Symptoms:** Documents found but not displaying correctly
**Solutions:**
1. Ensure field names match exactly: `title`, `description`, `url`
2. Check for typos in field names
3. Verify data types (all should be strings except `createdAt`)

### Issue 4: Firebase Not Initialized
**Symptoms:** App crashes or shows initialization errors
**Solutions:**
1. Check if `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is properly configured
2. Verify Firebase project setup in `firebase_options.dart`

## Step 5: Manual Testing Steps

### Using Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Firestore Database
4. Create a new collection called "leaflets"
5. Add a document with these fields:
   - title: "Test Leaflet 1"
   - description: "This is a test leaflet"
   - url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"

### Using Debug Page
1. Open the debug page (bug icon)
2. Click "Add Test Doc" to add a test document
3. Click "Refresh Data" to see if documents appear
4. Check the debug output for any errors

## Step 6: Verify Your Setup

### Checklist
- [ ] Firebase project is properly configured
- [ ] Firestore database is in production mode (not test mode)
- [ ] Collection "leaflets" exists
- [ ] At least one document exists in the collection
- [ ] Firestore rules allow read access
- [ ] App has internet connection
- [ ] No typos in collection or field names

### Debug Commands
You can also test directly in your browser console:
1. Open Firebase Console
2. Go to Firestore Database
3. Click on "leaflets" collection
4. Verify documents appear

## Step 7: Next Steps

If you've completed all steps above and still have issues:

1. **Check the debug page output** - it will show exact error messages
2. **Verify your Firebase configuration** - ensure you're using the correct project
3. **Check network connectivity** - ensure your device/emulator has internet
4. **Review app logs** - look for any Firebase-related error messages in the console

## Quick Fix Script

If you want to quickly test, run this in your browser console (after going to Firebase Console → Firestore):

```javascript
// Add test document
db.collection('leaflets').add({
  title: 'Test Leaflet',
  description: 'This is a test document',
  url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  createdAt: new Date()
});
```

## Support

If you're still experiencing issues after following this guide:
1. Take a screenshot of the debug page output
2. Check the browser console for any error messages
3. Verify your Firebase project configuration matches the app