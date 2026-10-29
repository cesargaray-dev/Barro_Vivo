-- ==============================================================================
-- BARRO VIVO - MÓDULO DE PRODUCCIÓN Y HORNO (HU-05)
-- Esquema para gestión de lotes y las 5 etapas estrictas del oficio de talavera:
-- barro_crudo -> jahuete -> esmaltado -> decorado -> terminado
-- ==============================================================================

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

-- 3. Índices para optimización de consultas
CREATE INDEX IF NOT EXISTS idx_lotes_produccion_activo ON public.lotes_produccion(activo, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_historial_lote_id ON public.lotes_historial_etapas(lote_id, fecha ASC);

-- 4. Habilitar Seguridad a Nivel de Fila (RLS)
ALTER TABLE public.lotes_produccion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_historial_etapas ENABLE ROW LEVEL SECURITY;

-- 5. Políticas RLS (Acceso para usuarios autenticados del taller)
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

-- (Opcional) Políticas de acceso anónimo para pruebas de desarrollo local si se requieren:
DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo lotes" ON public.lotes_produccion;
CREATE POLICY "Permitir acceso anon en desarrollo lotes" 
    ON public.lotes_produccion FOR ALL 
    TO anon 
    USING (true) 
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acceso anon en desarrollo historial" ON public.lotes_historial_etapas;
CREATE POLICY "Permitir acceso anon en desarrollo historial" 
    ON public.lotes_historial_etapas FOR ALL 
    TO anon 
    USING (true) 
    WITH CHECK (true);

-- 6. Trigger para actualización automática de updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_lotes_updated_at ON public.lotes_produccion;
CREATE TRIGGER set_lotes_updated_at
    BEFORE UPDATE ON public.lotes_produccion
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
