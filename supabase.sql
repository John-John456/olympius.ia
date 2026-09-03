-- OLYMPIUS — SUPABASE DATABASE
-- Execute este arquivo no Supabase > SQL Editor.
-- Depois, no index_supabase.html, coloque a URL e a PUBLISHABLE KEY do projeto.

create extension if not exists pgcrypto;

-- ============================================================
-- PERFIS
-- ============================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text not null unique,
    xp integer not null default 0 check (xp >= 0),
    level integer not null default 1 check (level >= 1),
    badges text[] not null default array['Iniciante Olímpico']::text[],
    created_at timestamptz not null default now()
);

-- ============================================================
-- POSTS
-- ============================================================
create table if not exists public.posts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    type text not null,
    content text not null check (char_length(content) between 1 and 5000),
    likes integer not null default 0 check (likes >= 0),
    created_at timestamptz not null default now()
);

create index if not exists profiles_xp_idx on public.profiles (xp desc);
create index if not exists posts_created_at_idx on public.posts (created_at desc);

-- ============================================================
-- CRIA PERFIL AUTOMATICAMENTE APÓS CADASTRO
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    desired_username text;
begin
    desired_username := coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
        split_part(new.email, '@', 1)
    );

    insert into public.profiles (id, username)
    values (new.id, desired_username);

    return new;
exception
    when unique_violation then
        raise exception 'USERNAME_ALREADY_EXISTS';
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ============================================================
-- XP — SOMENTE O PRÓPRIO USUÁRIO PODE GANHAR XP PELO RPC
-- ============================================================
create or replace function public.add_xp(amount integer)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
    updated_profile public.profiles;
    new_xp integer;
    new_level integer;
begin
    if auth.uid() is null then
        raise exception 'NOT_AUTHENTICATED';
    end if;

    if amount is null or amount <= 0 or amount > 100 then
        raise exception 'INVALID_XP_AMOUNT';
    end if;

    update public.profiles
    set
        xp = xp + amount,
        level = floor((xp + amount)::numeric / 100)::integer + 1
    where id = auth.uid()
    returning * into updated_profile;

    if updated_profile.id is null then
        raise exception 'PROFILE_NOT_FOUND';
    end if;

    return updated_profile;
end;
$$;

-- ============================================================
-- CURTIDA
-- ============================================================
create or replace function public.like_post(post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.posts
    set likes = likes + 1
    where id = post_id;
end;
$$;

-- ============================================================
-- RLS
-- ============================================================
alter table public.profiles enable row level security;
alter table public.posts enable row level security;

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles
for select
to authenticated
using (true);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "posts_select_authenticated" on public.posts;
create policy "posts_select_authenticated"
on public.posts
for select
to authenticated
using (true);

drop policy if exists "posts_insert_self" on public.posts;
create policy "posts_insert_self"
on public.posts
for insert
to authenticated
with check (user_id = auth.uid());

-- Não damos UPDATE direto de likes/xp ao cliente.
-- XP e likes são alterados pelas funções acima.
grant select on public.profiles to authenticated;
grant select, insert on public.posts to authenticated;
grant execute on function public.add_xp(integer) to authenticated;
grant execute on function public.like_post(uuid) to authenticated;

-- ============================================================
-- POSTS INICIAIS
-- ============================================================
-- Os autores abaixo são opcionais. Para evitar depender de IDs de
-- usuários que ainda não existem, eles não são inseridos aqui.
-- O HTML mantém os dois posts originais como fallback até você
-- publicar posts reais.
