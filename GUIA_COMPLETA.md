# Guía Completa: Sistema de Tracking de Corredores

## 📋 Resumen del Proyecto

Sistema móvil en Flutter que permite rastrear en tiempo real la ubicación de un grupo de corredores, con panel de administración para gestionar usuarios y ver el tracking en vivo.

### Puntuación Total: 80 puntos

---

## ✅ Requisitos Implementados

### 1️⃣ Login para Validación de Usuarios (10 puntos)
**Estado:** ✅ Implementado

**Características:**
- Autenticación con Supabase
- Validación de credenciales
- Diferentes roles de usuario
- Redirección automática según rol

**Archivos:**
- `lib/auth.dart` - Sistema de autenticación y redirección
- `lib/pages/login.dart` - Interfaz de login

**Roles soportados:**
- `corredor` - Usuarios que corren y se rastrean
- `admin` - Gestiona corredores y ve tracking

---

### 2️⃣ Sistema de Administración Web (20 puntos)
**Estado:** ✅ Implementado

**Características principales:**

#### a) Agregar Corredores
- A través del sistema de registro/login
- Asignación automática de rol
- Validación de email

#### b) Eliminar Corredores
- Botón con confirmación
- Eliminación de usuario de base de datos
- Actualización inmediata de lista

#### c) Desactivar Corredores
- Cambio de estado sin eliminar datos
- Permite reactivar después
- Visual claro del estado

#### d) Ver Tracking en Tiempo Real
- Mapa con OpenStreetMap integrado
- Actualización de ubicaciones cada 3 segundos
- Contador de corredores en línea
- Marcadores de ubicación en tiempo real

**Archivo:**
- `lib/pages/admin_corredores.dart` - Panel completo

**Interfaz:**
```
┌─────────────────────────────────────┐
│ Administración de Corredores        │
├─────────────────────────────────────┤
│ [Gestionar Corredores] [Tracking]   │
├─────────────────────────────────────┤
│ 📧 corredor1@test.com               │
│ 🟢 Activo                    ⋯      │
│                                     │
│ 📧 corredor2@test.com               │
│ 🔴 Inactivo                  ⋯      │
└─────────────────────────────────────┘

Tab 2 - Tracking:
┌─────────────────────────────────────┐
│         [Mapa con marcadores]       │
│         Corredores en línea: 2      │
└─────────────────────────────────────┘
```

---

### 3️⃣ Geolocalización en Tiempo Real (50 puntos)
**Estado:** ✅ Implementado

#### a) Rastreo en Tiempo Real
- GPS continuo usando `geolocator`
- Actualización cada 10 metros o 5 segundos
- Precisión de ubicación: HIGH
- Velocidad calculada automáticamente

#### b) OpenStreetMap / Google Maps
- Integración con `flutter_map` (OpenStreetMap)
- Marcadores visuales de ubicación
- Zoom y centrado automático
- Polígonos de área (heredado)

#### c) Links de Geolocalización Automáticos
- Generación automática de URLs OSM
- Formato: `https://www.openstreetmap.org/?mlat=LAT&mlon=LNG&zoom=15`
- Clickeables en detalles de corredor
- Copiables al portapapeles

**Archivos:**
- `lib/services/ubicacion_service.dart` - Lógica de tracking
- `lib/pages/tracking_corredores.dart` - UI para corredores

**Funcionalidades del Servicio:**

```dart
// Servicio singleton
final ubicacionService = UbicacionService();

// Solicitar permisos
bool tienePermiso = await ubicacionService.solicitarPermisos();

// Verificar servicio
bool servicioHabilitado = await ubicacionService.verificarServicioUbicacion();

// Obtener ubicación actual
Position? posicion = await ubicacionService.obtenerUbicacionActual();

// Iniciar rastreo (automático y continuo)
await ubicacionService.iniciarRastreo(usuarioId);

// Obtener ubicaciones de otros corredores
List<Map<String, dynamic>> corredores = await ubicacionService.obtenerCorredores();

// Generar link
String link = ubicacionService.generarLinkGeolocalizacion(latitud, longitud);

// Detener rastreo
ubicacionService.detenerRastreo();
```

---

## 🗄️ Estructura de Base de Datos

### Tabla: `usuarios`
```sql
id (UUID) - Primary Key
email (TEXT) - Unique
rol (TEXT) - corredor | admin | superadmin | topografo
activo (BOOLEAN) - true/false
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

### Tabla: `ubicaciones_corredores`
```sql
id (UUID) - Primary Key
usuario_id (UUID) - Foreign Key → usuarios
latitud (DECIMAL)
longitud (DECIMAL)
velocidad (DECIMAL) - m/s
timestamp (TIMESTAMP)
updated_at (TIMESTAMP)

Índices:
- usuario_id (UNIQUE)
- timestamp DESC
- usuario_id, timestamp DESC
```

---

## 📱 Flujo de Usuario

### Flujo Corredor:
```
Login → Dashboard → Mapa Tracking
       ↓
   Autoinicia GPS
   Ubicación guardada en BD
   Ve a otros corredores
   Puede ver detalles/links
