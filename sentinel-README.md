# SENTINEL — UAP Detection System
### by Nexior-Gray

Full-spectrum aerial anomaly identification and evidence capture.  
Stars · Planets · Satellites · Comets · Meteors · NEOs · Aircraft — all identified before any UAP is flagged.

---

## Free Deployment Stack

| Service | Purpose | Free Tier |
|---|---|---|
| **GitHub** | Source control + CI | Unlimited public/private repos |
| **Netlify** | Hosting + HTTPS + CDN | 100GB bandwidth, custom domain |
| **Supabase** | Auth + PostgreSQL DB | 500MB DB, 50k monthly active users |

No credit card required for any of these.

---

## Step-by-Step Setup

### 1 — Supabase Project

1. Go to [supabase.com](https://supabase.com) → **New Project**
2. Name it `sentinel`, choose a region close to your users, set a DB password
3. Once created, go to **SQL Editor → New Query**
4. Paste the entire contents of `supabase-schema.sql` and click **Run**
5. Go to **Project Settings → API** and copy:
   - **Project URL** → looks like `https://xxxxxxxxxxxx.supabase.co`
   - **anon public key** → long JWT string

### 2 — Enable Google OAuth (optional but recommended)

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project → **APIs & Services → Credentials → Create OAuth Client ID**
3. Application type: **Web application**
4. Authorised redirect URIs: `https://xxxxxxxxxxxx.supabase.co/auth/v1/callback`
5. Copy the **Client ID** and **Client Secret**
6. In Supabase → **Authentication → Providers → Google** → paste both values → Save
7. In Supabase → **Authentication → URL Configuration**:
   - Site URL: `https://YOUR-APP.netlify.app`
   - Redirect URLs: add `https://YOUR-APP.netlify.app/app.html`

### 3 — GitHub Repository

```bash
# Create a new repo at github.com, then:
git init
git add .
git commit -m "Initial SENTINEL v3 deployment"
git remote add origin https://github.com/YOUR-USERNAME/sentinel.git
git push -u origin main
```

### 4 — Netlify Deployment

1. Go to [netlify.com](https://netlify.com) → **Add new site → Import from Git**
2. Connect your GitHub account → select the `sentinel` repo
3. Build settings:
   - **Build command**: *(leave empty)*
   - **Publish directory**: `.`
4. Click **Deploy site**
5. Once deployed, go to **Site configuration → Environment variables** and add:

   | Key | Value |
   |---|---|
   | `SUPABASE_URL` | Your Supabase project URL |
   | `SUPABASE_ANON_KEY` | Your Supabase anon public key |

6. Redeploy after adding env vars

### 5 — Wire Up the Config

Open `index.html` and `app.html` and replace these two lines near the top of the `<script>` block:

```javascript
const SUPABASE_URL  = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual values. Then commit and push — Netlify auto-deploys.

> **Or** use a build-time injection script if you prefer environment variables.

### 6 — Custom Domain (optional)

In Netlify → **Domain management → Add custom domain** → follow the DNS instructions.  
HTTPS is automatic via Let's Encrypt.

---

## Project Structure

```
sentinel/
├── index.html           ← Auth page (sign in / sign up / Google OAuth)
├── app.html             ← Main scanner app (protected, requires login)
├── netlify.toml         ← Netlify redirects and security headers
├── supabase-schema.sql  ← Run once in Supabase SQL Editor
└── README.md            ← This file
```

---

## Database Schema

```
profiles
├── id                 UUID (links to auth.users)
├── username           TEXT
├── email              TEXT
├── marketing_consent  BOOLEAN  ← Nexior-Gray marketing list
└── created_at         TIMESTAMPTZ

recordings
├── id          UUID
├── user_id     UUID → profiles
├── title       TEXT
├── date        TIMESTAMPTZ
├── duration    INTEGER (seconds)
├── has_uap     BOOLEAN
├── lat/lon/alt TEXT
├── az/el       INTEGER
├── manifest    JSONB  ← full evidence chain log
└── tag_objs    JSONB  ← display tags
```

Row Level Security ensures users can **only read and write their own recordings**.

---

## Marketing Consent

When a user creates an account, they must tick:

> *"I agree to the Terms of Service and Privacy Policy, and I am happy to receive marketing emails and product updates from **Nexior-Gray**."*

This sets `marketing_consent = TRUE` in their profile row.

To export consented emails for a campaign, run this in Supabase SQL Editor using a service-role connection:

```sql
SELECT email, username, created_at
FROM   public.marketing_subscribers
ORDER  BY created_at DESC;
```

---

## OpenSky Flight Data

The flight layer calls the [OpenSky Network](https://opensky-network.org/) public API (no auth required, 400 requests/day free). If the API is unreachable, the app falls back to realistic simulated UK airspace traffic automatically.

For higher rate limits, create a free OpenSky account and add credentials to the API call in `app.html`.

---

## Local Development

Just open `index.html` in a browser — no build step required.  
For auth to work locally, add `http://localhost:PORT` to Supabase's allowed redirect URLs.

---

## Support

**Nexior-Gray** · support@nexior-gray.com
