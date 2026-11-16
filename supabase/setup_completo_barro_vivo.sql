-- ==============================================================================
-- BARRO VIVO - SCRIPT MAESTRO DE BASE DE DATOS Y STORAGE (HU-01 a HU-09)
-- ==============================================================================
-- Instrucciones para ejecutar en Supabase:
--   1. Abre tu proyecto en Supabase -> SQL Editor -> New query.
--   2. Copia y pega TODO el contenido de este archivo.
--   3. Presiona "Run".
--
-- Caracteristicas:
--   * 100% idempotente: puede ejecutarse varias veces sin duplicar datos ni fallar.
--   * Respeta el orden exacto de llaves foraneas entre tablas.
--   * Incluye tablas de Inventario (HU-03/04), Produccion (HU-05), Mermas + Storage
--     (HU-06), Finanzas (HU-07), Catalogo y Pedidos (HU-08/09).
--   * Activa Row Level Security (RLS) unicamente para el rol 'authenticated' y
--     elimina cualquier politica abierta a 'anon' o 'public'.
--
-- Nota sobre HU-01 y HU-02 (Autenticacion y Roles):
--   Utiliza auth.users nativo de Supabase Auth con metadata {'rol': 'taller' | 'cliente'}.
--   No requiere tabla personalizada adicional.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. FUNCION COMPARTIDA DE AUDITORIA (updated_at)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- 1. MODULO DE INVENTARIO Y ALERTAS DE STOCK MINIMO (HU-03 y HU-04)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.materias_primas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(150) NOT NULL CHECK (length(trim(nombre)) > 0),
    unidad VARCHAR(10) NOT NULL DEFAULT 'kg' CHECK (unidad IN ('kg', 'lt')),
    stock_actual NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (stock_actual >= 0),
    stock_minimo NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (stock_minimo >= 0),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_materias_primas_activo_nombre
    ON public.materias_primas(activo, nombre ASC);
CREATE INDEX IF NOT EXISTS idx_materias_primas_stock_alerta
    ON public.materias_primas(activo, stock_actual, stock_minimo);

ALTER TABLE public.materias_primas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura materias primas a autenticados" ON public.materias_primas;
CREATE POLICY "Permitir lectura materias primas a autenticados"
    ON public.materias_primas FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion materias primas a autenticados" ON public.materias_primas;
CREATE POLICY "Permitir insercion materias primas a autenticados"
    ON public.materias_primas FOR INSERT
    TO authenticated
    WITH CHECK (length(trim(nombre)) > 0 AND stock_actual >= 0 AND stock_minimo >= 0);

DROP POLICY IF EXISTS "Permitir actualizacion materias primas a autenticados" ON public.materias_primas;
CREATE POLICY "Permitir actualizacion materias primas a autenticados"
    ON public.materias_primas FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (length(trim(nombre)) > 0 AND stock_actual >= 0 AND stock_minimo >= 0);

DROP TRIGGER IF EXISTS set_materias_primas_updated_at ON public.materias_primas;
CREATE TRIGGER set_materias_primas_updated_at
    BEFORE UPDATE ON public.materias_primas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.materias_primas (id, nombre, unidad, stock_actual, stock_minimo, activo)
VALUES
    ('00000000-0000-4000-8000-000000000101', 'Barro negro y blanco preparado', 'kg', 180.00, 50.00, true),
    ('00000000-0000-4000-8000-000000000102', 'Esmalte blanco estannifero', 'lt', 12.00, 15.00, true),
    ('00000000-0000-4000-8000-000000000103', 'Pigmento azul cobalto mineral', 'kg', 3.50, 5.00, true),
    ('00000000-0000-4000-8000-000000000104', 'Gas LP para horno de gran fuego', 'lt', 320.00, 100.00, true),
    ('00000000-0000-4000-8000-000000000105', 'Oxido amarillo antimonio', 'kg', 8.50, 4.00, true),
    ('00000000-0000-4000-8000-000000000106', 'Barbotina de union artesanal', 'lt', 24.00, 10.00, true)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 2. MODULO DE PRODUCCION Y HORNO - 5 ETAPAS (HU-05)
-- ------------------------------------------------------------------------------
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

