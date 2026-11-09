-- ==============================================================================
-- BARRO VIVO - REGISTRO DE MERMAS CON COSTO ESTIMADO (HU-06)
-- ==============================================================================
-- Historia: Como usuario del taller, quiero registrar las mermas de un lote con
-- su costo estimado, para conocer el costo real de la producción.
--
-- Criterios de Aceptación:
--   1. Se pueden registrar piezas perdidas indicando la etapa en la que ocurrió
--      el daño y el motivo (despostillado, rotura, etc.).
--   2. Es obligatorio poder adjuntar una evidencia fotográfica del daño al
--      registrar la merma.
--   3. El sistema calcula el costo estimado de la pérdida según los insumos
--      consumidos.
-- ==============================================================================

-- 1. Crear tabla: lotes_mermas
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

-- 4. Políticas RLS para usuarios autenticados del taller
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

-- Políticas de desarrollo local (rol anon)
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo mermas" ON public.lotes_mermas;
CREATE POLICY "Permitir acceso anon en desarrollo mermas"
    ON public.lotes_mermas FOR ALL
    TO anon
    USING (true)
    WITH CHECK (length(trim(evidencia_url)) > 0 AND cantidad_piezas > 0);

-- 5. Trigger de actualización automática para updated_at
DROP TRIGGER IF EXISTS set_mermas_updated_at ON public.lotes_mermas;
CREATE TRIGGER set_mermas_updated_at
    BEFORE UPDATE ON public.lotes_mermas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

