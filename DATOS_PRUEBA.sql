-- ============================================
-- SCRIPT DE DATOS DE PRUEBA
-- ============================================
-- Este script crea usuarios de prueba para testing
-- Ejecutar DESPUÉS de haber creado los usuarios en Authentication

-- NOTA: Los UUIDs deben coincidir con los que cree Supabase en la tabla auth.users
-- Reemplaza los UUIDs con los reales de tu Supabase

-- ============================================
-- USUARIOS DE PRUEBA
-- ============================================

-- Admin (gerencia la aplicación)
INSERT INTO usuarios (id, email, rol, activo)
VALUES (
  '00000000-0000-0000-0000-000000000001',  -- Reemplazar con UUID real
  'admin@ejemplo.com',
  'admin',
  true
) ON CONFLICT (id) DO NOTHING;

-- Corredor 1
INSERT INTO usuarios (id, email, rol, activo)
VALUES (
  '00000000-0000-0000-0000-000000000002',  -- Reemplazar con UUID real
  'corredor1@ejemplo.com',
  'corredor',
  true
) ON CONFLICT (id) DO NOTHING;

-- Corredor 2
INSERT INTO usuarios (id, email, rol, activo)
VALUES (
  '00000000-0000-0000-0000-000000000003',  -- Reemplazar con UUID real
  'corredor2@ejemplo.com',
  'corredor',
  true
) ON CONFLICT (id) DO NOTHING;

-- Corredor 3
INSERT INTO usuarios (id, email, rol, activo)
VALUES (
  '00000000-0000-0000-0000-000000000004',  -- Reemplazar con UUID real
  'corredor3@ejemplo.com',
  'corredor',
  true
) ON CONFLICT (id) DO NOTHING;


-- ============================================
-- UBICACIONES DE PRUEBA (Quito, Ecuador)
-- ============================================

-- Ubicación para Corredor 1 (Centro de Quito)
INSERT INTO ubicaciones_corredores (usuario_id, latitud, longitud, velocidad, timestamp)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  -0.278233,
  -78.496129,
  3.5,
  now()
) ON CONFLICT (usuario_id) DO UPDATE SET
  latitud = EXCLUDED.latitud,
  longitud = EXCLUDED.longitud,
  velocidad = EXCLUDED.velocidad,
  timestamp = EXCLUDED.timestamp;

-- Ubicación para Corredor 2 (Sur de Quito)
INSERT INTO ubicaciones_corredores (usuario_id, latitud, longitud, velocidad, timestamp)
VALUES (
  '00000000-0000-0000-0000-000000000003',
  -0.320000,
  -78.500000,
  2.1,
  now()
) ON CONFLICT (usuario_id) DO UPDATE SET
  latitud = EXCLUDED.latitud,
  longitud = EXCLUDED.longitud,
  velocidad = EXCLUDED.velocidad,
  timestamp = EXCLUDED.timestamp;

-- Ubicación para Corredor 3 (Norte de Quito)
INSERT INTO ubicaciones_corredores (usuario_id, latitud, longitud, velocidad, timestamp)
VALUES (
  '00000000-0000-0000-0000-000000000004',
  -0.200000,
  -78.490000,
  4.2,
  now()
) ON CONFLICT (usuario_id) DO UPDATE SET
  latitud = EXCLUDED.latitud,
  longitud = EXCLUDED.longitud,
  velocidad = EXCLUDED.velocidad,
  timestamp = EXCLUDED.timestamp;

-- ============================================
-- VERIFICACIÓN DE DATOS
-- ============================================

-- Ver todos los usuarios creados
SELECT id, email, rol, activo, created_at FROM usuarios ORDER BY created_at DESC;

-- Ver todas las ubicaciones
SELECT 
  u.email as corredor,
  uc.latitud,
  uc.longitud,
  uc.velocidad,
  uc.timestamp
FROM ubicaciones_corredores uc
JOIN usuarios u ON uc.usuario_id = u.id
ORDER BY uc.timestamp DESC;

-- Contar corredores activos
SELECT COUNT(*) as corredores_activos FROM usuarios WHERE rol = 'corredor' AND activo = true;

-- Ver corredores con ubicación reciente (últimos 5 minutos)
SELECT 
  u.email,
  uc.latitud,
  uc.longitud,
  uc.velocidad,
  EXTRACT(EPOCH FROM (now() - uc.timestamp)) as segundos_atras
FROM ubicaciones_corredores uc
JOIN usuarios u ON uc.usuario_id = u.id
WHERE uc.timestamp > now() - INTERVAL '5 minutes'
ORDER BY uc.timestamp DESC;

-- ============================================
-- LIMPIEZA DE DATOS DE PRUEBA (SI ES NECESARIO)
-- ============================================

-- Eliminar todas las ubicaciones de prueba
-- DELETE FROM ubicaciones_corredores;

-- Eliminar todos los usuarios de prueba
-- DELETE FROM usuarios WHERE email LIKE '%@ejemplo.com' OR email LIKE '%@test.com';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
/*
1. Los UUIDs (00000000-0000-0000-0000-000000000001, etc.) 
   DEBEN SER reemplazados con los UUIDs reales que genera Supabase 
   cuando creas usuarios en la tabla auth.users

2. Para obtener los UUIDs reales:
   - Ve a Supabase Dashboard → Authentication → Users
   - Copia el ID de cada usuario
   - Reemplaza en este script

3. Las coordenadas de prueba están en Quito, Ecuador:
   - Centro: -0.278233, -78.496129
   - Se pueden ajustar según tu zona de prueba

4. Las velocidades son en m/s (metros por segundo)
   - 3.5 m/s = 12.6 km/h (trote lento)
   - 4.2 m/s = 15.1 km/h (trote rápido)

5. El timestamp usa 'now()' que genera la hora del servidor
   - Se actualiza cada vez que se ejecuta el script

6. Los campos de velocidad son solo de demostración
   - En producción se calculan automáticamente desde GPS
*/
