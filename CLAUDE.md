# CafeteriaNova — Sistema de Pedidos para Cafetería Universitaria

**Proyecto:** CafeteriaNova App  
**Cliente:** NovaUniversitas — Oaxaca de Juárez, Oaxaca  
**Versión:** 2.0  
**Última actualización:** Julio 2025

---

## 🎯 Descripción del Proyecto

CafeteriaNova es una plataforma digital que permite a la comunidad universitaria de NovaUniversitas (alumnos, docentes, personal administrativo y operativo) realizar pedidos de alimentos de manera anticipada desde dispositivos móviles, evitando filas y tiempos de espera.

El sistema digitaliza completamente el flujo de pedidos de la cafetería universitaria con tres interfaces diferenciadas: app móvil para clientes, panel web para caja/administración y display en tiempo real para cocina.

---

## 📚 Documentación de Referencia Obligatoria

**REGLA ABSOLUTA:** Antes de tomar cualquier decisión arquitectónica o de implementación, SIEMPRE consulta estos documentos en este orden:

1. **`SRS_CafeteriaNova_NovaUniversitas_v2.0.docx`** (Especificación de Requisitos de Software)
   - Fuente de verdad absoluta para funcionalidad
   - Define los 8 estados del ciclo de pedido (CRÍTICO)
   - Especifica los 4 roles de usuario y sus permisos
   - Contiene todos los requisitos funcionales (RF-001 a RF-064) y no funcionales (RNF-001 a RNF-023)
   - **Ubicación:** Raíz del proyecto o carpeta `/docs`

2. **Este archivo `CLAUDE.md`** (Contexto técnico y arquitectónico)
   - Stack tecnológico definitivo
   - Decisiones de arquitectura
   - Convenciones de código
   - Integración entre módulos

3. **Agentes especializados** (ver sección "Cuándo Invocar Agentes")
   - `backend-architect.md` — para backend NestJS + MongoDB
   - `flutter-architect.md` — para app móvil Flutter
   - `strategy-brainstormer.md` — para decisiones de producto

---

## 🏗️ Arquitectura del Sistema

### Stack Tecnológico (DEFINITIVO)

```
┌─────────────────────────────────────────────────────────────┐
│  FRONTEND MÓVIL                                             │
│  • Flutter 3.x (Dart)                                       │
│  • Riverpod (state management)                             │
│  • flutter_animate + Lottie (animaciones)                  │
│  • GoRouter (navegación con guards por rol)                │
│  • Dio (HTTP client con interceptores)                     │
│  • Firebase Cloud Messaging (push notifications)           │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTPS + WebSocket
┌─────────────────────────────────────────────────────────────┐
│  BACKEND API                                                │
│  • NestJS 10+ (Node.js + TypeScript)                       │
│  • MongoDB + Mongoose (base de datos)                      │
│  • Socket.io (tiempo real — cocina + pedidos)              │
│  • Firebase Admin SDK (FCM server + Storage)               │
│  • JWT + Guards (autenticación y autorización)             │
│  • class-validator + Zod (validación de DTOs)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  INFRAESTRUCTURA                                            │
│  • Railway (despliegue backend)                            │
│  • MongoDB Atlas (base de datos cloud)                     │
│  • Firebase (Storage para imágenes + FCM)                  │
│  • Play Store + App Store (distribución móvil)             │
└─────────────────────────────────────────────────────────────┘
```

### Repositorios Separados

```
cafeterianova-backend/     # NestJS + MongoDB + Socket.io + FCM
├── src/
├── .env.development
├── .env.staging
├── .env.production
├── CLAUDE.md              # Contexto específico del backend
└── README.md

cafeterianova-app/         # Flutter + Riverpod
├── lib/
├── .env.development
├── .env.staging
├── .env.production
├── CLAUDE.md              # Contexto específico de Flutter
└── README.md
```

**⚠️ IMPORTANTE:** Cada repositorio tiene su propio `CLAUDE.md` específico que extiende este archivo maestro con detalles técnicos del stack correspondiente.

