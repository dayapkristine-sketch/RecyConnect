# RecyConnect Firebase security

This project uses Firebase Authentication, Cloud Firestore, and Firebase
Hosting on the free plan. Firebase Storage is disabled until it is needed.

## Authentication

- Users sign in through Firebase Email/Password Authentication.
- Passwords are never stored in the Flutter app or Firestore.
- Registration sends an email-verification message.
- Password reset uses Firebase's password-reset email.
- Admin accounts must be created in Firebase Authentication and linked to a
  Firestore document with `role: "admin"` and `status: "approved"`.
- The old sample administrator credentials are no longer supported.

## Firestore access

- Users can read and edit only their own profile fields.
- Admin access is checked from the authenticated user's Firestore profile.
- New accounts cannot assign themselves the administrator role.
- Only household owners can create or cancel posts and accept offers.
- Providers can create offers only for open posts.
- Messages are readable only by their participants.
- Notifications are readable only by their recipient.
- Reports are visible to the reporter and administrators.
- Exact pickup details are protected until an offer is accepted.

The active rules are in [firestore.rules](firestore.rules). Deploy rule changes
with:

```powershell
firebase deploy --project recyconnect-mobile-app --only firestore:rules
```

## Free-plan limitation

Profile pictures and verification documents are not uploaded online while
Storage is disabled. They are retained only in the current app session.
