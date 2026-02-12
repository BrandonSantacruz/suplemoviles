# 🎯 INSTRUCCIONES FINALES - PANEL SUPERADMIN

## ✅ LO QUE YA HICE

1. ✅ Reescribí `panel_superadmin.dart` sin errores de sintaxis
2. ✅ Agregué el **trigger `handle_new_user()`** en `SQL_SETUP.sql`
3. ✅ Agregué logs de debugging detallados en `lib/auth.dart`
4. ✅ El APK compila sin errores
5. ✅ El código está en GitHub actualizado

## ❌ LO QUE AÚN NO ESTÁ HECHO

**El trigger NO está activo en tu base de datos Supabase** porque:
- Aún no ejecutaste `SQL_SETUP.sql` en Supabase
- Sin el trigger, los usuarios se crean con `rol = 'corredor'` por defecto

---

## 🚀 PASOS EXACTOS PARA SOLUCIONAR

### PASO 1: Abre Supabase
```
Ve a: https://app.supabase.com
Selecciona tu proyecto
```

### PASO 2: Abre SQL Editor
```
En el menú lateral izquierdo:
  Desarrollo → SQL Editor
```

### PASO 3: Abre SQL_SETUP.sql
```
En tu PC:
  /Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles/SQL_SETUP.sql

Abre el archivo con un editor de texto (VS Code, Notepad, etc)
Selecciona TODO el contenido (Ctrl+A o Cmd+A)
Copia (Ctrl+C o Cmd+C)
```

### PASO 4: Pega en Supabase SQL Editor
```
En Supabase SQL Editor:
  1. Click en la ventana de texto
  2. Pega todo el SQL (Cmd+V)
  3. Presiona el botón azul "Run" (o Cmd+Enter)
  
Espera a que termine (deberías ver ✅ "Success")
```

### PASO 5: Verifica que el Trigger Existe
```
En SQL Editor, ejecuta:

SELECT trigger_name 
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_schema = 'auth';

Deberías ver: ✅ on_auth_user_created
```

### PASO 6: Elimina Usuarios Anteriores (IMPORTANTE)
```
En SQL Editor, ejecuta:

DELETE FROM usuarios;
DELETE FROM ubicaciones_corredores;

Esto limpia los datos de prueba anteriores
```

### PASO 7: Reinstala la App
```
En tu teléfono:
  1. Desinstala la app anterior
  2. Instala el APK nuevo (build/app/outputs/flutter-apk/app-release.apk)
```

### PASO 8: Registra un Usuario Superadmin
```
En la app:
  1. Presiona "Registrarse"
  2. Email: superadmin@test.com
  3. Contraseña: password123
  4. Rol: Selecciona "Superadmin" del dropdown
  5. Presiona "Registrarse"
  
Deberías ver: ✅ "Cuenta creada con éxito"
```

### PASO 9: Verifica que se Guardó en la BD
```
En SQL Editor, ejecuta:

SELECT id, email, rol, activo 
FROM usuarios 
WHERE email = 'superadmin@test.com';

Deberías ver:
┌─────────┬──────────────────────┬─────────────┬────────┐
│ id      │ email                │ rol         │ activo │
├─────────┼──────────────────────┼─────────────┼────────┤
│ UUID123 │ superadmin@test.com  │ superadmin  │ true   │
└─────────┴──────────────────────┴─────────────┴────────┘

✅ IMPORTANTE: rol debe ser 'superadmin', NOT 'corredor'
```

### PASO 10: Intenta Login
```
En la app:
  1. Presiona "Iniciar Sesión"
  2. Email: superadmin@test.com
  3. Contraseña: password123
  4. Presiona "Entrar"
  
Deberías ver:
  - Pantalla de carga que dice "Rol: superadmin"
  - Luego: Panel Superadmin con:
    - Mapa arriba
    - Lista de corredores y admins abajo
    - Botón de + para crear usuarios
```

---

## 🎉 SI LLEGASTE AQUÍ = ¡FUNCIONA! 

Si ves el panel superadmin, entonces:
- ✅ El trigger funciona
- ✅ El rol se guarda correctamente
- ✅ La autenticación funciona
- ✅ La navegación funciona

---

## 🆘 SI SIGUE SIN FUNCIONAR

### Opción 1: Ver Logs de Debugging

Ejecuta en terminal:
```bash
cd "/Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles"
flutter run -v
```