---

## 🔄 Ciclo de Vida del Pedido (CRÍTICO)

Este es el flujo central de todo el sistema. Todos los módulos de pedidos (RF-022 a RF-041) implementan este ciclo.

### Estados del Pedido

| # | Actor | Estado | Descripción | Notificación al Cliente |
|---|-------|--------|-------------|------------------------|
| 1 | Cliente | **CREADO** | Cliente confirma pedido con restricciones y nota | Sí: "Pedido recibido" |
| 2 | Caja/Admin | **PENDIENTE_EN_CAJA** | Pedido espera revisión de ingredientes | No |
| 2A | Caja/Admin | **RECHAZADO_CAJA** | Caja rechaza (motivo obligatorio de lista) | Sí: motivo + mensaje alentador |
| 3 | Caja/Admin | **ACEPTADO** | Caja acepta → pasa automáticamente a cocina | No |
| 4 | Cocina | **EN_PREPARACION** | Cocina marca inicio de preparación | Sí: "En preparación" |
| 4A | Cocina | **RECHAZADO_COCINA** | Cocina rechaza (motivo obligatorio de lista) | Sí: motivo + mensaje alentador |
| 5 | Cocina | **LISTO_PARA_ENTREGAR** | Pedido terminado, listo para recoger | Sí: "¡Listo! Pasa por él" |
| 6 | Cliente/Caja | **ENTREGADO** | Cliente recogió y pagó | Sí: confirmación de cierre |

### Reglas de Negocio del Ciclo

1. Un pedido **RECHAZADO** (2A o 4A) no puede volver a estados anteriores
2. Solo Caja/Admin puede ejecutar el paso 2A; solo Cocina puede ejecutar 4A
3. El motivo de rechazo siempre es **obligatorio** (lista desplegable configurable)
4. Cada cambio de estado genera **automáticamente** una notificación push con sonido/vibración
5. Los pedidos con **beca activa** siguen el mismo ciclo pero sin cobro
6. Los pedidos creados desde caja (clientes sin app) entran directamente en estado **ACEPTADO** (paso 3)

**⚠️ REFERENCIA:** Ver Sección 3 del SRS para descripción completa del ciclo.

---

## 👥 Roles de Usuario

| Rol | Permisos Principales | Vistas |
|-----|---------------------|--------|
| **Administrador** | Gestión total: menú, usuarios, becas, cuenta MP, pedidos en caja, configuración de restricciones | Panel web completo |
| **Cajero** | Aceptar/rechazar pedidos, crear pedidos en caja, ver estado de pedidos | Panel web limitado |
| **Cocina** | Ver pedidos aceptados en tarjetas, actualizar estado (paso 4, 4A, 5), rechazar con motivo | Display de cocina (tablet/monitor) |
| **Cliente** | Hacer pedidos, ver menú, ver historial, configurar perfil y tema | App móvil |

---

## 🗄️ Esquema de Base de Datos (MongoDB)

### Colecciones Principales

#### `users`
```typescript
{
  _id: ObjectId,
  email: string,
  passwordHash: string,
  role: 'admin' | 'cajero' | 'cocina' | 'cliente',
  profile: {
    firstName: string,
    lastName: string,
    nickname: string,
    photoUrl: string,  // Firebase Storage ref
    area: 'alumno' | 'docente' | 'administrativo' | 'operativo' | 'otro',
    birthDate: Date,
  },
  scholarship: {
    hasDesayuno: boolean,
    hasComida: boolean,
  },
  fcmToken: string,  // Firebase Cloud Messaging token
  isActive: boolean,  // Requiere activación presencial por admin
  createdAt: Date,
  updatedAt: Date,
}
```

