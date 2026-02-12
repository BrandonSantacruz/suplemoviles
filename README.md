# 📍 GeoTrack – Sistema de Tracking de Corredores

Aplicación móvil que permite rastrear en **tiempo real** la ubicación de un grupo de corredores, con panel de administración para gestionar usuarios y ver el tracking en vivo.

## 🎯 Objetivo Principal
Implementar una solución que permita trackear en tiempo real la ubicación de un grupo de corredores, donde cada usuario pueda ver dónde se encuentran sus demás compañeros corredores, con un panel administrativo para gestionar usuarios.

## 📊 Puntuación del Proyecto

| Requisito | Puntos | Estado |
|-----------|--------|--------|
| **Login para validación de usuarios** | 10 | ✅ |
| **Sistema de administración web** | 20 | ✅ |
| **Geolocalización en tiempo real** | 50 | ✅ |
| **TOTAL** | **80** | ✅ **COMPLETADO** |

---

## 👥 Roles de Usuario

### 🏃 Corredor
- Inicia sesión con sus credenciales
- Automáticamente se activa el rastreo GPS
- Puede ver a otros corredores en tiempo real en un mapa
- Ver detalles de ubicación (lat, lng, velocidad)
- Acceso a links de geolocalización en OpenStreetMap

### 👨‍💼 Administrador
- Gestión completa de corredores:
  - ✅ **Agregar corredores** (via registro/login)
  - ✅ **Eliminar corredores** (con confirmación)
  - ✅ **Desactivar corredores** (cambiar estado)
  - ✅ **Ver tracking en vivo** (mapa interactivo)
- Panel con 2 tabs:
  - Tab 1: Gestionar Corredores (lista, acciones)
  - Tab 2: Tracking en Vivo (mapa en tiempo real)

### 👑 SuperAdmin
- Acceso total a todas las funciones
- Administración completa de usuarios



---

## ✨ Características Implementadas

### 1️⃣ Login con Validación (10 pts)
```
✅ Autenticación con Supabase
✅ Validación de credenciales
✅ 3 roles diferentes (corredor, admin, superadmin)
✅ Redirección automática según rol
```

**Ubicación:** `lib/auth.dart`, `lib/pages/login.dart`

### 2️⃣ Sistema de Administración Web (20 pts)
```
✅ AGREGAR USUARIOS (corredores, admins, superadmins)
   └─ Sistema de registro/login automático

✅ ELIMINAR USUARIOS  
   └─ Confirmación de seguridad
   └─ Eliminación de base de datos

✅ DESACTIVAR USUARIOS
   └─ Cambio de estado sin eliminar
   └─ Reactivación permitida

✅ VER TRACKING EN VIVO
   └─ Mapa interactivo CartoDB
   └─ Actualización cada 3 segundos
   └─ Contador de usuarios activos
   └─ Marcadores visuales diferenciados
   └─ Ubicación propia con icono especial
```

**Ubicación:** `lib/pages/admin_corredores.dart`, `lib/pages/tracking_corredores.dart`

### 3️⃣ Geolocalización en Tiempo Real (50 pts)
```
✅ RASTREO CONTINUO
   └─ GPS activado automáticamente
   └─ Actualización cada 10 metros O 5 segundos
   └─ Precisión: Alta (±5-10m)

✅ OPENSTREETMAP
   └─ Integración con Flutter Map
   └─ Marcadores de ubicación
   └─ Zoom automático

✅ LINKS OSM AUTOMÁTICOS
   └─ Generación automática de URLs
   └─ Formato: https://www.openstreetmap.org/?mlat=X&mlon=Y&zoom=15
   └─ Clickeables en detalles de corredor

✅ VELOCIDAD CALCULADA
   └─ Cálculo automático en m/s
   └─ Almacenada en base de datos
```

**Ubicación:** `lib/services/ubicacion_service.dart`, `lib/pages/tracking_corredores.dart`

---

## 🗄️ Estructura de Base de Datos

### Tabla: `usuarios`
```sql
id (UUID) → Primary Key
email (TEXT) → Unique
rol (TEXT) → corredor | admin | superadmin | topografo
activo (BOOLEAN) → true/false
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

### Tabla: `ubicaciones_corredores`
```sql
id (UUID) → Primary Key
usuario_id (UUID) → FK a usuarios
latitud (DECIMAL)
longitud (DECIMAL)
velocidad (DECIMAL) → m/s
timestamp (TIMESTAMP)
updated_at (TIMESTAMP)

