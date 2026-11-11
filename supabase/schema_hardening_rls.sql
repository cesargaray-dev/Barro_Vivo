-- ==============================================================================
-- BARRO VIVO - ENDURECIMIENTO DE SEGURIDAD (RLS y STORAGE)
-- ==============================================================================
-- Ejecutar UNA VEZ en el SQL Editor de Supabase si tu base ya tenía los scripts
-- anteriores aplicados. Elimina el acceso anónimo (rol anon) que permitía leer y
-- escribir sin iniciar sesión y restringe Storage a usuarios autenticados.
-- Es idempotente: se puede ejecutar varias veces sin error.
--
-- Verificación posterior (SQL Editor):
--   SELECT tablename, policyname, roles FROM pg_policies
--   WHERE schemaname IN ('public','storage') AND 'anon' = ANY(roles);
--   -> debe devolver 0 filas.
-- ==============================================================================

-- 1. Quitar políticas anon de las tablas del taller
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo lotes"     ON public.lotes_produccion;
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo historial" ON public.lotes_historial_etapas;
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo finanzas"  ON public.lotes_finanzas;
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo mermas"    ON public.lotes_mermas;

-- 2. Asegurar RLS activo en todas las tablas
ALTER TABLE public.lotes_produccion       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_historial_etapas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_finanzas         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_mermas           ENABLE ROW LEVEL SECURITY;

-- 3. Storage: bucket de evidencias con límites y escritura solo autenticada
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png']
WHERE id = 'evidencias-mermas';

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