#### `products`
```typescript
{
  _id: ObjectId,
  name: string,
  description: string,
  price: number,
  category: 'antojitos' | 'desayuno' | 'comida' | 'especiales',
  photoUrl: string,  // Firebase Storage ref
  availableRestrictions: string[],  // IDs de restricciones aplicables
  isVisible: boolean,  // Ocultar sin eliminar
  createdAt: Date,
  updatedAt: Date,
}
```

#### `orders` (LA MÁS CRÍTICA)
```typescript
{
  _id: ObjectId,
  userId: ObjectId,  // Referencia a users
  items: [
    {
      productId: ObjectId,
      productSnapshot: { name, price, photoUrl },  // Snapshot del momento del pedido
      restrictions: string[],  // Ej: ['sin mayonesa', 'sin chile']
      quantity: number,
    }
  ],
  customerNote: string,  // "Llego en 10 min"
  totalAmount: number,
  paymentMethod: 'efectivo' | 'mercadopago' | 'beca',
  paymentStatus: 'pendiente' | 'pagado',
  currentStatus: 'CREADO' | 'PENDIENTE_EN_CAJA' | 'RECHAZADO_CAJA' | 'ACEPTADO' | 
                 'EN_PREPARACION' | 'RECHAZADO_COCINA' | 'LISTO_PARA_ENTREGAR' | 'ENTREGADO',
  statusHistory: [
    {
      status: string,
      actor: ObjectId,  // Usuario que ejecutó el cambio
      timestamp: Date,
      rejectionReason?: string,  // Solo si status es RECHAZADO_*
    }
  ],
  createdAt: Date,
  updatedAt: Date,
}
```

#### `restrictions`
```typescript
{
  _id: ObjectId,
  name: string,  // 'sin mayonesa', 'sin chile', 'solo quesillo'
  applicableCategories: string[],  // A qué productos aplica
  createdAt: Date,
}
```

#### `menu_items` (Desayuno y Comida del día)
```typescript
{
  _id: ObjectId,
  type: 'desayuno' | 'comida',
  name: string,
  description: string,
  price: number,
  photoUrl: string,
  date: Date,  // Día específico para el que se publicó
  createdAt: Date,
}
```

---

## 🔐 Autenticación y Autorización

### Flujo de Autenticación JWT

1. Usuario inicia sesión → backend genera `accessToken` (15min) y `refreshToken` (7 días)
2. Flutter almacena tokens en `flutter_secure_storage`
3. Dio interceptor agrega `Authorization: Bearer {accessToken}` a cada request
4. Si el access token expira, el interceptor usa el refresh token automáticamente
5. Logout → backend invalida el refresh token (blacklist en Redis o MongoDB)

### Guards de NestJS

```typescript
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'cajero')
@Post('orders/:id/accept')
async acceptOrder(@Param('id') id: string) { ... }
```

---

## 🔔 Sistema de Notificaciones

### Firebase Cloud Messaging (FCM)

**Backend:** Firebase Admin SDK envía notificaciones push  
**Frontend:** Flutter recibe con `firebase_messaging` package

### Eventos que Disparan Notificaciones

| Evento | Destinatario | Tipo | Payload |
|--------|--------------|------|---------|
| Pedido creado (paso 1) | Caja/Admin | Alerta con sonido | Datos del pedido |
| Pedido aceptado (paso 3) | Cliente | Silent (opcional) | Estado actualizado |
| Pedido en preparación (paso 4) | Cliente | Push con sonido | "Tu pedido está en preparación" |
| Pedido listo (paso 5) | Cliente | Push con sonido + vibración | "¡Tu pedido está listo!" |
| Pedido rechazado (2A o 4A) | Cliente | Push con motivo | Motivo + mensaje alentador |
| Cumpleaños | Todos los usuarios | Push celebración | Foto + nombre del festejado |

### Estructura de Notificación FCM

```typescript
{
  notification: {
    title: "Tu pedido está listo",
    body: "Pasa a la cafetería a recogerlo",
  },
  data: {
    orderId: "...",
    status: "LISTO_PARA_ENTREGAR",
    route: "/orders/123",  // Para deep linking en Flutter
  },
  token: "device-fcm-token",
}
```