CREATE TABLE IF NOT EXISTS public.lotes_historial_etapas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES public.lotes_produccion(id) ON DELETE CASCADE,
    etapa VARCHAR(50) NOT NULL
        CHECK (etapa IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')),
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_lotes_produccion_activo
    ON public.lotes_produccion(activo, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_historial_lote_id
    ON public.lotes_historial_etapas(lote_id, fecha ASC);

ALTER TABLE public.lotes_produccion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_historial_etapas ENABLE ROW LEVEL SECURITY;

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

DROP TRIGGER IF EXISTS set_lotes_updated_at ON public.lotes_produccion;
CREATE TRIGGER set_lotes_updated_at
    BEFORE UPDATE ON public.lotes_produccion
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

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

-- ------------------------------------------------------------------------------
-- 3. MODULO DE MERMAS Y STORAGE DE EVIDENCIA FOTOGRAFICA (HU-06)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.lotes_mermas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES public.lotes_produccion(id) ON DELETE CASCADE,
    lote_codigo VARCHAR(150) NOT NULL,
    etapa VARCHAR(50) NOT NULL
        CHECK (etapa IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')),
    motivo VARCHAR(100) NOT NULL
        CHECK (motivo IN (
            'despostillado',
            'rotura',
            'grieta_termica',
            'defecto_esmalte',
            'deformacion',
            'contaminacion_pigmento',
            'otro'
        )),
    cantidad_piezas INTEGER NOT NULL CHECK (cantidad_piezas > 0),
    evidencia_url TEXT NOT NULL CHECK (length(trim(evidencia_url)) > 0),
    evidencia_descripcion TEXT,
    insumos_consumidos JSONB NOT NULL DEFAULT '[]'::jsonb,
    costo_unitario_estimado NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_unitario_estimado >= 0),
    costo_total_estimado NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_total_estimado >= 0),
    observaciones TEXT,
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_lotes_mermas_lote_id ON public.lotes_mermas(lote_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_mermas_etapa ON public.lotes_mermas(etapa);
CREATE INDEX IF NOT EXISTS idx_lotes_mermas_activo ON public.lotes_mermas(activo, created_at DESC);

ALTER TABLE public.lotes_mermas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de mermas a usuarios autenticados" ON public.lotes_mermas;
CREATE POLICY "Permitir lectura de mermas a usuarios autenticados"
    ON public.lotes_mermas FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion de mermas a usuarios autenticados" ON public.lotes_mermas;
CREATE POLICY "Permitir insercion de mermas a usuarios autenticados"
    ON public.lotes_mermas FOR INSERT
    TO authenticated
    WITH CHECK (length(trim(evidencia_url)) > 0 AND cantidad_piezas > 0);

DROP POLICY IF EXISTS "Permitir actualizacion de mermas a usuarios autenticados" ON public.lotes_mermas;
CREATE POLICY "Permitir actualizacion de mermas a usuarios autenticados"
    ON public.lotes_mermas FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (length(trim(evidencia_url)) > 0 AND cantidad_piezas > 0);

DROP TRIGGER IF EXISTS set_mermas_updated_at ON public.lotes_mermas;
CREATE TRIGGER set_mermas_updated_at
    BEFORE UPDATE ON public.lotes_mermas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

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

INSERT INTO public.lotes_mermas (
    id,
    lote_id,
    lote_codigo,
    etapa,
    motivo,
    cantidad_piezas,
    evidencia_url,
    evidencia_descripcion,
    insumos_consumidos,
    costo_unitario_estimado,
    costo_total_estimado,
    observaciones,
    fecha,
    activo
)
VALUES
    (
        '33333333-3333-4333-8333-333333333301',
        '11111111-1111-4111-8111-111111111101',
        'LOTE-2024-001 (Vajilla Clasica)',
        'jahuete',
        'grieta_termica',
        4,
        'evidencia://taller/mermas/jahuete_grieta_termica_001.jpg',
        'Fotografia de 4 platos con fisura radial tras abrir el horno de bizcocho.',
        '[
          {"insumo_id":"ins_barro_pasta","nombre":"Barro negro y blanco preparado","unidad":"kg","cantidad_por_pieza":1.20,"costo_por_unidad":18.00,"costo_por_pieza":21.60,"etapa_asociada":"barro_crudo"},
          {"insumo_id":"ins_gas_jahuete","nombre":"Gas LP (1ra quema de Jahuete)","unidad":"lt","cantidad_por_pieza":0.80,"costo_por_unidad":15.00,"costo_por_pieza":12.00,"etapa_asociada":"jahuete"}
        ]'::jsonb,
        33.60,
        134.40,
        'Incremento brusco de temperatura en la zona inferior del horno.',
        timezone('utc'::text, now()) - interval '14 days',
        true
    ),
    (
        '33333333-3333-4333-8333-333333333302',
        '11111111-1111-4111-8111-111111111101',
        'LOTE-2024-001 (Vajilla Clasica)',
        'decorado',
        'despostillado',
        2,
        'evidencia://taller/mermas/decorado_despostillado_002.jpg',
        'Fotografia de detalle de borde despostillado en sopera ya esmaltada y plumeada.',
        '[
          {"insumo_id":"ins_barro_pasta","nombre":"Barro negro y blanco preparado","unidad":"kg","cantidad_por_pieza":1.20,"costo_por_unidad":18.00,"costo_por_pieza":21.60,"etapa_asociada":"barro_crudo"},
          {"insumo_id":"ins_gas_jahuete","nombre":"Gas LP (1ra quema de Jahuete)","unidad":"lt","cantidad_por_pieza":0.80,"costo_por_unidad":15.00,"costo_por_pieza":12.00,"etapa_asociada":"jahuete"},
          {"insumo_id":"ins_esmalte_blanco","nombre":"Esmalte blanco estannifero","unidad":"lt","cantidad_por_pieza":0.25,"costo_por_unidad":60.00,"costo_por_pieza":15.00,"etapa_asociada":"esmaltado"},
          {"insumo_id":"ins_pigmentos_minerales","nombre":"Pigmentos minerales (Azul cobalto y oxidos)","unidad":"kg","cantidad_por_pieza":0.08,"costo_por_unidad":150.00,"costo_por_pieza":12.00,"etapa_asociada":"decorado"}
        ]'::jsonb,
        60.60,
        121.20,
        'Roce accidental en mesa de trabajo durante el secado de pigmento cobalto.',
        timezone('utc'::text, now()) - interval '8 days',
        true
    ),
    (
        '33333333-3333-4333-8333-333333333303',
        '11111111-1111-4111-8111-111111111102',
        'LOTE-2024-002 (Juego de Tazas)',
        'esmaltado',
        'rotura',
        4,
        'evidencia://taller/mermas/esmaltado_rotura_asa_003.jpg',
        'Evidencia fotografica de asas desprendidas durante la inmersion en tina de esmalte.',
        '[
          {"insumo_id":"ins_barro_pasta","nombre":"Barro negro y blanco preparado","unidad":"kg","cantidad_por_pieza":1.20,"costo_por_unidad":18.00,"costo_por_pieza":21.60,"etapa_asociada":"barro_crudo"},
          {"insumo_id":"ins_gas_jahuete","nombre":"Gas LP (1ra quema de Jahuete)","unidad":"lt","cantidad_por_pieza":0.80,"costo_por_unidad":15.00,"costo_por_pieza":12.00,"etapa_asociada":"jahuete"},
          {"insumo_id":"ins_esmalte_blanco","nombre":"Esmalte blanco estannifero","unidad":"lt","cantidad_por_pieza":0.25,"costo_por_unidad":60.00,"costo_por_pieza":15.00,"etapa_asociada":"esmaltado"}
        ]'::jsonb,
        48.60,
        194.40,
        'Union de barbotina debil en las asas antes del bano blanco.',
        timezone('utc'::text, now()) - interval '5 days',
        true
    )
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 4. MODULO FINANCIERO, COSTO UNITARIO Y UTILIDAD (HU-07)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.lotes_finanzas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES public.lotes_produccion(id) ON DELETE CASCADE,
    lote_codigo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    etapa_actual VARCHAR(50) NOT NULL DEFAULT 'barro_crudo'
        CHECK (etapa_actual IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')),
    cantidad_piezas_iniciales INTEGER NOT NULL CHECK (cantidad_piezas_iniciales >= 0),
    piezas_mermadas INTEGER NOT NULL DEFAULT 0 CHECK (piezas_mermadas >= 0),
    gasto_materia_prima_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (gasto_materia_prima_total >= 0),
    costo_mermas_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_mermas_total >= 0),
    precio_venta_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (precio_venta_unitario >= 0),
    costo_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_unitario >= 0),
    margen_utilidad_porcentaje NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    desglose_categorias JSONB NOT NULL DEFAULT '[]'::jsonb,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.lotes_finanzas
    ADD COLUMN IF NOT EXISTS fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_lote_id ON public.lotes_finanzas(lote_id);
CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_activo ON public.lotes_finanzas(activo, created_at DESC);

ALTER TABLE public.lotes_finanzas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de finanzas a usuarios autenticados" ON public.lotes_finanzas;
CREATE POLICY "Permitir lectura de finanzas a usuarios autenticados"
    ON public.lotes_finanzas FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion de finanzas a usuarios autenticados" ON public.lotes_finanzas;
CREATE POLICY "Permitir insercion de finanzas a usuarios autenticados"
    ON public.lotes_finanzas FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir actualizacion de finanzas a usuarios autenticados" ON public.lotes_finanzas;
CREATE POLICY "Permitir actualizacion de finanzas a usuarios autenticados"
    ON public.lotes_finanzas FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP TRIGGER IF EXISTS set_finanzas_updated_at ON public.lotes_finanzas;
CREATE TRIGGER set_finanzas_updated_at
    BEFORE UPDATE ON public.lotes_finanzas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.lotes_finanzas (
    id,
    lote_id,
    lote_codigo,
    descripcion,
    etapa_actual,
    cantidad_piezas_iniciales,
    piezas_mermadas,
    gasto_materia_prima_total,
    costo_mermas_total,
    precio_venta_unitario,
    costo_unitario,
    margen_utilidad_porcentaje,
    desglose_categorias,
    fecha_creacion,
    activo
)
VALUES
    (
        '44444444-4444-4444-8444-444444444401',
        '11111111-1111-4111-8111-111111111101',
        'LOTE-2024-001 (Vajilla Clasica)',
        'Vajilla artesanal de 6 servicios con motivos tradicionales de Dolores Hidalgo.',
        'terminado',
        60,
        6,
        3600.00,
        450.00,
        180.00,
        75.00,
        58.33,
        '[
          {"categoria":"barro_pastas","monto":1260.0,"porcentaje":31.11},
          {"categoria":"esmaltes_vidriado","monto":900.0,"porcentaje":22.22},
          {"categoria":"pigmentos_decorado","monto":720.0,"porcentaje":17.78},
          {"categoria":"horneado_energia","monto":720.0,"porcentaje":17.78},
          {"categoria":"merma_prorrateada","monto":450.0,"porcentaje":11.11}
        ]'::jsonb,
        timezone('utc'::text, now()) - interval '20 days',
        true
    ),
    (
        '44444444-4444-4444-8444-444444444402',
        '11111111-1111-4111-8111-111111111102',
        'LOTE-2024-002 (Juego de Tazas)',
        'Juego de 40 tazas decoradas a mano con grecas azul cobalto.',
        'decorado',
        40,
        4,
        2160.00,
        270.00,
        150.00,
        67.50,
        55.00,
        '[
          {"categoria":"barro_pastas","monto":756.0,"porcentaje":31.11},
          {"categoria":"esmaltes_vidriado","monto":540.0,"porcentaje":22.22},
          {"categoria":"pigmentos_decorado","monto":432.0,"porcentaje":17.78},
          {"categoria":"horneado_energia","monto":432.0,"porcentaje":17.78},
          {"categoria":"merma_prorrateada","monto":270.0,"porcentaje":11.11}
        ]'::jsonb,
        timezone('utc'::text, now()) - interval '12 days',
        true
    ),
    (
        '44444444-4444-4444-8444-444444444403',
        '11111111-1111-4111-8111-111111111103',
        'LOTE-2024-003 (Florero Cervantino)',
        'Florero de gran formato torneado a mano.',
        'jahuete',
        15,
        3,
        2880.00,
        600.00,
        480.00,
        290.00,
        39.58,
        '[
          {"categoria":"barro_pastas","monto":1008.0,"porcentaje":28.97},
          {"categoria":"esmaltes_vidriado","monto":720.0,"porcentaje":20.69},
          {"categoria":"pigmentos_decorado","monto":576.0,"porcentaje":16.55},
          {"categoria":"horneado_energia","monto":576.0,"porcentaje":16.55},
          {"categoria":"merma_prorrateada","monto":600.0,"porcentaje":17.24}
        ]'::jsonb,
        timezone('utc'::text, now()) - interval '5 days',
        true
    ),
    (
        '44444444-4444-4444-8444-444444444404',
        '11111111-1111-4111-8111-111111111104',
        'LOTE-2024-004 (Azulejos Mayolica)',
        'Azulejos cuadrados 10x10 para mural artesanal.',
        'esmaltado',
        100,
        10,
        4500.00,
        500.00,
        65.00,
        55.56,
        14.53,
        '[
          {"categoria":"barro_pastas","monto":1575.0,"porcentaje":31.50},
          {"categoria":"esmaltes_vidriado","monto":1125.0,"porcentaje":22.50},
          {"categoria":"pigmentos_decorado","monto":900.0,"porcentaje":18.00},
          {"categoria":"horneado_energia","monto":900.0,"porcentaje":18.00},
          {"categoria":"merma_prorrateada","monto":500.0,"porcentaje":10.00}
        ]'::jsonb,
        timezone('utc'::text, now()) - interval '2 days',
        true
    )
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 5. MODULO DE CATALOGO COMERCIAL, CARRITO Y PEDIDOS CON ESTADOS (HU-08 y HU-09)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.catalogo_piezas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID REFERENCES public.lotes_produccion(id) ON DELETE SET NULL,
    lote_codigo VARCHAR(100) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NOT NULL DEFAULT '',
    categoria VARCHAR(80) NOT NULL DEFAULT 'General',
    etapa_actual VARCHAR(50) NOT NULL DEFAULT 'barro_crudo' CHECK (
        etapa_actual IN ('barro_crudo', 'jahuete', 'esmaltado', 'decorado', 'terminado')
    ),
    existencia INTEGER NOT NULL DEFAULT 0 CHECK (existencia >= 0),
    precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_catalogo_piezas_publicadas
    ON public.catalogo_piezas(activo, etapa_actual, existencia)
    WHERE activo = true AND etapa_actual = 'terminado' AND existencia > 0;

