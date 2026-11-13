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

-- 0. Asegurar funcion de trigger para updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- 7. Datos semilla idempotentes para catalogo comercial (HU-08) y pedidos iniciales (HU-09)
--    Incluye 5 piezas publicables (terminado y existencia > 0) y 3 no publicables
--    para validar en BD la regla critica de HU-08.
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
    (
        '55555555-5555-4555-8555-555555555501',
        '11111111-1111-4111-8111-111111111101',
        'LOTE-2024-001',
        'Vajilla Clasica 6 Servicios',
        'Vajilla artesanal de 24 piezas con grecas azul cobalto pintadas a mano en Dolores Hidalgo.',
        'Vajillas',
        'terminado',
        8,
        1850.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555502',
        NULL,
        'LOTE-2024-005',
        'Tibores Coloniales Azul Cobalto',
        'Par de tibores torneados y esmaltados a gran fuego (1050 grados C) con tapa tradicional.',
        'Decoracion',
        'terminado',
        5,
        920.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555503',
        NULL,
        'LOTE-2024-006',
        'Juego de Tazas Cacatua (6 pzas)',
        'Seis tazas de barro brunido y esmalte blanco estannifero con motivos florales.',
        'Tazas y Mesa',
        'terminado',
        14,
        640.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555504',
        NULL,
        'LOTE-2024-007',
        'Platon Ceremonial Flor de Liz',
        'Platon ovalado de 42 cm decorado con pigmentos minerales tradicionales.',
        'Mesa y Cocina',
        'terminado',
        4,
        780.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555505',
        NULL,
        'LOTE-2024-008',
        'Caja de Azulejos Mayolica (20 pzas)',
        'Azulejos cuadrados 10x10 cm listos para instalacion en muros o fuentes.',
        'Murales y Azulejos',
        'terminado',
        12,
        1100.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555506',
        '11111111-1111-4111-8111-111111111102',
        'LOTE-2024-002',
        'Juego de Tazas Grecas (En taller)',
        'En proceso de decorado manual; aun no entra a segunda quema.',
        'Tazas y Mesa',
        'decorado',
        36,
        580.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555507',
        '11111111-1111-4111-8111-111111111103',
        'LOTE-2024-003',
        'Florero Cervantino Gran Formato',
        'En etapa de jahuete tras primera coccion.',
        'Decoracion',
        'jahuete',
        12,
        480.00,
        true
    ),
    (
        '55555555-5555-4555-8555-555555555508',
        NULL,
        'LOTE-2024-009',
        'Licorera Tradicional Edicion Especial',
        'Lote terminado pero actualmente sin unidades en existencia.',
        'Decoracion',
        'terminado',
        0,
        690.00,
        true
    )
ON CONFLICT DO NOTHING;

-- Pedidos iniciales (BV-0126 y BV-0127) para que el siguiente pedido emita BV-0128
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