---

## 🎨 Sistema de Diseño Visual

### Colores Institucionales NovaUniversitas

```dart
// lib/core/theme/app_colors.dart
class NovaColors {
  // Primarios
  static const greenDark = Color(0xFF1A4731);
  static const greenMedium = Color(0xFF2E7D52);
  static const greenLight = Color(0xFFD4EDDA);
  static const gold = Color(0xFFC8960C);
  static const goldLight = Color(0xFFFFF8E1);
  
  // Semánticos (estados de pedido)
  static const statusReady = Color(0xFF1B5E20);      // Verde para LISTO
  static const statusInProgress = Color(0xFFE65100); // Ámbar para EN_PREPARACION
  static const statusRejected = Color(0xFFB71C1C);   // Rojo para RECHAZADO
}
```

### Temas Disponibles

1. **Tema Institucional** (default) — Colores NovaUniversitas
2. **Modo Oscuro** — Esquema oscuro con acentos en gold
3. **Modo Claro** — Esquema claro con acentos en greenMedium
4. **Tema del Sistema** — Sigue la configuración del teléfono

**Regla:** El usuario selecciona el tema desde su perfil; se persiste en `SharedPreferences` y aplica inmediatamente.

---

## 📡 Tiempo Real (WebSockets)

### Socket.io — Eventos del Sistema

**Backend:** `OrdersGateway` (NestJS WebSocket Gateway)  
**Frontend:** `socket_io_client` package en Flutter

#### Rooms de Socket.io

```typescript
// Backend NestJS
@WebSocketGateway()
export class OrdersGateway {
  @SubscribeMessage('join-kitchen')
  handleJoinKitchen(client: Socket) {
    client.join('kitchen');  // Todos los pedidos aceptados
  }
  
  @SubscribeMessage('join-cashier')
  handleJoinCashier(client: Socket) {
    client.join('cashier');  // Nuevos pedidos entrantes
  }
  
  @SubscribeMessage('join-order')
  handleJoinOrder(client: Socket, orderId: string) {
    client.join(`order:${orderId}`);  // Cliente sigue su pedido específico
  }
}
```

#### Eventos Emitidos

```typescript
// Desde backend
server.to('kitchen').emit('order:accepted', orderData);
server.to('cashier').emit('order:created', orderData);
server.to(`order:${orderId}`).emit('order:status-changed', { status, timestamp });
```

```dart
// Flutter recibe
socket.on('order:status-changed', (data) {
  ref.read(orderProvider.notifier).updateStatus(data['status']);
  showNotification(data['status']);
});
```

---

## 🛠️ Convenciones de Código

### Nomenclatura

| Contexto | Convención | Ejemplo |
|----------|-----------|---------|
| Clases (NestJS + Dart) | PascalCase | `OrdersService`, `MenuRepository` |
| Métodos/funciones | camelCase | `acceptOrder()`, `fetchProducts()` |
| Variables | camelCase | `totalAmount`, `fcmToken` |
| Archivos (NestJS) | kebab-case | `orders.service.ts`, `jwt-auth.guard.ts` |
| Archivos (Flutter) | snake_case | `order_card.dart`, `app_colors.dart` |
| Constantes | UPPER_SNAKE_CASE | `MAX_ORDERS_PER_USER`, `FCM_TOPIC` |
| DTOs (NestJS) | PascalCase + sufijo | `CreateOrderDto`, `UpdateUserDto` |
| Enums | PascalCase | `OrderStatus`, `UserRole` |

### Estructura de Carpetas (Backend NestJS)

