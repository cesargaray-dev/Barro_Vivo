-- ==============================================================================
-- BARRO VIVO - MODULO DE PRODUCCION Y HORNO (HU-05)
-- Esquema para gestion de lotes y las 5 etapas estrictas del oficio de talavera:
-- barro_crudo -> jahuete -> esmaltado -> decorado -> terminado
-- ==============================================================================

-- 0. Asegurar funcion de trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Crear tabla principal: lotes_produccion
CREATE TABLE IF NOT EXISTS public.lotes_produccion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(100) NOT NULL,
    cantidad_piezas INTEGER NOT NULL CHECK (cantidad_piezas > 0),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    descripcion TEXT,
    etapa_actual VARCHAR(50) NOT NULL DEFAULT 'barro_crudo'
        CHECK (etapa_actual IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Crear tabla de historial: lotes_historial_etapas
CREATE TABLE IF NOT EXISTS public.lotes_historial_etapas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES public.lotes_produccion(id) ON DELETE CASCADE,
    etapa VARCHAR(50) NOT NULL
        CHECK (etapa IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')),
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Indices para optimizacion de consultas
CREATE INDEX IF NOT EXISTS idx_lotes_produccion_activo ON public.lotes_produccion(activo, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_historial_lote_id ON public.lotes_historial_etapas(lote_id, fecha ASC);

-- 4. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.lotes_produccion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_historial_etapas ENABLE ROW LEVEL SECURITY;

-- 5. Politicas RLS (Acceso para usuarios autenticados del taller)
DROP POLICY IF EXISTS "Permitir lectura para usuarios autenticados" ON public.lotes_produccion;
CREATE POLICY "Permitir lectura para usuarios autenticados"
    ON public.lotes_produccion FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion para usuarios autenticados" ON public.lotes_produccion;
CREATE POLICY "Permitir insercion para usuarios autenticados"
    ON public.lotes_produccion FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir actualizacion para usuarios autenticados" ON public.lotes_produccion;
CREATE POLICY "Permitir actualizacion para usuarios autenticados"
    ON public.lotes_produccion FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir lectura historial para usuarios autenticados" ON public.lotes_historial_etapas;
CREATE POLICY "Permitir lectura historial para usuarios autenticados"
    ON public.lotes_historial_etapas FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion historial para usuarios autenticados" ON public.lotes_historial_etapas;
CREATE POLICY "Permitir insercion historial para usuarios autenticados"
    ON public.lotes_historial_etapas FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Seguridad: se eliminan las politicas de acceso anonimo (rol anon). Solo los
-- usuarios autenticados pueden operar sobre estas tablas (ver schema_hardening_rls.sql).
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo lotes" ON public.lotes_produccion;
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo historial" ON public.lotes_historial_etapas;

-- 6. Trigger para actualizacion automatica de updated_at
DROP TRIGGER IF EXISTS set_lotes_updated_at ON public.lotes_produccion;
CREATE TRIGGER set_lotes_updated_at
    BEFORE UPDATE ON public.lotes_produccion
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 7. Datos semilla idempotentes (4 lotes de referencia en distintas etapas)
INSERT INTO public.lotes_produccion (id, codigo, cantidad_piezas, fecha_creacion, descripcion, etapa_actual, activo)
VALUES
    ('11111111-1111-4111-8111-111111111101', 'LOTE-2024-001 (Vajilla Clasica)', 60, timezone('utc'::text, now()) - interval '20 days', 'Vajilla artesanal de 6 servicios con motivos tradicionales de Dolores Hidalgo.', 'terminado', true),
    ('11111111-1111-4111-8111-111111111102', 'LOTE-2024-002 (Juego de Tazas)', 40, timezone('utc'::text, now()) - interval '12 days', 'Juego de 40 tazas decoradas a mano con grecas azul cobalto.', 'decorado', true),
    ('11111111-1111-4111-8111-111111111103', 'LOTE-2024-003 (Florero Cervantino)', 15, timezone('utc'::text, now()) - interval '5 days', 'Florero de gran formato torneado a mano.', 'jahuete', true),
    ('11111111-1111-4111-8111-111111111104', 'LOTE-2024-004 (Azulejos Mayolica)', 100, timezone('utc'::text, now()) - interval '2 days', 'Azulejos cuadrados 10x10 para mural artesanal.', 'esmaltado', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.lotes_historial_etapas (id, lote_id, etapa, fecha, notas)
VALUES
    ('22222222-2222-4222-8222-222222222101', '11111111-1111-4111-8111-111111111101', 'barro_crudo', timezone('utc'::text, now()) - interval '20 days', 'Moldeado inicial y secado a sombra.'),
    ('22222222-2222-4222-8222-222222222102', '11111111-1111-4111-8111-111111111101', 'jahuete', timezone('utc'::text, now()) - interval '15 days', 'Primera quema a 850 grados C completada.'),
    ('22222222-2222-4222-8222-222222222103', '11111111-1111-4111-8111-111111111101', 'esmaltado', timezone('utc'::text, now()) - interval '11 days', 'Inmersion en bano de esmalte blanco estannifero.'),
    ('22222222-2222-4222-8222-222222222104', '11111111-1111-4111-8111-111111111101', 'decorado', timezone('utc'::text, now()) - interval '8 days', 'Decorado con azul cobalto y oxido amarillo.'),
    ('22222222-2222-4222-8222-222222222105', '11111111-1111-4111-8111-111111111101', 'terminado', timezone('utc'::text, now()) - interval '4 days', 'Segunda quema a gran fuego (1050 grados C) aprobada.'),

    ('22222222-2222-4222-8222-222222222201', '11111111-1111-4111-8111-111111111102', 'barro_crudo', timezone('utc'::text, now()) - interval '12 days', 'Torneado y pegado de asas.'),
    ('22222222-2222-4222-8222-222222222202', '11111111-1111-4111-8111-111111111102', 'jahuete', timezone('utc'::text, now()) - interval '8 days', 'Primera coccion completada sin fracturas.'),
    ('22222222-2222-4222-8222-222222222203', '11111111-1111-4111-8111-111111111102', 'esmaltado', timezone('utc'::text, now()) - interval '5 days', 'Base blanca vitrea aplicada.'),
    ('22222222-2222-4222-8222-222222222204', '11111111-1111-4111-8111-111111111102', 'decorado', timezone('utc'::text, now()) - interval '2 days', 'En mesa de pincel fino para grecas.'),

    ('22222222-2222-4222-8222-222222222301', '11111111-1111-4111-8111-111111111103', 'barro_crudo', timezone('utc'::text, now()) - interval '5 days', 'Torneado de gran formato.'),
    ('22222222-2222-4222-8222-222222222302', '11111111-1111-4111-8111-111111111103', 'jahuete', timezone('utc'::text, now()) - interval '2 days', 'Salio de primera quema en espera de esmalte.'),

    ('22222222-2222-4222-8222-222222222401', '11111111-1111-4111-8111-111111111104', 'barro_crudo', timezone('utc'::text, now()) - interval '2 days', 'Prensado de 100 losetas 10x10.'),
    ('22222222-2222-4222-8222-222222222402', '11111111-1111-4111-8111-111111111104', 'jahuete', timezone('utc'::text, now()) - interval '1 day', 'Primera quema uniforme.'),
    ('22222222-2222-4222-8222-222222222403', '11111111-1111-4111-8111-111111111104', 'esmaltado', timezone('utc'::text, now()) - interval '12 hours', 'Banado blanco listo para trazado.')
ON CONFLICT (id) DO NOTHING;