CREATE TABLE IF NOT EXISTS public.pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    folio VARCHAR(20) NOT NULL UNIQUE,
    numero_consecutivo INTEGER NOT NULL UNIQUE CHECK (numero_consecutivo > 0),
    cliente_email VARCHAR(200) NOT NULL,
    cliente_nombre VARCHAR(150),
    direccion_entrega TEXT,
    notas_cliente TEXT,
    estado_actual VARCHAR(30) NOT NULL DEFAULT 'en_espera_pago' CHECK (
        estado_actual IN ('en_espera_pago', 'pagado', 'en_preparacion', 'enviado', 'entregado')
    ),
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0),
    costo_envio NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
    total NUMERIC(10, 2) NOT NULL CHECK (total >= 0),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_email
    ON public.pedidos(cliente_email, numero_consecutivo DESC);

CREATE TABLE IF NOT EXISTS public.pedidos_historial_estados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
    estado VARCHAR(30) NOT NULL CHECK (
        estado IN ('en_espera_pago', 'pagado', 'en_preparacion', 'enviado', 'entregado')
    ),
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    nota TEXT
);

CREATE INDEX IF NOT EXISTS idx_pedidos_historial_pedido
    ON public.pedidos_historial_estados(pedido_id, fecha ASC);

ALTER TABLE public.catalogo_piezas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_historial_estados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura catalogo para autenticados" ON public.catalogo_piezas;
CREATE POLICY "Lectura catalogo para autenticados"
    ON public.catalogo_piezas FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Insercion catalogo para autenticados" ON public.catalogo_piezas;
