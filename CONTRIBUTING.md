# Contributing to RecyConnect

## Branches

- `main` is the stable integration branch.
- Do not commit feature work directly to `main`.
- Create one focused branch per task, for example:
  `feature/admin-approval`, `fix/login-profile`, or `docs/pit-report`.

```powershell
git switch main
git pull origin main
git switch -c feature/short-description
```

## Commits

Use a short, meaningful commit message:

```powershell
git add .
git commit -m "Add admin approval workflow"
git push -u origin feature/short-description
```

Do not commit passwords, service-account JSON files, `.env` files, private
keys, Firebase tokens, or generated build directories.

## Pull requests

1. Push the feature branch to GitHub.
2. Open a pull request into `main`.
3. Explain what changed and how it was tested.
4. Ask at least one teammate to review it.
5. Resolve comments and wait for the validation workflow to pass.
6. Merge the pull request only after review.

Before opening a pull request, run:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

## Recommended GitHub repository settings

The repository owner should:

- Add all team members under **Settings > Collaborators**.
- Set `main` as the default branch.
- Protect `main` and require a pull request before merging.
- Require at least one approving review.
- Require the Flutter validation workflow to pass.
- Disable force-pushes and branch deletion on `main`.
