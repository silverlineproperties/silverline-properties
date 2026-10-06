# Silverline Properties

Static frontend + Supabase backend for the Silverline Properties community property catalogue.

## Stack
- HTML/CSS/vanilla JavaScript
- Supabase Auth (email/password)
- Supabase Postgres for properties
- Supabase Storage for public property images with staff-only upload/delete policies
- Suitable for GitHub Pages, Cloudflare Pages or another static host

## Setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In Authentication > Users, create the staff/admin account with email + password.
4. Copy that user's UUID and run:
   `insert into public.staff_members (user_id, display_name) values ('USER-UUID-HERE', 'Silverline Staff');`
5. In Supabase Project Settings/API, copy the Project URL and Publishable key.
6. Put them in `config.js` as `supabaseUrl` and `supabasePublishableKey`.
7. Upload the folder to GitHub and enable GitHub Pages.

The browser uses only the Supabase publishable key. Do NOT put a service_role/secret key in the site.

## Admin
- `/admin/login.html` — staff login
- `/admin/index.html` — staff dashboard
- `/admin/add.html` — property upload form

The database and Storage RLS policies are the actual protection. Hiding the admin link alone is not security.

## Images
The `property-images` bucket is public for serving approved listing images, but its insert/update/delete operations are restricted to staff. The bucket itself limits uploads to JPG/JPEG, PNG and WEBP at 8 MB per file.

## Notes
- The example property on the public page is kept as a visual fallback until Supabase is configured.
- Replace the placeholder Supabase URL/key in `config.js`.
- Replace any placeholder contact/job links as needed.
