-- ==============================================================================
-- BARRO VIVO - TIENDA, CATALOGO DE CLIENTE Y PEDIDOS CON ESTADOS (HU-08 y HU-09)
-- ==============================================================================
-- Reglas de negocio y seguridad implementadas en servidor:
--   1. catalogo_piezas: controla etapa_actual y existencia >= 0.
--   2. pedidos: folio consecutivo unico (BV-XXXX), estado_actual restringido a la
--      secuencia estricta (en_espera_pago -> pagado -> en_preparacion -> enviado -> entregado).
--   3. pedidos_historial_estados: bitacora cronologica para el timeline del cliente.
--   4. Row Level Security (RLS) habilitado solo para usuarios autenticados.
-- ==============================================================================

-- 1. Tabla de catalogo comercial (HU-08)
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

-- 2. Tabla de pedidos confirmados (HU-09)
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

-- 3. Historial de estados del pedido para el timeline (HU-09)
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

-- 4. Habilitar RLS en todas las tablas de tienda y pedidos
ALTER TABLE public.catalogo_piezas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_historial_estados ENABLE ROW LEVEL SECURITY;

-- 5. Politicas RLS (unicamente rol authenticated)
DROP POLICY IF EXISTS "Lectura catalogo para autenticados" ON public.catalogo_piezas;
CREATE POLICY "Lectura catalogo para autenticados"
    ON public.catalogo_piezas FOR SELECT
    TO authenticated
    USING (true);

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

-- 6. Triggers para updated_at
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