```

### Flujo Admin:
```
Login → Panel Admin
       ├─ Tab 1: Gestionar Corredores
       │  ├─ Ver lista
       │  ├─ Desactivar
       │  └─ Eliminar
       │
       └─ Tab 2: Tracking en Vivo
          ├─ Mapa interactivo
          ├─ Actualización automática
          └─ Contador de activos
```

---

## 🔧 Instalación y Configuración

### 1. Clonar y Dependencias
```bash
cd /path/to/proyecto
flutter pub get
```

### 2. Configurar Supabase

#### En Supabase Dashboard:
1. Ejecutar SQL en editor SQL (copiar contenido de `SQL_SETUP.sql`)
2. Verificar tablas creadas
3. Habilitar RLS (Row Level Security)

#### En el código:
```dart
// Ya configurado en lib/main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 3. Permisos del Sistema

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita acceso a tu ubicación para rastrear tu actividad.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Se necesita acceso continuo a tu ubicación.</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 4. Lanzar Aplicación
```bash
flutter run
```

---

## 📊 Datos en Tiempo Real

**Actualización de ubicaciones:**
- Frecuencia: Cada 10 metros O cada 5 segundos
- Precisión: Alta (±5-10 metros)
- Campo velocidad: Se calcula automáticamente

**Limpieza de datos:**
- Ubicaciones más antiguas de 5 minutos → se consideran offline
- Ubicaciones más antiguas de 6 horas → se pueden eliminar (opcional)

---

## 🧪 Pruebas Recomendadas

### Test 1: Rastreo Básico
1. Crear 2 usuarios como "corredor"
2. Login en dispositivo 1 como corredor1
3. Login en dispositivo 2 como corredor2
4. Mover dispositivo 1
5. Verificar que ubicación aparece en dispositivo 2

### Test 2: Panel Admin
1. Login como admin
2. Ver ambos corredores en lista
3. Verificar Tab de Tracking con ambas ubicaciones
4. Desactivar un corredor
5. Verificar que se refleja inmediatamente

### Test 3: Permisos
1. Denegar permiso de ubicación
2. Verificar que app solicita nuevamente
3. Aceptar permiso
4. Verificar que rastreo comienza

---

## 📝 Archivos Clave

```
lib/
├── main.dart                          # Punto de entrada
├── auth.dart                          # Lógica autenticación
├── services/
│   ├── supabase_service.dart         # (Existente)
│   └── ubicacion_service.dart        # ✨ NUEVO - Rastreo GPS
├── pages/
│   ├── login.dart                     # Login
│   ├── mapa.dart                      # (Existente)
│   ├── panel_admin.dart              # (Existente)
│   ├── tracking_corredores.dart      # ✨ NUEVO - UI Corredor
│   └── admin_corredores.dart         # ✨ NUEVO - Panel Admin
│
SQL_SETUP.sql                          # ✨ NUEVO - Setup BD
REQUISITOS_TRACKING.md                 # ✨ NUEVO - Docs
GUIA_IMPLEMENTACION.md                 # ✨ NUEVO - Esta guía
```

---

## 🎯 Checkpoints de Validación

- [ ] Base de datos creada y tablas visibles en Supabase
- [ ] Login funciona con diferentes roles
- [ ] Corredor ve su propia ubicación en mapa
- [ ] Admin ve todos los corredores
- [ ] Actualización automática cada 3-5 segundos
- [ ] Desactivar/eliminar corredores funciona
- [ ] Links de OSM generados correctamente
- [ ] Rastreo continuo funciona entre dispositivos
- [ ] Permisos se solicitan correctamente

---

## 🐛 Troubleshooting

### "Too many positional arguments"
✅ Solucionado en versión actual

### Ubicación no se actualiza
1. Verificar permisos en dispositivo
2. Verificar servicio de ubicación habilitado
3. Revisar logs: `flutter logs`

### Admin no ve ubicaciones
1. Verificar que existan usuarios con rol "corredor"
2. Verificar que hayan iniciado rastreo
3. Verificar conexión Supabase

### Permisos denegados
1. iOS: Settings → Privacy → Location
2. Android: Settings → Apps → Permisos

---

## 📱 Dispositivos Soportados

- ✅ iOS 12+
- ✅ Android 5.0+
- ⚠️ Web (limitado - sin GPS real)

---

## 🎓 Conceptos Implementados

- **Autenticación:** Supabase Auth
- **Base de datos:** Supabase PostgreSQL
- **Geolocalización:** Geolocator package
- **Mapas:** Flutter Map + OpenStreetMap
- **Tiempo real:** Stream listeners
- **Seguridad:** Row Level Security (RLS)
- **UI/UX:** Material Design 3
- **Patrones:** Singleton (UbicacionService), Provider (Builder patterns)

---

## 📧 Contacto / Soporte

Para preguntas o issues:
1. Revisar logs: `flutter logs`
2. Verificar configuración de Supabase
3. Verificar permisos del sistema operativo
4. Ejecutar `flutter doctor`

---

**Última actualización:** Febrero 2026
**Versión:** 1.0.0