```
src/
├── modules/
│   ├── auth/           # JWT, login, register
│   ├── users/          # CRUD usuarios, becas
│   ├── orders/         # Ciclo de pedido completo (CRÍTICO)
│   ├── products/       # CRUD productos
│   ├── menu/           # Desayuno y comida del día
│   ├── restrictions/   # Gestión de restricciones
│   ├── notifications/  # FCM server-side
│   └── kitchen/        # WebSocket gateway para cocina
├── common/
│   ├── guards/         # JwtAuthGuard, RolesGuard
│   ├── decorators/     # @Roles(), @CurrentUser()
│   ├── filters/        # Global exception filter
│   ├── interceptors/   # Logging, transform response
│   └── pipes/          # ZodValidationPipe
├── config/
│   ├── database.config.ts
│   ├── firebase.config.ts
│   └── jwt.config.ts
└── main.ts
```

### Estructura de Carpetas (Flutter)

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/       # Repositories, DTOs
│   │   ├── domain/     # Models, use cases
│   │   └── presentation/ # Screens, widgets, providers
│   ├── menu/
│   ├── orders/         # Flujo de pedido del cliente
│   ├── kitchen/        # Display de cocina (solo rol cocina)
│   ├── cashier/        # Panel de caja (solo admin/cajero)
│   └── profile/
├── core/
│   ├── theme/          # NovaColors, ThemeData
│   ├── router/         # GoRouter con guards
│   ├── network/        # Dio + interceptores
│   └── notifications/  # FCM handler
└── shared/
    ├── widgets/        # Componentes reutilizables
    └── models/         # DTOs compartidos
```

---

## 🚀 Ambientes de Despliegue

| Ambiente | Backend URL | MongoDB | Firebase Project | Flutter Build |
|----------|-------------|---------|------------------|---------------|
| **development** | `http://localhost:3000` | MongoDB local o Atlas dev | `cafeterianova-dev` | Debug local |
| **staging** | `https://cafeterianova-staging.railway.app` | Atlas staging cluster | `cafeterianova-staging` | Debug + staging API |
| **production** | `https://cafeterianova.railway.app` | Atlas production cluster | `cafeterianova-prod` | Release |

### Variables de Entorno (Backend)

```bash
# .env.production
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/cafeterianova
JWT_SECRET=your-strong-secret
JWT_REFRESH_SECRET=your-refresh-secret
FIREBASE_PROJECT_ID=cafeterianova-prod
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=firesdk@cafeno.com
FRONTEND_URL=https://cafeno.app  # Para CORS
```

