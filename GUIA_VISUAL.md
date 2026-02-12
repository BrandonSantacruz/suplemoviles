# 📱 GUÍA VISUAL - RESOLVER PANEL SUPERADMIN

## ¿CUÁL ES EL PROBLEMA?

```
Usuario intenta registrarse como "superadmin"
                 ↓
El rol se guarda en auth.users (✅ correcto)
                 ↓
PERO la tabla usuarios tiene rol = 'corredor' (❌ INCORRECTO)
                 ↓
Usuario intenta login
                 ↓
auth.dart consulta tabla usuarios
                 ↓
Encuentra rol = 'corredor' (❌ INCORRECTO)
                 ↓
Lo rutea a panel de corredor (❌ INCORRECTO)
                 ↓
Usuario no ve panel superadmin ❌
```

## ¿CUÁL ES LA SOLUCIÓN?

```
CREAR UN TRIGGER QUE LEA EL ROL DE auth.users Y LO COPIE A tabla usuarios

Registro → auth.users actualizado ✅
        ↓
        Trigger se ejecuta automáticamente
        ↓
        Lee: raw_user_meta_data->>'rol'
        ↓
        Inserta en tabla usuarios ✅
        ↓
Login → consulta tabla usuarios ✅
     ↓
     Encuentra rol correcto ✅
     ↓
     Navega a panel correcto ✅
```

---

## 5️⃣ PASOS ULTRA-SIMPLES

### 1️⃣ ABRIR SUPABASE

```
Abre navegador
Escribe: app.supabase.com
Inicia sesión
Selecciona tu proyecto
```

**Visual**:
```
┌─────────────────────────────────────┐
│ app.supabase.com                    │
│                                     │
│ Mis Proyectos                       │
│ [Selecciona "suplemoviles"]         │
└─────────────────────────────────────┘
```

---

### 2️⃣ VE A SQL EDITOR

```
En Supabase, menú izquierdo:
  Desarrollo → SQL Editor
```

**Visual**:
```
┌─────────────────────┐
│ DESARROLLO          │
│ ├─ SQL Editor ◄─────┤─ AQUÍ
│ ├─ Tables           │
│ ├─ Webhooks         │
│ └─ Migrations       │
└─────────────────────┘
```

---

### 3️⃣ COPIA TODO EL CONTENIDO DE SQL_SETUP.sql

```
En tu PC:
  Abre: /Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles/SQL_SETUP.sql
  Ctrl+A (selecciona todo)
  Ctrl+C (copia)
```

**Visual**:
```
┌─ SQL_SETUP.sql
│ -- ============================================
│ -- CREACIÓN DE TABLAS PARA SISTEMA DE TRACKING
│ -- ============================================
│
│ CREATE TABLE IF NOT EXISTS usuarios (
│   id UUID PRIMARY KEY REFERENCES auth.users(id),
│   ... (TODO EL SQL)
│ 
│ SELECCIONA TODO ↑
│ COPIA TODO ↑
└─ EOF
```

---

### 4️⃣ PEGA EN SUPABASE

```
En Supabase SQL Editor:
  Click en el área de texto blanca
  Ctrl+V (pega TODO)
  
Presiona el botón azul "Run" (esquina inferior derecha)

Espera... deberías ver ✅ "Success"
```

**Visual**:
```
┌──────────────────────────────────────────────┐
│ SQL Editor                                   │
│                                              │
│ -- TODO EL SQL QUE COPIASTE                 │
│ -- PEGA AQUÍ                                │
│ [Área de texto con SQL pegado]              │
│                                              │
│ [Run Button] ◄─────┬─ PRESIONA AQUÍ        │
└──────────────────────────────────────────────┘
          ↓
       ✅ Success
```

---

### 5️⃣ VERIFICA QUE EL TRIGGER EXISTE

```
En SQL Editor, copia esta línea:

SELECT trigger_name 
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_schema = 'auth';

Presiona Run
```

**Deberías ver**:
```
┌────────────────────────────────┐
│ Query Results                  │
├────────────────────────────────┤
│ trigger_name                   │
├────────────────────────────────┤
│ on_auth_user_created ✅        │
└────────────────────────────────┘
```

---

## 📱 EN TU TELÉFONO

### Paso A: Desinstala app anterior

```
Settings → Apps → BolsaStreet → Desinstalar
```

### Paso B: Instala APK nuevo

```
Descarga: build/app/outputs/flutter-apk/app-release.apk
Abre el archivo
Instala
```

### Paso C: Registra superadmin

