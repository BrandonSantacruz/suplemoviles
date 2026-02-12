# Diagnóstico: Problema con Panel Superadmin

## Problema Identificado
El usuario intenta crear una cuenta con rol "superadmin", pero cuando intenta ingresar, no accede al panel superadmin.

## Posibles Causas y Soluciones

### 1. **TABLA USUARIOS NO SE ACTUALIZA CON EL ROL**
**Síntoma**: El rol se ve en Supabase Auth pero la tabla `usuarios` tiene `rol = 'corredor'`

**Causa**: Falta el trigger `handle_new_user()` que lee de `auth.users.raw_user_meta_data->>'rol'`

**Solución Implementada**:
- Agregué función `handle_new_user()` en SQL_SETUP.sql
- Esta función se ejecuta automáticamente cuando se crea un usuario en auth.users
- Copia el rol de los metadatos a la tabla usuarios

**Pasos a ejecutar en Supabase SQL Editor**:
```sql
-- 1. Ejecutar el SQL_SETUP.sql actualizado
-- 2. Verificar con esta query:
SELECT id, email, rol FROM usuarios WHERE email = 'superadmin@example.com';
```

### 2. **VERIFICAR QUE EL DROPDOWN DE REGISTRO TIENE "SUPERADMIN"**
**Estado**: ✅ El archivo `registro.dart` tiene el dropdown con la opción

### 3. **VERIFICAR QUE auth.dart RECONOCE "superadmin"**
**Estado**: ✅ El archivo `auth.dart` tiene la condición `if (rol == 'superadmin')`

### 4. **VERIFICAR QUE panel_superadmin.dart COMPILA SIN ERRORES**
**Estado**: ✅ Compilación exitosa (APK generado)

### 5. **VERIFICAR RLS POLICIES**
Las políticas actuales permiten que superadmin vea y modifique datos:
```sql
-- Superadmin debería poder ver todos los usuarios
(SELECT rol FROM usuarios WHERE id = auth.uid()) IN ('admin', 'superadmin')
```

**Potencial problema**: Si el rol no se guardó correctamente en la tabla usuarios, el RLS policy fallará.

## Checklist de Debugging

- [ ] Ejecutar SQL_SETUP.sql (versión actualizada) en Supabase
- [ ] Crear nuevo usuario con rol "superadmin" en la app
- [ ] Verificar que la tabla usuarios tiene la entrada con rol correcto
- [ ] Revisar logs de Dart en VS Code
- [ ] Verificar que `_redirigir()` en auth.dart llega a la condición superadmin
- [ ] Verificar que PanelSuperAdmin se instancia correctamente

## Cambios Realizados

1. **SQL_SETUP.sql**: Agregué función `handle_new_user()` y trigger `on_auth_user_created`
2. **panel_superadmin.dart**: Reescrito completamente con estructura limpia
3. **registro.dart**: Contiene opción "superadmin" en dropdown
4. **auth.dart**: Contiene lógica de routing para "superadmin"

## Próximos Pasos

1. Ejecutar SQL_SETUP.sql en Supabase Console
2. Crear nuevo usuario con rol "superadmin"
3. Verificar que aparece en tabla usuarios
4. Intentar login con ese usuario
5. Si aún no funciona, revisar logs de Flutter
