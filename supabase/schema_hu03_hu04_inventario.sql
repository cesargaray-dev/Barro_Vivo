-- ==============================================================================
-- BARRO VIVO - INVENTARIO DE MATERIAS PRIMAS Y ALERTAS DE STOCK MINIMO (HU-03 y HU-04)
-- ==============================================================================
-- Esquema para la tabla public.materias_primas usada por SupabaseInsumosRepository.
-- Es 100% idempotente: puede ejecutarse de forma segura multiples veces.
-- ==============================================================================

-- 0. Funcion de trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Crear tabla: public.materias_primas
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

-- 2. Indices para consultas frecuentes y alertas de stock minimo
CREATE INDEX IF NOT EXISTS idx_materias_primas_activo_nombre
    ON public.materias_primas(activo, nombre ASC);
CREATE INDEX IF NOT EXISTS idx_materias_primas_stock_alerta
    ON public.materias_primas(activo, stock_actual, stock_minimo);

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE public.materias_primas ENABLE ROW LEVEL SECURITY;

-- 4. Politicas RLS (unicamente rol authenticated)
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo materias primas" ON public.materias_primas;
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

-- 5. Trigger de actualizacion automatica para updated_at
DROP TRIGGER IF EXISTS set_materias_primas_updated_at ON public.materias_primas;
CREATE TRIGGER set_materias_primas_updated_at
    BEFORE UPDATE ON public.materias_primas
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 6. Datos semilla iniciales (incluye insumos en alerta de stock minimo para HU-04)
INSERT INTO public.materias_primas (id, nombre, unidad, stock_actual, stock_minimo, activo)
VALUES
    ('00000000-0000-4000-8000-000000000101', 'Barro negro y blanco preparado', 'kg', 180.00, 50.00, true),
    ('00000000-0000-4000-8000-000000000102', 'Esmalte blanco estannifero', 'lt', 12.00, 15.00, true),
    ('00000000-0000-4000-8000-000000000103', 'Pigmento azul cobalto mineral', 'kg', 3.50, 5.00, true),
    ('00000000-0000-4000-8000-000000000104', 'Gas LP para horno de gran fuego', 'lt', 320.00, 100.00, true),
    ('00000000-0000-4000-8000-000000000105', 'Oxido amarillo antimonio', 'kg', 8.50, 4.00, true),
    ('00000000-0000-4000-8000-000000000106', 'Barbotina de union artesanal', 'lt', 24.00, 10.00, true)
ON CONFLICT (id) DO NOTHING;

