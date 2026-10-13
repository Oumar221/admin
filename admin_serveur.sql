alter table public.utilisateur add column if not exists derniere_activite timestamptz;

create table if not exists public.app_config (
  cle text primary key,
  valeur jsonb not null default '{}'::jsonb,
  maj timestamptz not null default now()
);
alter table public.app_config enable row level security;
drop policy if exists app_config_lecture on public.app_config;
create policy app_config_lecture on public.app_config for select to anon, authenticated using (true);

create table if not exists public.admin_message (
  id bigint generated always as identity primary key,
  cible text not null default 'tous',
  titre text not null,
  texte text not null,
  created_at timestamptz not null default now()
);
alter table public.admin_message enable row level security;
drop policy if exists admin_message_lecture on public.admin_message;
create policy admin_message_lecture on public.admin_message for select to authenticated using (true);

create or replace function public.proteger_activite() returns trigger language plpgsql set search_path to 'public' as $$
begin
  if current_user in ('authenticated','anon') and new.derniere_activite is not null and new.derniere_activite > now() + interval '5 minutes' then
    new.derniere_activite := now();
  end if;
  return new;
end $$;
drop trigger if exists proteger_activite on public.utilisateur;
create trigger proteger_activite before update on public.utilisateur for each row execute function public.proteger_activite();
