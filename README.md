# Gather — Invitations & RSVP

A mobile-friendly, multi-user RSVP web app built with React, TypeScript, Vite, and Supabase.

## Features
- Host sign-up, login, and sign-out (Supabase Auth)
- Private host dashboard with events and guest response lists
- Invitations with four color themes, location, date/time, and description
- Copyable guest links and public invitation previews
- Guest RSVP without account: yes/maybe/no, party size, optional email and note
- Guest list totals for attending, maybe, and declined
- PostgreSQL row-level security protects private event management and guest data

## Get running
1. Install [Node.js](https://nodejs.org/) 20.19+ or 22.12+.
2. Open this folder in Terminal and run `npm install`.
3. Create a new project at [supabase.com](https://supabase.com/).
4. Open **SQL Editor**, paste `supabase/schema.sql`, and run it once on a new project.
5. In Supabase go to **Project Settings → API Keys** and copy the project URL and publishable key (use a public/publishable key, **never** a secret/service-role key).
6. Copy `.env.example` to `.env.local` and fill in the values.
7. Run `npm run dev`; visit the local URL Vite prints.
8. Register a host account. Depending on your Supabase authentication settings, confirm your email first. Then create an event, copy its invitation link and try an RSVP in a private/incognito window.

## Production setup
In **Supabase → Authentication → URL Configuration**, set Site URL to your deployed app URL and add it to Redirect URLs. Deploy as a static Vite project to Netlify or Vercel, with `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` configured in deployment environment variables. `npm run build` generates `dist/`.

URLs use hash routes (`#/invite/<slug>`) so static hosting doesn't require server-side rewrite rules.

## Security & MVP limitations
Guests can submit RSVP responses but cannot read other guests' names, email addresses, or messages. Only the owner can read their events and RSVP list. Public invitation details are available to anyone who possesses a link. RSVP responses are **append-only**, so submitting twice makes two entries, and guests cannot change or withdraw submissions in this version. An invite link functions as an unlisted public link, not a password-protected page.

Before public launch, implement bot protection/CAPTCHA, abuse moderation, rate limiting and spam prevention. Consider verified RSVP update links, invitation expiry, host editing/deleting, reminders, per-event limits, and accessible templates. Do not rely on simple client validation for security.

## Project structure
- `src/App.tsx`: host screens, authentication, events, and guest RSVP flow
- `src/styles.css`: responsive layouts/themes
- `src/supabase.ts`: Supabase client
- `supabase/schema.sql`: database schema, row-level security and safe public RPCs

## Suggested next iteration
Add editing/canceling events, duplicate-response handling, custom cover images, QR invitations, RSVP deadlines, and email invitation delivery through a server-side provider.
