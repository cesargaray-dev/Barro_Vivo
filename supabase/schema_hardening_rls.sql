-- ==============================================================================
-- BARRO VIVO - ENDURECIMIENTO DE SEGURIDAD (RLS y STORAGE)
-- ==============================================================================
-- Ejecutar en el SQL Editor de Supabase.
-- Es idempotente y tolerante a tablas aún no creadas (no falla si alguna tabla
-- opcional como lotes_finanzas aún no existe en tu instancia).
--
-- Acciones que realiza:
--   1. Habilita RLS en todas las tablas del taller existentes.
--   2. Elimina cualquier política previa en 'public' asignada a anon o public.
--   3. Asegura política autenticada para materias_primas si quedó sin políticas.
--   4. Configura el bucket 'evidencias-mermas' (JPEG/PNG, máx. 5 MB) y restringe
--      su escritura y consulta de objetos en storage.objects a 'authenticated'.
--
-- Verificación posterior en SQL Editor (debe devolver 0 filas):
--   SELECT schemaname, tablename, policyname, roles
--   FROM pg_policies
--   WHERE (schemaname = 'public' AND ('anon' = ANY(roles) OR 'public' = ANY(roles)))
--      OR (
--          schemaname = 'storage'
--          AND tablename = 'objects'
--          AND ('anon' = ANY(roles) OR 'public' = ANY(roles))
--          AND (coalesce(qual, '') LIKE '%evidencias-mermas%'
--               OR coalesce(with_check, '') LIKE '%evidencias-mermas%')
--      );
-- ==============================================================================

DO $$
DECLARE
    tbl TEXT;
    pol RECORD;
BEGIN
    -- 1. Habilitar RLS en todas las tablas del taller que existan
    FOREACH tbl IN ARRAY ARRAY[
        'materias_primas',
        'lotes_produccion',
        'lotes_historial_etapas',
        'lotes_mermas',
        'lotes_finanzas'
    ]
    LOOP
        IF to_regclass('public.' || tbl) IS NOT NULL THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl);
        END IF;
    END LOOP;

    -- 2. Eliminar cualquier política en 'public' abierta a anon o public
    FOR pol IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND ('anon' = ANY(roles) OR 'public' = ANY(roles))
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS %I ON %I.%I;',
            pol.policyname,
            pol.schemaname,
            pol.tablename
        );
    END LOOP;

    -- 3. Garantizar que materias_primas tenga política para authenticated si existe
    IF to_regclass('public.materias_primas') IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'materias_primas'
          AND 'authenticated' = ANY(roles)
    ) THEN
        CREATE POLICY "Permitir acceso materias primas a autenticados"
            ON public.materias_primas FOR ALL
            TO authenticated
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- 4. Storage: asegurar bucket de evidencias con límites y permisos mínimos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'evidencias-mermas',
    'evidencias-mermas',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png']
)
ON CONFLICT (id) DO UPDATE
SET public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png'];

DROP POLICY IF EXISTS "Lectura publica de fotos de mermas"          ON storage.objects;
DROP POLICY IF EXISTS "Subida de fotos de mermas taller"            ON storage.objects;
DROP POLICY IF EXISTS "Actualizacion de fotos de mermas taller"     ON storage.objects;
DROP POLICY IF EXISTS "Eliminacion de fotos de mermas taller"       ON storage.objects;
DROP POLICY IF EXISTS "Lectura de fotos de mermas autenticados"     ON storage.objects;
DROP POLICY IF EXISTS "Subida de fotos de mermas autenticados"      ON storage.objects;

CREATE POLICY "Lectura de fotos de mermas autenticados"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'evidencias-mermas');

CREATE POLICY "Subida de fotos de mermas autenticados"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'evidencias-mermas');
