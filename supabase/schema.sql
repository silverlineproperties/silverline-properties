-- Silverline Properties backend
-- Run this in the Supabase SQL Editor.
-- Then create your staff user in Supabase Authentication > Users and insert that user's UUID below.

create extension if not exists pgcrypto;

create table if not exists public.staff_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 120),
  price numeric(12,2) not null check (price >= 0),
  currency text not null default '$' check (currency in ('$', '£')),
  description text not null check (char_length(trim(description)) between 1 and 5000),
  image_urls text[] not null default '{}',
  published boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists properties_created_at_idx on public.properties(created_at desc);

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.staff_members
    where user_id = auth.uid() and active = true
  );
$$;

alter table public.staff_members enable row level security;
alter table public.properties enable row level security;

revoke all on table public.staff_members from anon, authenticated;
revoke all on table public.properties from anon, authenticated;
grant select on table public.properties to anon;
grant select on table public.properties to authenticated;
grant insert, update, delete on table public.properties to authenticated;

-- Staff can see their own staff row. The is_staff() function above is used by the other policies.
drop policy if exists "Staff can view own staff record" on public.staff_members;
create policy "Staff can view own staff record"
on public.staff_members for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Public can view published properties" on public.properties;
create policy "Public can view published properties"
on public.properties for select to anon
using (published = true);

drop policy if exists "Authenticated can view published properties" on public.properties;
create policy "Authenticated can view published properties"
on public.properties for select to authenticated
using (published = true or public.is_staff());

drop policy if exists "Staff can create properties" on public.properties;
create policy "Staff can create properties"
on public.properties for insert to authenticated
with check (public.is_staff() and created_by = auth.uid());

drop policy if exists "Staff can update properties" on public.properties;
create policy "Staff can update properties"
on public.properties for update to authenticated
using (public.is_staff())
with check (public.is_staff());

drop policy if exists "Staff can delete properties" on public.properties;
create policy "Staff can delete properties"
on public.properties for delete to authenticated
using (public.is_staff());

-- Public property images. Retrieval is public, but uploads/deletes are staff-only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('property-images', 'property-images', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Staff can upload property images" on storage.objects;
create policy "Staff can upload property images"
on storage.objects for insert to authenticated
with check (bucket_id = 'property-images' and public.is_staff());

drop policy if exists "Staff can update property images" on storage.objects;
create policy "Staff can update property images"
on storage.objects for update to authenticated
using (bucket_id = 'property-images' and public.is_staff())
with check (bucket_id = 'property-images' and public.is_staff());

drop policy if exists "Staff can delete property images" on storage.objects;
create policy "Staff can delete property images"
on storage.objects for delete to authenticated
using (bucket_id = 'property-images' and public.is_staff());
