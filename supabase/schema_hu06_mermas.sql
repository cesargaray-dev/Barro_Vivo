-- ==============================================================================
-- BARRO VIVO - REGISTRO DE MERMAS CON COSTO ESTIMADO + STORAGE DE FOTOS (HU-06)
-- ==============================================================================
-- Instrucciones:
--   Copia y pega todo este script en el "SQL Editor" de tu proyecto en Supabase
--   y presiona "Run". Creará automáticamente:
--     1. La tabla public.lotes_mermas conectada a public.lotes_produccion(id).
--     2. El bucket público 'evidencias-mermas' en Supabase Storage.
--     3. Todas las políticas RLS de base de datos y de Storage para subir fotos.
-- ==============================================================================

-- 0. Asegurar función de trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Crear tabla: lotes_mermas (relacionada con lotes_produccion)
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

-- 2. Índices de optimización
CREATE INDEX IF NOT EXISTS idx_lotes_mermas_lote_id ON public.lotes_mermas(lote_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_mermas_etapa ON public.lotes_mermas(etapa);
CREATE INDEX IF NOT EXISTS idx_lotes_mermas_activo ON public.lotes_mermas(activo, created_at DESC);

-- 3. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.lotes_mermas ENABLE ROW LEVEL SECURITY;

-- 4. Politicas RLS para usuarios autenticados del taller (sin rol anon)
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

-- Seguridad: sin acceso anónimo (rol anon); solo usuarios autenticados.
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo mermas" ON public.lotes_mermas;

-- 5. Trigger de actualización automática para updated_at
DROP TRIGGER IF EXISTS set_mermas_updated_at ON public.lotes_mermas;
CREATE TRIGGER set_mermas_updated_at
    BEFORE UPDATE ON public.lotes_mermas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 6. SUPABASE STORAGE: BUCKET 'evidencias-mermas' PARA GUARDAR LAS FOTOS EN LA NUBE
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('evidencias-mermas', 'evidencias-mermas', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Políticas RLS en storage.objects para permitir subir y consultar las fotos
-- Permisos mínimos: el bucket es de LECTURA pública (fotos de piezas dañadas, sin
-- datos personales; la app las muestra con su URL pública) pero SOLO usuarios
-- autenticados pueden subir. Se restringe tipo (imagen) y tamaño (5 MB). No hay
-- borrado ni actualización desde la app (las evidencias son inmutables).
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png']
WHERE id = 'evidencias-mermas';

DROP POLICY IF EXISTS "Lectura publica de fotos de mermas" ON storage.objects;
DROP POLICY IF EXISTS "Actualizacion de fotos de mermas taller" ON storage.objects;
DROP POLICY IF EXISTS "Eliminacion de fotos de mermas taller" ON storage.objects;
DROP POLICY IF EXISTS "Subida de fotos de mermas taller" ON storage.objects;
DROP POLICY IF EXISTS "Lectura de fotos de mermas autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Subida de fotos de mermas autenticados" ON storage.objects;

CREATE POLICY "Lectura de fotos de mermas autenticados"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'evidencias-mermas');

CREATE POLICY "Subida de fotos de mermas autenticados"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'evidencias-mermas');

-- ==============================================================================
-- 7. DATOS SEMILLA IDEMPOTENTES DE MERMAS (HU-06)
-- ==============================================================================
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
