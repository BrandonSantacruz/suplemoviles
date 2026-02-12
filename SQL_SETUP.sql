-- ============================================
-- CREACIÓN DE TABLAS PARA SISTEMA DE TRACKING
-- ============================================

-- 1. TABLA USUARIOS (ampliada)
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  rol TEXT NOT NULL DEFAULT 'corredor' CHECK (rol IN ('corredor', 'admin', 'superadmin')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Crear índice en email para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);

-- 2. TABLA UBICACIONES_CORREDORES (Geolocalización en Tiempo Real)
CREATE TABLE IF NOT EXISTS ubicaciones_corredores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  latitud DECIMAL(10, 8) NOT NULL,
  longitud DECIMAL(11, 8) NOT NULL,
  velocidad DECIMAL(5, 2) DEFAULT 0,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(usuario_id)
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_ubicaciones_timestamp ON ubicaciones_corredores(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ubicaciones_usuario ON ubicaciones_corredores(usuario_id);
CREATE INDEX IF NOT EXISTS idx_ubicaciones_usuario_timestamp ON ubicaciones_corredores(usuario_id, timestamp DESC);

-- ============================================
-- POLÍTICAS DE SEGURIDAD (RLS - Row Level Security)
-- ============================================

-- Habilitar RLS en ambas tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ubicaciones_corredores ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PARA TABLA USUARIOS
-- Los usuarios solo pueden ver su propio perfil, los admins pueden ver todos
CREATE POLICY "Usuarios pueden ver su propio perfil"
  ON usuarios FOR SELECT
  USING (
    auth.uid() = id 
    OR (SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin')
  );

CREATE POLICY "Admins pueden actualizar usuarios"
  ON usuarios FOR UPDATE
  USING ((SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin'));

CREATE POLICY "Admins pueden eliminar usuarios"
  ON usuarios FOR DELETE
  USING ((SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin'));

-- POLÍTICAS PARA TABLA UBICACIONES_CORREDORES
-- Los corredores pueden ver sus propias ubicaciones
-- Los admins pueden ver todas las ubicaciones
CREATE POLICY "Corredores ven sus propias ubicaciones"
  ON ubicaciones_corredores FOR SELECT
  USING (
    auth.uid() = usuario_id 
    OR (SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin')
  );

-- Los corredores pueden insertar sus propias ubicaciones
CREATE POLICY "Corredores pueden insertar ubicaciones"
  ON ubicaciones_corredores FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

-- Los corredores pueden actualizar sus propias ubicaciones
CREATE POLICY "Corredores pueden actualizar ubicaciones"
  ON ubicaciones_corredores FOR UPDATE
  USING (auth.uid() = usuario_id);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para manejar nuevos usuarios (crear entrada en tabla usuarios)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_rol TEXT;
BEGIN
  -- Obtener el rol de los metadatos del usuario (raw_user_meta_data)
  user_rol := NEW.raw_user_meta_data->>'rol';
  
  -- Si no hay rol definido, usar 'corredor' como default
  IF user_rol IS NULL OR user_rol = '' THEN
    user_rol := 'corredor';
  END IF;
  
  -- Insertar en la tabla usuarios
  INSERT INTO public.usuarios (id, email, rol, activo)
  VALUES (NEW.id, NEW.email, user_rol, true)
  ON CONFLICT (id) DO UPDATE SET
    email = NEW.email,
    rol = user_rol,
    activo = true;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear usuario en tabla usuarios cuando se crea en auth
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Actualizar el campo updated_at automáticamente
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para usuarios
CREATE TRIGGER trigger_usuarios_updated_at
  BEFORE UPDATE ON usuarios
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at();

-- Trigger para ubicaciones
CREATE TRIGGER trigger_ubicaciones_updated_at
  BEFORE UPDATE ON ubicaciones_corredores
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- FUNCIÓN PARA LIMPIAR UBICACIONES ANTIGUAS
-- ============================================
CREATE OR REPLACE FUNCTION limpiar_ubicaciones_antiguas()
RETURNS void AS $$
BEGIN
  DELETE FROM ubicaciones_corredores
  WHERE timestamp < NOW() - INTERVAL '6 hours';
END;
$$ LANGUAGE plpgsql;

-- Ejecutar limpieza cada 6 horas (opcional - requiere pg_cron en Supabase)
-- SELECT cron.schedule('limpiar_ubicaciones', '0 */6 * * *', 'SELECT limpiar_ubicaciones_antiguas()');

-- ============================================
-- INSERCIONES DE PRUEBA (Opcional)
-- ============================================

-- Crear usuario de prueba (admin)
-- Primero debes crear el usuario en Auth, luego insertarlo aquí
-- INSERT INTO usuarios (id, email, rol, activo) 
-- VALUES ('UUID_GENERADO', 'admin@test.com', 'admin', true);