### Variables de Entorno (Flutter)

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'cafeterianova-dev',
  );
}
```

---

## 🤖 Cuándo Invocar Agentes Especializados

Claude Code tiene acceso a agentes especializados. Cada agente tiene memoria persistente y expertise específico.

### `backend-architect.md`

**Invocar cuando:**
- Diseñar o implementar módulos NestJS
- Definir esquemas de MongoDB / Mongoose
- Configurar Guards, Pipes, Interceptors
- Implementar WebSockets con Socket.io
- Integrar Firebase Admin SDK (FCM + Storage)
- Resolver conflictos entre requisitos del SRS y arquitectura técnica

**Ejemplo de invocación:**
```
User: "Necesito implementar el módulo de pedidos con todos los estados del ciclo"
Assistant: "Voy a invocar al agente backend-architect para diseñar la arquitectura completa del módulo de pedidos..."
```

### `flutter-architect.md`

**Invocar cuando:**
- Diseñar arquitectura de features en Flutter
- Implementar state management con Riverpod
- Configurar navegación con GoRouter y guards por rol
- Diseñar componentes animados con flutter_animate
- Implementar manejo de FCM en foreground/background
- Resolver problemas de UI/UX o accesibilidad WCAG

**Ejemplo de invocación:**
```
User: "La pantalla de cocina debe mostrar tarjetas de pedidos en tiempo real"
Assistant: "Voy a invocar al agente flutter-architect para diseñar el display de cocina con WebSockets y animaciones..."
```

### `strategy-brainstormer.md`

**Invocar cuando:**
- Necesitas explorar múltiples soluciones a un problema ambiguo
- Hay conflicto entre requisitos del SRS y restricciones técnicas
- Planificar nuevas features no contempladas en el SRS
- Generar alternativas para decisiones de producto
- Priorizar features usando matrices de impacto/esfuerzo

**Ejemplo de invocación:**
```
User: "¿Cómo manejamos pedidos cuando la conexión es intermitente?"
Assistant: "Voy a invocar al agente strategy-brainstormer para explorar estrategias de offline-first y sincronización..."
```

---

## ⚠️ Reglas Absolutas de Implementación

### NUNCA

1. ❌ **NUNCA** mezclar lógica de negocio en controladores NestJS → siempre en servicios
2. ❌ **NUNCA** usar `setState` directamente en Flutter → siempre Riverpod providers
3. ❌ **NUNCA** hardcodear colores en widgets → siempre usar `NovaColors` del tema
4. ❌ **NUNCA** omitir validación de DTOs con class-validator o Zod
5. ❌ **NUNCA** almacenar contraseñas en texto plano → bcrypt con salt rounds >= 10
6. ❌ **NUNCA** exponer información sensible en logs de producción
7. ❌ **NUNCA** devolver un pedido rechazado a estados anteriores (regla del ciclo)

### SIEMPRE

1. ✅ **SIEMPRE** consultar el SRS antes de implementar cualquier requisito funcional
2. ✅ **SIEMPRE** registrar en `statusHistory` cada cambio de estado del pedido
3. ✅ **SIEMPRE** enviar notificación FCM al cambiar estado de pedido
4. ✅ **SIEMPRE** validar permisos de rol con Guards antes de ejecutar acciones críticas
5. ✅ **SIEMPRE** usar transacciones de MongoDB para operaciones multi-documento
6. ✅ **SIEMPRE** manejar errores con clases de excepción específicas (NestJS) y Either pattern (Flutter)
7. ✅ **SIEMPRE** testear el flujo completo del ciclo de pedido antes de mergear

---

## 📝 Checklist Pre-Implementación

Antes de comenzar cualquier feature, verifica:

- [ ] ¿Consulté el SRS v2.0 para entender el requisito exacto?
- [ ] ¿Identifiqué qué parte del ciclo de pedido afecta esta feature?
- [ ] ¿Verifiqué qué roles tienen permiso para ejecutar esta acción?
- [ ] ¿Diseñé el esquema de MongoDB o el modelo de datos Flutter?
- [ ] ¿Definí qué notificaciones push se disparan?
- [ ] ¿Consideré el manejo de errores y casos edge (timeout, conexión perdida)?
- [ ] ¿Invoqué al agente especializado correspondiente si la tarea es compleja?

---

## 🎓 Glosario de Términos del Dominio

| Término | Definición |
|---------|-----------|
| **Restricción** | Modificación al producto solicitada por el cliente (ej. "sin mayonesa", "solo quesillo") |
| **Beca alimentaria** | Beneficio institucional que exenta al alumno del pago de desayuno y/o comida |
| **Nota del cliente** | Mensaje opcional que el cliente agrega al pedido (ej. "Llego en 10 min") |
| **Snapshot de producto** | Copia de nombre/precio/foto del producto en el momento del pedido (no se actualiza si el producto cambia después) |
| **Tarjeta de cocina** | Card visual en el display de cocina que muestra foto, nombre, pedido y nota del cliente |
| **Motivo de rechazo** | Razón obligatoria seleccionada de lista desplegable al rechazar un pedido (pasos 2A o 4A) |
| **Productos especiales** | Productos ocasionales (cóctel de fruta, cheesecake) que se destacan en primera posición del menú |

---

## 📞 Soporte y Contacto

**Desarrollador principal:** Omar Martínez Osorio  
**Cliente:** NovaUniversitas — Oaxaca de Juárez, Oaxaca  
**Documentación completa:** Ver `SRS_CafeteriaNova_NovaUniversitas_v2.0.docx`

---

**Última actualización:** Julio 2025  
**Versión del documento:** 2.0