CREATE POLICY "Insercion catalogo para autenticados"
    ON public.catalogo_piezas FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Actualizacion catalogo para autenticados" ON public.catalogo_piezas;
CREATE POLICY "Actualizacion catalogo para autenticados"
    ON public.catalogo_piezas FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Lectura pedidos para autenticados" ON public.pedidos;
CREATE POLICY "Lectura pedidos para autenticados"
    ON public.pedidos FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Insercion pedidos para autenticados" ON public.pedidos;
CREATE POLICY "Insercion pedidos para autenticados"
    ON public.pedidos FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Actualizacion pedidos para autenticados" ON public.pedidos;
CREATE POLICY "Actualizacion pedidos para autenticados"
    ON public.pedidos FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Lectura historial pedidos autenticados" ON public.pedidos_historial_estados;
CREATE POLICY "Lectura historial pedidos autenticados"
    ON public.pedidos_historial_estados FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Insercion historial pedidos autenticados" ON public.pedidos_historial_estados;
CREATE POLICY "Insercion historial pedidos autenticados"
    ON public.pedidos_historial_estados FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP TRIGGER IF EXISTS set_catalogo_updated_at ON public.catalogo_piezas;
CREATE TRIGGER set_catalogo_updated_at
    BEFORE UPDATE ON public.catalogo_piezas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_pedidos_updated_at ON public.pedidos;