```
Abre app
Presiona "Registrarse"

Email: superadmin@test.com
Contraseña: password123
Rol: Selecciona "Superadmin" ◄─────┬─ IMPORTANTE
Registrarse

Ver: ✅ "Cuenta creada con éxito"
```

**Visual en pantalla**:
```
┌─────────────────────────────────┐
│ REGISTRARSE                     │
├─────────────────────────────────┤
│ Email: superadmin@test.com      │
│ Contraseña: password123         │
│ Rol: [Selecciona Superadmin] ◄──┤─ AQUÍ
│      ├─ Corredor               │
│      ├─ Administrador          │
│      └─ Superadmin ✅          │
├─────────────────────────────────┤
│ [Registrarse Button]            │
└─────────────────────────────────┘
```

---

### Paso D: Verifica en Supabase

```
En SQL Editor:

SELECT email, rol FROM usuarios 
WHERE email = 'superadmin@test.com';

Presiona Run
```

**Deberías ver**:
```
┌────────────────────────────────────┐
│ Query Results                      │
├────────────────────────────────────┤
│ email                │ rol         │
├────────────────────────────────────┤
│ superadmin@test.com  │ superadmin ✅│
└────────────────────────────────────┘
```

---

### Paso E: Login

```
En app:
Presiona "Iniciar Sesión"

Email: superadmin@test.com
Contraseña: password123
Presiona "Entrar"
```

**Visual en pantalla**:
```
┌─────────────────────────────────┐
│ INICIAR SESIÓN                  │
├─────────────────────────────────┤
│ Email: superadmin@test.com      │
│ Contraseña: ••••••••••          │
├─────────────────────────────────┤
│ [Entrar Button]                 │
│                                 │
│ Loading... "Rol: superadmin"    │
│ [Spinner Animation]             │
└─────────────────────────────────┘
     ↓ Espera 2 segundos ↓
┌─────────────────────────────────┐
│ PANEL SUPERADMIN ✅             │
├─────────────────────────────────┤
│ [Mapa OSM con ubicaciones]       │
├─────────────────────────────────┤
│ Corredores en línea: 0           │
│ Corredores:                      │
│ Administradores:                │
├─────────────────────────────────┤
│ [+ Button para crear usuarios]   │
└─────────────────────────────────┘
```

---

## ✅ SI LLEGASTE AQUÍ = ¡FUNCIONA!

```
✅ Trigger existe
✅ Rol se guarda correctamente
✅ Login funciona
✅ Panel superadmin se abre
✅ LISTO PARA USAR
```

---

## ❌ SI NO FUNCIONA

### Opción 1: Ver Logs

```
Abre Terminal en VS Code
Escribe:

cd "/Users/brandonsantacruz/Downloads/Proyecto_Final_Moviles"
flutter run -v

Intenta login
Busca líneas con "DEBUG AUTH:"
Copia y comparte todo
```

### Opción 2: Verificar Manualmente

```
En SQL Editor:

-- Ver si el usuario existe
SELECT * FROM usuarios WHERE email = 'superadmin@test.com';

-- Ver si el trigger existe
SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user';

-- Ver si hay error de permisos
SELECT * FROM usuarios LIMIT 1;
```

### Opción 3: Resetear TODO

```
En SQL Editor, ejecuta:

DROP TABLE IF EXISTS ubicaciones_corredores CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

Luego vuelve a ejecutar SQL_SETUP.sql completo
```

---

## 📚 DOCUMENTACIÓN POR SI NECESITAS MÁS INFO

| Archivo | Lee si... |
|---------|-----------|
| GUIA_SOLUCION_SUPERADMIN.md | Quieres instrucciones muy detalladas |
| INSTRUCCIONES_FINALES.md | Quieres pasos paso a paso |
| DIAGRAMA_PROBLEMA_SOLUCION.md | Quieres entender qué estaba mal |
| EXPLICACION_TABLAS.md | Quieres entender la BD |
| CHECKLIST_RAPIDO.md | Quieres un checklist simple |
| RESUMEN_ESTADO.md | Quieres saber el estado del proyecto |

---

## 🎯 TIEMPO TOTAL

- Ejecutar SQL: 5 min
- Verificar trigger: 2 min
- Registrar usuario: 5 min
- Login: 3 min

**TOTAL: ~15 MINUTOS ⏱️**

---

## 🚀 ¡LISTO! 

Empieza por el paso **1️⃣ ABRIR SUPABASE** arriba. 👆

Cuando termines, tu app tendrá:
- ✅ Panel superadmin funcional
- ✅ Gestión de usuarios
- ✅ Mapa en tiempo real
- ✅ Sistema de roles completo

**¡Éxito! 🎉**
