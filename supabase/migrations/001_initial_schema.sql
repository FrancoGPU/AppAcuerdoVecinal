-- =============================================================================
-- AcuerdoVecinal v2.0.0 - Esquema inicial en Supabase (PostgreSQL + RLS + Realtime)
-- =============================================================================

create extension if not exists pgcrypto;

-- 1. Tablas principales
create table if not exists public.condominios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  direccion text not null default '',
  codigo_invitacion text not null unique,
  admin_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  email text not null,
  nombre text not null,
  rol text not null check (rol in ('vecino', 'administrador')),
  departamento text not null default '',
  created_at timestamptz not null default now()
);

create unique index if not exists idx_perfiles_condominio_dpto_unico
  on public.perfiles (condominio_id, lower(departamento))
  where rol = 'vecino' and departamento <> '';

create table if not exists public.reglamento_articulos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  etiqueta text not null,
  resumen text not null,
  categoria text not null default 'General',
  orden int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.negociaciones (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  titulo text not null,
  categoria text not null,
  descripcion_problema text not null,
  solicitante_id uuid references auth.users(id),
  receptor_id uuid references auth.users(id),
  dpto_solicitante text not null,
  dpto_receptor text not null,
  es_anonimo boolean not null default false,
  interes_solicitante text not null default '',
  interes_receptor text not null default '',
  condiciones jsonb not null default '[]'::jsonb,
  estado_general text not null default 'enNegociacion',
  fecha_creacion timestamptz not null default now(),
  fecha_formalizacion timestamptz,
  codigo_acta text,
  firmado_solicitante boolean not null default false,
  firmado_receptor boolean not null default false,
  firma_solicitante_base64 text,
  firma_receptor_base64 text,
  updated_at timestamptz not null default now()
);

create table if not exists public.mensajes_mediador (
  id uuid primary key default gen_random_uuid(),
  negociacion_id uuid not null references public.negociaciones(id) on delete cascade,
  usuario_id uuid not null references auth.users(id) on delete cascade,
  texto text not null,
  es_usuario boolean not null default true,
  created_at timestamptz not null default now()
);

-- 2. Trigger para updated_at en negociaciones
create or replace function public.actualizar_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_negociaciones_updated_at on public.negociaciones;
create trigger trg_negociaciones_updated_at
  before update on public.negociaciones
  for each row
  execute function public.actualizar_updated_at();

-- 3. Helpers SECURITY DEFINER (evitan recursion infinita en RLS)
create or replace function public.mi_condominio_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select condominio_id
  from public.perfiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.mi_departamento()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(departamento, '')
  from public.perfiles
  where id = auth.uid()
  limit 1;
$$;

create or replace function public.es_admin_de_condominio(p_condominio_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.condominio_id = p_condominio_id
      and p.rol = 'administrador'
  );
$$;