Índices:
- usuario_id (UNIQUE)
- timestamp DESC
- usuario_id, timestamp DESC
```

---

## 🚀 Instalación Rápida

### 1. Setup Base de Datos
```bash
# En Supabase Dashboard → SQL Editor
# Copiar y ejecutar: SQL_SETUP.sql
```

### 2. Dependencias
```bash
flutter pub get
```

### 3. Permisos (iOS)
```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita tu ubicación...</string>
```

### 4. Permisos (Android)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### 5. Ejecutar
```bash
flutter run
```

---


### 👥 Roles de Usuario

#### 🏃 Corredor
- Inicia sesión con sus credenciales
- Rastreo GPS automático
- Puede ver a otros corredores en tiempo real en un mapa
- Ver detalles de ubicación (lat, lng, velocidad)
- Acceso a links de geolocalización en OpenStreetMap

#### 👨‍💼 Administrador
- Gestión completa de corredores:
   - ✅ **Agregar corredores** (via registro/login)
   - ✅ **Eliminar corredores** (con confirmación)
   - ✅ **Desactivar corredores** (cambiar estado)
   - ✅ **Ver tracking en vivo** (mapa interactivo)
- Panel en: `lib/pages/admin_corredores.dart`
      └─ Contador activos
```

---

## 📋 Archivos Principales

```
lib/
├── main.dart                          # Entrada
├── auth.dart                          # Autenticación ✨ MEJORADO
├── services/
│   └── ubicacion_service.dart        # ✨ NUEVO
├── pages/
│   ├── login.dart                     # Login
│   ├── tracking_corredores.dart      # ✨ NUEVO - Corredor
│   └── admin_corredores.dart         # ✨ NUEVO - Admin

Documentación/
├── SQL_SETUP.sql                      # ✨ NUEVO
├── DATOS_PRUEBA.sql                   # ✨ NUEVO
├── GUIA_COMPLETA.md                   # ✨ NUEVO
└── CHECKLIST_INTEGRACION.md           # ✨ NUEVO
```

---

## 🧪 Pruebas Recomendadas

### Test 1: Login
- [ ] Login como corredor
- [ ] Login como admin
- [ ] Redireccionamiento correcto

### Test 2: Rastreo
- [ ] 2 corredores en 2 dispositivos
- [ ] Mover uno → verificar en el otro
- [ ] Actualización automática

### Test 3: Admin
- [ ] Ver lista de corredores
- [ ] Ver tracking en vivo
- [ ] Desactivar corredor
- [ ] Eliminar corredor

---

## 🔧 Tecnologías Utilizadas

- **Framework:** Flutter 3.8+
- **Backend:** Supabase (PostgreSQL + Auth)
- **Mapas:** Flutter Map + OpenStreetMap
- **GPS:** Geolocator 11.0.0
- **Autenticación:** Supabase Auth
- **Base de Datos:** PostgreSQL con RLS

---

## 📚 Documentación Completa

Para información detallada, ver:
- `GUIA_COMPLETA.md` - Guía exhaustiva
- `CHECKLIST_INTEGRACION.md` - Pasos para integrar
- `SQL_SETUP.sql` - Setup de base de datos
- `DATOS_PRUEBA.sql` - Datos de prueba

---

## 🎓 Conceptos Implementados

✅ Autenticación multi-rol
✅ Geolocalización en tiempo real
✅ Actualizaciones automáticas (Streams)
✅ Mapas interactivos
✅ Row Level Security (RLS)
✅ Índices de base de datos
✅ Triggers automáticos
✅ Patrón Singleton
✅ Material Design 3

---

## 📞 Soporte

Para problemas:
1. Revisar `CHECKLIST_INTEGRACION.md`
2. Verificar `flutter doctor`
3. Revisar logs: `flutter logs`
4. Verificar Supabase Dashboard

---

**Versión:** 1.0.0  
**Última actualización:** 11 febrero 2026  
**Puntuación Total:** 80/80 ✅
![WhatsApp Image 2025-08-05 at 10 07 19 (2)](https://github.com/user-attachments/assets/0cc2fde9-0c92-48df-a002-33466595359f)

 
![WhatsApp Image 2025-08-05 at 10 09 09](https://github.com/user-attachments/assets/7194cba2-c8eb-4df0-b1b3-f265fa38d028)


- ☁️ **Datos almacenados en la nube (Supabase)**

<img width="1800" height="790" alt="image" src="https://github.com/user-attachments/assets/c59a9d5f-4a99-4627-a2b6-e698290cb46f" />



## 🔗 Links

[![Funcionalidad](https://img.shields.io/badge/Funcionalidad-red?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=V-qpMeYvJes)

[![Disponible en Amazon Appstore](https://img.shields.io/badge/Disponible_en-Amazon_Appstore-FF9900?style=for-the-badge&logo=amazon&logoColor=white)](https://www.amazon.com/gp/product/B0FLF722X7)



**Integrantes**
- Alisson Viteri
- Anthony Haro
- Jhonatan Bautista




