-- ==============================================================================
-- BARRO VIVO - PANEL FINANCIERO, COSTO UNITARIO Y UTILIDAD (HU-07)
-- ==============================================================================
-- Criterios de Aceptación:
--   1. Cálculo del costo unitario sumando gasto materia prima + merma prorrateada.
--   2. Desglose de costos por categoría (barro, esmaltes, pigmentos, energía, merma).
--   3. Indicador de utilidad estimada enfrentando el margen contra el precio de venta.
-- ==============================================================================

-- 1. Crear tabla: lotes_finanzas
CREATE TABLE IF NOT EXISTS public.lotes_finanzas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id UUID NOT NULL REFERENCES public.lotes_produccion(id) ON DELETE CASCADE,
    lote_codigo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    etapa_actual VARCHAR(50) NOT NULL DEFAULT 'barro_crudo',
    cantidad_piezas_iniciales INTEGER NOT NULL CHECK (cantidad_piezas_iniciales >= 0),
    piezas_mermadas INTEGER NOT NULL DEFAULT 0 CHECK (piezas_mermadas >= 0),
    gasto_materia_prima_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (gasto_materia_prima_total >= 0),
    costo_mermas_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_mermas_total >= 0),
    precio_venta_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (precio_venta_unitario >= 0),
    costo_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo_unitario >= 0),
    margen_utilidad_porcentaje NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    desglose_categorias JSONB NOT NULL DEFAULT '[]'::jsonb,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Índices de optimización
CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_lote_id ON public.lotes_finanzas(lote_id);
CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_activo ON public.lotes_finanzas(activo, created_at DESC);

-- 3. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.lotes_finanzas ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de Acceso RLS para usuarios autenticados
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

-- Políticas de desarrollo local (rol anon)
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo finanzas" ON public.lotes_finanzas;
CREATE POLICY "Permitir acceso anon en desarrollo finanzas"
    ON public.lotes_finanzas FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- 5. Trigger de actualización automática para updated_at
DROP TRIGGER IF EXISTS set_finanzas_updated_at ON public.lotes_finanzas;
CREATE TRIGGER set_finanzas_updated_at
    BEFORE UPDATE ON public.lotes_finanzas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