-- 4. RPCs transaccionales de registro y validacion de invitacion
create or replace function public.buscar_condominio_por_codigo(p_codigo text)
returns table (
  id uuid,
  nombre text,
  codigo_invitacion text
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.nombre, c.codigo_invitacion
  from public.condominios c
  where upper(trim(c.codigo_invitacion)) = upper(trim(coalesce(p_codigo, '')))
  limit 1;
$$;

revoke all on function public.buscar_condominio_por_codigo(text) from public;
grant execute on function public.buscar_condominio_por_codigo(text) to anon, authenticated;

create or replace function public.registrar_admin_condominio(
  p_nombre text,
  p_email text,
  p_nombre_condominio text,
  p_direccion text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_condominio public.condominios%rowtype;
  v_perfil public.perfiles%rowtype;
  v_codigo text;
  v_intento int := 0;
begin
  if v_uid is null then
    raise exception 'Debes iniciar sesión para registrar un condominio.';
  end if;

  if exists (select 1 from public.perfiles where id = v_uid) then
    select * into v_perfil from public.perfiles where id = v_uid;
    select * into v_condominio from public.condominios where id = v_perfil.condominio_id;
    return jsonb_build_object(
      'condominio', to_jsonb(v_condominio),
      'perfil', to_jsonb(v_perfil)
    );
  end if;

  loop
    v_intento := v_intento + 1;
    v_codigo := 'AV-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4));
    exit when not exists (select 1 from public.condominios where codigo_invitacion = v_codigo);
    if v_intento > 15 then
      v_codigo := 'AV-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
      exit;
    end if;
  end loop;

  insert into public.condominios (nombre, direccion, codigo_invitacion, admin_id)
  values (
    trim(p_nombre_condominio),
    trim(coalesce(p_direccion, '')),
    v_codigo,
    v_uid
  )
  returning * into v_condominio;

  insert into public.perfiles (id, condominio_id, email, nombre, rol, departamento)
  values (
    v_uid,
    v_condominio.id,
    trim(lower(p_email)),
    trim(p_nombre),
    'administrador',
    'Administración'
  )
  returning * into v_perfil;

  insert into public.reglamento_articulos (condominio_id, etiqueta, resumen, categoria, orden)
  values
    (v_condominio.id, 'Art. 14 - Reglamento Interno (Ruidos Molestos)', 'Horario de silencio obligatorio de lunes a jueves de 10:00 p.m. a 7:00 a.m., y viernes/sábados desde la medianoche.', 'Ruido', 1),
    (v_condominio.id, 'Art. 18 - Reglamento Interno (Tenencia de Mascotas)', 'Uso obligatorio de correa en áreas comunes y responsabilidad por ladridos persistentes en balcones.', 'Mascotas', 2),
    (v_condominio.id, 'Art. 22 - Reglamento Interno (Estacionamientos)', 'Respeto estricto a las líneas demarcadas; prohibido obstruir parcialmente el acceso contiguo.', 'Cochera', 3),
    (v_condominio.id, 'Art. 27 - Reglamento Interno (Áreas Comunes y Parrillas)', 'Reserva previa con 48 horas y entrega limpia antes de las 11:00 p.m.', 'Áreas Comunes', 4),
    (v_condominio.id, 'Art. 31 - Reglamento Interno (Filtraciones y Mantenimiento)', 'Reparación compartida o asumida por el departamento origen en un plazo máximo de 7 días.', 'Otros', 5),
    (v_condominio.id, 'Criterio de Beneficio Mutuo / Buena Convivencia', 'Acuerdo voluntario sin escalar a multa de la Junta de Propietarios.', 'General', 6);

  return jsonb_build_object(
    'condominio', to_jsonb(v_condominio),
    'perfil', to_jsonb(v_perfil)
  );
end;
$$;

revoke all on function public.registrar_admin_condominio(text, text, text, text) from public;
grant execute on function public.registrar_admin_condominio(text, text, text, text) to authenticated;

create or replace function public.registrar_vecino_condominio(
  p_nombre text,
  p_email text,
  p_departamento text,
  p_codigo_invitacion text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_dpto text := trim(coalesce(p_departamento, ''));
  v_condominio public.condominios%rowtype;
  v_perfil public.perfiles%rowtype;
begin
  if v_uid is null then
    raise exception 'Debes iniciar sesión para vincular tu departamento.';
  end if;

  if v_dpto = '' then
    raise exception 'Ingresa tu número de departamento o vivienda.';
  end if;

  select *
  into v_condominio
  from public.condominios c
  where upper(trim(c.codigo_invitacion)) = upper(trim(coalesce(p_codigo_invitacion, '')))
  limit 1;

  if v_condominio.id is null then
    raise exception 'Código de invitación inválido o inexistente.';
  end if;

  if exists (select 1 from public.perfiles where id = v_uid) then
    select * into v_perfil from public.perfiles where id = v_uid;
    return jsonb_build_object(
      'condominio', to_jsonb(v_condominio),
      'perfil', to_jsonb(v_perfil)
    );
  end if;

  if exists (
    select 1
    from public.perfiles p
    where p.condominio_id = v_condominio.id
      and p.rol = 'vecino'
      and lower(p.departamento) = lower(v_dpto)
  ) then
    raise exception 'El departamento "%" ya se encuentra registrado en este condominio.', v_dpto;
  end if;

  insert into public.perfiles (id, condominio_id, email, nombre, rol, departamento)
  values (
    v_uid,
    v_condominio.id,
    trim(lower(p_email)),
    trim(p_nombre),
    'vecino',
    v_dpto
  )
  returning * into v_perfil;

  return jsonb_build_object(
    'condominio', to_jsonb(v_condominio),
    'perfil', to_jsonb(v_perfil)
  );
end;
$$;

revoke all on function public.registrar_vecino_condominio(text, text, text, text) from public;
grant execute on function public.registrar_vecino_condominio(text, text, text, text) to authenticated;

-- 5. Habilitar Row Level Security (RLS)
alter table public.condominios enable row level security;
alter table public.perfiles enable row level security;
alter table public.reglamento_articulos enable row level security;
alter table public.negociaciones enable row level security;
alter table public.mensajes_mediador enable row level security;

-- Condominios
drop policy if exists "condominios_select_miembros" on public.condominios;
create policy "condominios_select_miembros"
  on public.condominios for select
  to authenticated
  using (id = public.mi_condominio_id() or admin_id = auth.uid());

drop policy if exists "condominios_update_admin" on public.condominios;
create policy "condominios_update_admin"
  on public.condominios for update
  to authenticated
  using (public.es_admin_de_condominio(id))
  with check (public.es_admin_de_condominio(id));

-- Perfiles
drop policy if exists "perfiles_select_mismo_condominio" on public.perfiles;
create policy "perfiles_select_mismo_condominio"
  on public.perfiles for select
  to authenticated
  using (condominio_id = public.mi_condominio_id() or id = auth.uid());

drop policy if exists "perfiles_update_propio" on public.perfiles;
create policy "perfiles_update_propio"
  on public.perfiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Reglamento (lectura para el condominio, escritura solo administrador)
drop policy if exists "reglamento_select_condominio" on public.reglamento_articulos;
create policy "reglamento_select_condominio"
  on public.reglamento_articulos for select
  to authenticated
  using (condominio_id = public.mi_condominio_id());

drop policy if exists "reglamento_insert_admin" on public.reglamento_articulos;
create policy "reglamento_insert_admin"
  on public.reglamento_articulos for insert
  to authenticated
  with check (public.es_admin_de_condominio(condominio_id));

drop policy if exists "reglamento_update_admin" on public.reglamento_articulos;
create policy "reglamento_update_admin"
  on public.reglamento_articulos for update
  to authenticated
  using (public.es_admin_de_condominio(condominio_id))
  with check (public.es_admin_de_condominio(condominio_id));

drop policy if exists "reglamento_delete_admin" on public.reglamento_articulos;
create policy "reglamento_delete_admin"
  on public.reglamento_articulos for delete
  to authenticated
  using (public.es_admin_de_condominio(condominio_id));

-- Negociaciones
drop policy if exists "negociaciones_select_partes_o_admin" on public.negociaciones;
create policy "negociaciones_select_partes_o_admin"
  on public.negociaciones for select
  to authenticated
  using (
    condominio_id = public.mi_condominio_id()
    and (
      solicitante_id = auth.uid()
      or receptor_id = auth.uid()
      or lower(dpto_solicitante) = lower(public.mi_departamento())
      or lower(dpto_receptor) = lower(public.mi_departamento())
      or (
        public.es_admin_de_condominio(condominio_id)
        and (estado_general = 'formalizada' or es_anonimo = false)
      )
    )
  );

drop policy if exists "negociaciones_insert_vecino" on public.negociaciones;
create policy "negociaciones_insert_vecino"
  on public.negociaciones for insert
  to authenticated
  with check (
    condominio_id = public.mi_condominio_id()
    and solicitante_id = auth.uid()
  );

drop policy if exists "negociaciones_update_partes" on public.negociaciones;
create policy "negociaciones_update_partes"
  on public.negociaciones for update
  to authenticated
  using (
    condominio_id = public.mi_condominio_id()
    and (
      solicitante_id = auth.uid()
      or receptor_id = auth.uid()
      or lower(dpto_solicitante) = lower(public.mi_departamento())
      or lower(dpto_receptor) = lower(public.mi_departamento())
    )
  )
  with check (condominio_id = public.mi_condominio_id());

-- Mensajes privados del Mediador IA
drop policy if exists "mensajes_mediador_propios" on public.mensajes_mediador;
create policy "mensajes_mediador_propios"
  on public.mensajes_mediador for all
  to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- 6. Publicacion Realtime segura e idempotente
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'negociaciones'
    ) then
      alter publication supabase_realtime add table public.negociaciones;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reglamento_articulos'
    ) then
      alter publication supabase_realtime add table public.reglamento_articulos;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'perfiles'
    ) then
      alter publication supabase_realtime add table public.perfiles;
    end if;
  end if;
end $$;
