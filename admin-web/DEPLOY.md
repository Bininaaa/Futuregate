# Admin Hosting Deployment

This admin panel is meant to live on a separate Firebase Hosting site so the main `futuregate.tech` domain can stay locked to the restricted landing page and `/auth/action`.

## Recommended setup

- Main site: `futuregate.tech`
- Admin site: `admin.futuregate.tech`
- Firebase Hosting site ID for admin: `avenirdz-7305d-admin`

## Repo targets

The root repo already maps Firebase Hosting targets in `.firebaserc`:

- `root` -> `avenirdz-7305d`
- `admin` -> `avenirdz-7305d-admin`

The root `firebase.json` deploys:

- `public/` to `hosting:root`
- `admin-web/public/` to `hosting:admin`

## One-time setup

Create the admin Hosting site:

```bash
firebase hosting:sites:create avenirdz-7305d-admin
```

If you choose a different site ID, remap the checked-in target:

```bash
firebase target:apply hosting admin <your-site-id>
```

## Deploy

Deploy only the admin site:

```bash
npm run deploy:hosting:admin
```

Deploy only the main restricted site:

```bash
npm run deploy:hosting:root
```

Deploy both Hosting targets:

```bash
npm run deploy:hosting:all
```

## Connect `admin.futuregate.tech`

1. Open Firebase Console.
2. Go to Hosting.
3. Open the `avenirdz-7305d-admin` site.
4. Add custom domain `admin.futuregate.tech`.
5. Copy the DNS records Firebase gives you.
6. Add those records in the DNS zone for `futuregate.tech`.
7. Wait for Firebase to verify DNS and provision SSL.

## Expected URLs

- Main restricted site: `https://futuregate.tech`
- Email action page: `https://futuregate.tech/auth/action`
- Admin login: `https://admin.futuregate.tech/login.html`
- Admin dashboard after sign-in: `https://admin.futuregate.tech/index.html`
