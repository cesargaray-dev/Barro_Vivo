-- ==============================================================================
-- BARRO VIVO - PANEL FINANCIERO, COSTO UNITARIO Y UTILIDAD (HU-07)
-- ==============================================================================
-- Criterios de Aceptacion:
--   1. Calculo del costo unitario sumando gasto materia prima + merma prorrateada.
--   2. Desglose de costos por categoria (barro, esmaltes, pigmentos, energia, merma).
--   3. Indicador de utilidad estimada enfrentando el margen contra el precio de venta.
-- ==============================================================================

-- 0. Asegurar funcion de trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Crear tabla: lotes_finanzas
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

-- Compatibilidad idempotente por si la tabla existia sin fecha_creacion
ALTER TABLE public.lotes_finanzas
    ADD COLUMN IF NOT EXISTS fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

-- 2. Indices de optimizacion
CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_lote_id ON public.lotes_finanzas(lote_id);
CREATE INDEX IF NOT EXISTS idx_lotes_finanzas_activo ON public.lotes_finanzas(activo, created_at DESC);

-- 3. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.lotes_finanzas ENABLE ROW LEVEL SECURITY;

-- 4. Politicas de Acceso RLS para usuarios autenticados
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

-- Seguridad: sin acceso anonimo (rol anon); solo usuarios autenticados.
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo finanzas" ON public.lotes_finanzas;

-- 5. Trigger de actualizacion automatica para updated_at
DROP TRIGGER IF EXISTS set_finanzas_updated_at ON public.lotes_finanzas;
CREATE TRIGGER set_finanzas_updated_at
    BEFORE UPDATE ON public.lotes_finanzas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 6. Datos semilla idempotentes (4 analisis financieros vinculados a lotes_produccion)
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