Luego intenta login y busca en los logs lineas que empiezan con:
- `DEBUG AUTH:` - Información del rol
- `DEBUG PANEL:` - Información del panel
- Copia TODO lo que ves

### Opción 2: Verificar Tabla Usuarios Manualmente

En SQL Editor:
```sql
-- Ver todos los usuarios
SELECT * FROM usuarios;

-- Ver específicamente el tuyo
SELECT * FROM usuarios WHERE email = 'superadmin@test.com';

-- Ver si hay error de permisos
SELECT * FROM usuarios LIMIT 1;
```

### Opción 3: Resetear TODO (Nuclear Option)

```sql
-- CUIDADO: Esto ELIMINA TODOS LOS DATOS
DROP TABLE IF EXISTS ubicaciones_corredores CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Luego vuelve a ejecutar SQL_SETUP.sql
```

---

## 📋 RESUMEN DE CAMBIOS EN TU PROYECTO

### SQL_SETUP.sql
```diff
+ CREATE OR REPLACE FUNCTION handle_new_user()
+ RETURNS TRIGGER AS $$
+ DECLARE
+   user_rol TEXT;
+ BEGIN
+   user_rol := NEW.raw_user_meta_data->>'rol';
+   IF user_rol IS NULL OR user_rol = '' THEN
+     user_rol := 'corredor';
+   END IF;
+   INSERT INTO public.usuarios (id, email, rol, activo)
+   VALUES (NEW.id, NEW.email, user_rol, true)
+   ON CONFLICT (id) DO UPDATE SET
+     email = NEW.email,
+     rol = user_rol,
+     activo = true;
+   RETURN NEW;
+ END;
+ $$ LANGUAGE plpgsql SECURITY DEFINER;
+
+ CREATE TRIGGER on_auth_user_created
+   AFTER INSERT ON auth.users
+   FOR EACH ROW
+   EXECUTE FUNCTION handle_new_user();
```

### lib/auth.dart
```diff
  // Agregué logs detallados para ver qué rol se obtiene
  print('DEBUG AUTH: Rol recuperado: $rol (tipo: ${rol.runtimeType})');
  print('DEBUG AUTH: ¿rol == "superadmin"? ${rol == 'superadmin'}');
```

### lib/pages/panel_superadmin.dart
```diff
  // Reescrito completamente
  // - Sin errores de sintaxis
  // - Con try-catch en métodos
  // - Con logs de inicialización
```

### lib/pages/registro.dart
```diff
  // Ya tenía la opción superadmin en el dropdown
  const DropdownMenuItem(
    value: 'superadmin',
    child: Text('Superadmin'),
  ),
```

---

## 🎯 PRÓXIMO: CREAR OTROS USUARIOS PARA PRUEBAS

Una vez que superadmin funciona:

### Crear Admin:
```
Registrarse
- Email: admin@test.com
- Contraseña: password123
- Rol: "Administrador"
- Registrarse
```

### Crear Corredor 1:
```
Registrarse
- Email: corredor1@test.com
- Contraseña: password123
- Rol: "Corredor"
- Registrarse
```

### Crear Corredor 2:
```
Registrarse
- Email: corredor2@test.com
- Contraseña: password123
- Rol: "Corredor"
- Registrarse
```

Luego prueba login con cada uno para verificar que ve su panel correcto.

---

## ✅ CHECKLIST FINAL

- [ ] Ejecuté SQL_SETUP.sql en Supabase
- [ ] Verifiqué que trigger `on_auth_user_created` existe
- [ ] Registré usuario superadmin
- [ ] Verifiqué que rol = 'superadmin' en tabla usuarios
- [ ] Hice login como superadmin
- [ ] Vi el panel superadmin correctamente
- [ ] Creé usuarios admin y corredores para pruebas
- [ ] Verifiqué que cada rol ve su panel correcto

---

## 📞 SOPORTE

Si algo no funciona:
1. Revisa el archivo `GUIA_SOLUCION_SUPERADMIN.md`
2. Revisa el archivo `DIAGRAMA_PROBLEMA_SOLUCION.md`
3. Revisa los logs de Flutter con `-v`
4. Verifica manualmente que el trigger existe
5. Verifica que la tabla usuarios tiene los datos correctos

---

**¿Listo? Empieza por el PASO 1.** 🚀

Cuando todo funcione, avísame y continuamos con:
- Geolocalización en tiempo real
- Documentación final
- Revisión del código
