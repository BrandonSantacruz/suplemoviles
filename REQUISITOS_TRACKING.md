# Sistema de Tracking de Corredores - Requisitos de Base de Datos

## Estructura de Tablas Requeridas en Supabase

### 1. Tabla `usuarios`
```sql
CREATE TABLE usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('corredor', 'admin')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

**Roles disponibles:**
- `corredor`: Usuarios que corren y se rastrean
- `admin`: Administradores que gestionan corredores y ven tracking en vivo


### 2. Tabla `ubicaciones_corredores` (Geolocalización en Tiempo Real)
```sql
CREATE TABLE ubicaciones_corredores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  latitud DECIMAL(10, 8) NOT NULL,
  longitud DECIMAL(11, 8) NOT NULL,
  velocidad DECIMAL(5, 2) DEFAULT 0,
  timestamp TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  UNIQUE(usuario_id)
);

CREATE INDEX idx_ubicaciones_timestamp ON ubicaciones_corredores(timestamp DESC);
CREATE INDEX idx_ubicaciones_usuario ON ubicaciones_corredores(usuario_id);
```

## Requisitos Implementados

### ✅ 1. Login (10 puntos)
- Sistema de autenticación con Supabase
- Validación de credenciales
- Redirección según rol del usuario

**Archivos:**
- `lib/auth.dart` - Lógica de autenticación
- `lib/pages/login.dart` - UI de login

### ✅ 2. Panel de Administración (20 puntos)
Características:
- **Agregar corredores** - A través del login/registro
- **Eliminar corredores** - Con confirmación
- **Desactivar corredores** - Cambiar estado activo/inactivo
- **Ver tracking en vivo** - Mapa con ubicaciones en tiempo real

**Archivo:**
- `lib/pages/admin_corredores.dart`

**Funcionalidades:**
- Tab 1: Gestionar Corredores
  - Lista de todos los corredores
  - Opciones para desactivar o eliminar
  - Estado de activación visual
  
- Tab 2: Tracking en Vivo
  - Mapa interactivo con OpenStreetMap
  - Marcadores de ubicación de corredores
  - Actualizaciones cada 3 segundos

### ✅ 3. Geolocalización en Tiempo Real (50 puntos)
Características:
- **Rastreo continuo** - GPS en tiempo real
- **Actualización periódica** - Cada 10 metros de movimiento
- **Historial de ubicaciones** - Con timestamp y velocidad
- **Links de geolocalización** - Generación automática

**Archivos:**
- `lib/services/ubicacion_service.dart` - Servicio de ubicación
- `lib/pages/tracking_corredores.dart` - UI de tracking para corredores

**Funcionalidades del servicio:**
```dart
// Solicitar permisos de ubicación
await ubicacionService.solicitarPermisos();

// Iniciar rastreo
await ubicacionService.iniciarRastreo(usuarioId);

// Obtener ubicaciones de corredores
List<Map<String, dynamic>> corredores = await ubicacionService.obtenerCorredores();

// Generar link de geolocalización
String link = ubicacionService.generarLinkGeolocalizacion(lat, lng);
// Genera: https://www.openstreetmap.org/?mlat=lat&mlon=lng&zoom=15
```

## Flujo de Uso

### Para Corredores:
1. Login con credenciales
2. Automáticamente se inicia rastreo de ubicación
3. Ven a otros corredores en el mapa
4. Pueden ver detalles y links de ubicación

### Para Administradores:
1. Login como admin
2. Tab "Gestionar Corredores" - Administrar lista
3. Tab "Tracking en Vivo" - Ver todas las ubicaciones en tiempo real
4. Pueden desactivar/eliminar corredores según sea necesario


- Acceso total a todas las funciones administrativas

## Dependencias Requeridas

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.9.1
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
```

## Configuración de Permisos

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a tu ubicación para rastrear tu actividad física.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a tu ubicación en todo momento.</string>
```

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Pruebas

Para probar la aplicación:

1. **Crear usuarios de prueba:**
   - Corredor 1: corredor1@test.com
   - Corredor 2: corredor2@test.com
   - Admin: admin@test.com

2. **En dos dispositivos/emuladores:**
   - Abre la app en ambos como corredores
   - Mueve uno de ellos físicamente o simula ubicación
   - La ubicación debe aparecer en tiempo real en ambos dispositivos

3. **En admin:**
   - Login como admin
   - Ve el Tab de "Tracking en Vivo"
   - Observa los marcadores actualizándose