CREATE TRIGGER set_pedidos_updated_at
    BEFORE UPDATE ON public.pedidos
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.catalogo_piezas (
    id,
    lote_id,
    lote_codigo,
    nombre,
    descripcion,
    categoria,
    etapa_actual,
    existencia,
    precio_unitario,
    activo
)
VALUES
    ('55555555-5555-4555-8555-555555555501', '11111111-1111-4111-8111-111111111101', 'LOTE-2024-001', 'Vajilla Clasica 6 Servicios', 'Vajilla artesanal de 24 piezas con grecas azul cobalto pintadas a mano en Dolores Hidalgo.', 'Vajillas', 'terminado', 8, 1850.00, true),
    ('55555555-5555-4555-8555-555555555502', NULL, 'LOTE-2024-005', 'Tibores Coloniales Azul Cobalto', 'Par de tibores torneados y esmaltados a gran fuego (1050 grados C) con tapa tradicional.', 'Decoracion', 'terminado', 5, 920.00, true),
    ('55555555-5555-4555-8555-555555555503', NULL, 'LOTE-2024-006', 'Juego de Tazas Cacatua (6 pzas)', 'Seis tazas de barro brunido y esmalte blanco estannifero con motivos florales.', 'Tazas y Mesa', 'terminado', 14, 640.00, true),
    ('55555555-5555-4555-8555-555555555504', NULL, 'LOTE-2024-007', 'Platon Ceremonial Flor de Liz', 'Platon ovalado de 42 cm decorado con pigmentos minerales tradicionales.', 'Mesa y Cocina', 'terminado', 4, 780.00, true),
    ('55555555-5555-4555-8555-555555555505', NULL, 'LOTE-2024-008', 'Caja de Azulejos Mayolica (20 pzas)', 'Azulejos cuadrados 10x10 cm listos para instalacion en muros o fuentes.', 'Murales y Azulejos', 'terminado', 12, 1100.00, true),
    ('55555555-5555-4555-8555-555555555506', '11111111-1111-4111-8111-111111111102', 'LOTE-2024-002', 'Juego de Tazas Grecas (En taller)', 'En proceso de decorado manual; aun no entra a segunda quema.', 'Tazas y Mesa', 'decorado', 36, 580.00, true),
    ('55555555-5555-4555-8555-555555555507', '11111111-1111-4111-8111-111111111103', 'LOTE-2024-003', 'Florero Cervantino Gran Formato', 'En etapa de jahuete tras primera coccion.', 'Decoracion', 'jahuete', 12, 480.00, true),
    ('55555555-5555-4555-8555-555555555508', NULL, 'LOTE-2024-009', 'Licorera Tradicional Edicion Especial', 'Lote terminado pero actualmente sin unidades en existencia.', 'Decoracion', 'terminado', 0, 690.00, true)
ON CONFLICT DO NOTHING;

INSERT INTO public.pedidos (
    id,
    folio,
    numero_consecutivo,
    cliente_email,
    cliente_nombre,
    direccion_entrega,
    estado_actual,
    items,
    subtotal,
    costo_envio,
    total,
    fecha_creacion
)
VALUES
    (
        '66666666-6666-4666-8666-666666666126',
        'BV-0126',
        126,
        'cliente@barrovivo.test',
        'Ana Sofia Mendez',
        'Av. Juarez 412, Centro, Guanajuato, Gto.',
        'entregado',
        '[
          {"pieza_id":"55555555-5555-4555-8555-555555555501","lote_codigo":"LOTE-2024-001","nombre_pieza":"Vajilla Clasica 6 Servicios","cantidad":1,"precio_unitario":1850.00,"subtotal":1850.00}
        ]'::jsonb,
        1850.00,
        0.00,
        1850.00,
        timezone('utc'::text, now()) - interval '9 days'
    ),
    (
        '66666666-6666-4666-8666-666666666127',
        'BV-0127',
        127,
        'cliente@barrovivo.test',
        'Ana Sofia Mendez',
        'Av. Juarez 412, Centro, Guanajuato, Gto.',
        'en_preparacion',
        '[
          {"pieza_id":"55555555-5555-4555-8555-555555555502","lote_codigo":"LOTE-2024-005","nombre_pieza":"Tibores Coloniales Azul Cobalto","cantidad":1,"precio_unitario":920.00,"subtotal":920.00},
          {"pieza_id":"55555555-5555-4555-8555-555555555503","lote_codigo":"LOTE-2024-006","nombre_pieza":"Juego de Tazas Cacatua (6 pzas)","cantidad":1,"precio_unitario":640.00,"subtotal":640.00}
        ]'::jsonb,
        1560.00,
        0.00,
        1560.00,
        timezone('utc'::text, now()) - interval '2 days'
    )
ON CONFLICT DO NOTHING;

INSERT INTO public.pedidos_historial_estados (id, pedido_id, estado, fecha, nota)
SELECT v.id, v.pedido_id, v.estado, v.fecha, v.nota
FROM (
    VALUES
        ('77777777-7777-4777-8777-777777777101'::uuid, '66666666-6666-4666-8666-666666666126'::uuid, 'en_espera_pago', timezone('utc'::text, now()) - interval '9 days', NULL),
        ('77777777-7777-4777-8777-777777777102'::uuid, '66666666-6666-4666-8666-666666666126'::uuid, 'pagado', timezone('utc'::text, now()) - interval '8 days', NULL),
        ('77777777-7777-4777-8777-777777777103'::uuid, '66666666-6666-4666-8666-666666666126'::uuid, 'en_preparacion', timezone('utc'::text, now()) - interval '7 days', NULL),
        ('77777777-7777-4777-8777-777777777104'::uuid, '66666666-6666-4666-8666-666666666126'::uuid, 'enviado', timezone('utc'::text, now()) - interval '6 days', 'Guia de paqueteria artesanal asignada.'),
        ('77777777-7777-4777-8777-777777777105'::uuid, '66666666-6666-4666-8666-666666666126'::uuid, 'entregado', timezone('utc'::text, now()) - interval '4 days', 'Recibido por el cliente.'),
        ('77777777-7777-4777-8777-777777777201'::uuid, '66666666-6666-4666-8666-666666666127'::uuid, 'en_espera_pago', timezone('utc'::text, now()) - interval '2 days', 'Pedido confirmado en tienda.'),
        ('77777777-7777-4777-8777-777777777202'::uuid, '66666666-6666-4666-8666-666666666127'::uuid, 'pagado', timezone('utc'::text, now()) - interval '42 hours', 'Pago verificado por el taller.'),
        ('77777777-7777-4777-8777-777777777203'::uuid, '66666666-6666-4666-8666-666666666127'::uuid, 'en_preparacion', timezone('utc'::text, now()) - interval '10 hours', 'Empacando piezas con proteccion acolchada.')
) AS v(id, pedido_id, estado, fecha, nota)
WHERE EXISTS (
    SELECT 1 FROM public.pedidos p WHERE p.id = v.pedido_id
)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 6. ENDURECIMIENTO DE SEGURIDAD (ELIMINAR POLITICAS ANON/PUBLIC EN PUBLIC)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    pol RECORD;
BEGIN
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
END $$;

