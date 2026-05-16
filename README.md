# Atom — Pomodoro con gestión inteligente de proyectos

Aplicación móvil de productividad basada en el método Pomodoro con generación automática de microtareas mediante IA (Ollama).

## Estructura del monorepo

```
atom/
├── frontend/          # App Flutter (iOS + Android)
├── backend/           # API REST Node.js + Express + PostgreSQL
├── README.md
└── .gitignore
```

---

## Requisitos previos

| Herramienta | Versión mínima |
|-------------|---------------|
| Node.js     | 18.x          |
| Flutter     | 3.x           |
| PostgreSQL  | 14.x          |
| Ollama      | 0.1.x         |

---

## Backend

### 1. Configurar variables de entorno

```bash
cd backend
cp .env.example .env
# Editar .env con tus valores reales
```

Variables requeridas:

```
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://usuario:contraseña@localhost:5432/atom_db
JWT_SECRET=tu_secreto_muy_largo_y_aleatorio
REFRESH_TOKEN_SECRET=otro_secreto_diferente
ALLOWED_ORIGINS=http://localhost:3000
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
FACEBOOK_APP_ID=...
FACEBOOK_APP_SECRET=...
OAUTH_CALLBACK_HOST=http://localhost:3000
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2
```

### 2. Crear base de datos y ejecutar migración

```bash
createdb atom_db
npm run migrate
```

### 3. Instalar dependencias e iniciar

```bash
npm install
npm run dev      # desarrollo con nodemon
npm start        # producción
```

### Endpoints

| Método | Ruta | Autenticación | Descripción |
|--------|------|---------------|-------------|
| POST | `/auth/register` | — | Registro con email + contraseña |
| POST | `/auth/login` | — | Login, devuelve JWT pair |
| POST | `/auth/refresh` | — | Rota refresh token |
| POST | `/auth/logout` | Bearer | Revoca refresh token |
| GET | `/auth/google` | — | Inicia flujo OAuth Google |
| GET | `/auth/google/callback` | — | Callback OAuth Google |
| GET | `/auth/facebook` | — | Inicia flujo OAuth Facebook |
| GET | `/auth/facebook/callback` | — | Callback OAuth Facebook |
| GET | `/projects` | Bearer | Lista proyectos del usuario |
| POST | `/projects` | Bearer | Crea proyecto + genera microtareas con Ollama |
| GET | `/projects/:id` | Bearer | Detalle de proyecto con microtareas |
| DELETE | `/projects/:id` | Bearer | Elimina proyecto |
| PATCH | `/tasks/:id` | Bearer | Actualiza estado de microtarea |
| POST | `/sessions` | Bearer | Registra sesión Pomodoro completada |

### Flujo OAuth (deep link)

Tras autenticarse con Google/Facebook, el servidor redirige a:

```
atom://auth?access_token=<JWT>&refresh_token=<token_opaco>
```

La app Flutter captura este deep link y almacena los tokens.

---

## Frontend (Flutter)

### Configurar deep link

**iOS** — `frontend/ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>atom</string>
    </array>
  </dict>
</array>
```

**Android** — `frontend/android/app/src/main/AndroidManifest.xml` (dentro de `<activity>`):

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="atom" android:host="auth" />
</intent-filter>
```

### Instalar dependencias e iniciar

```bash
cd frontend
flutter pub get
flutter run
```

---

## Modelo de datos

```
users
  id · email · name · avatar_url · password_hash · created_at · updated_at

oauth_accounts
  id · user_id → users · provider (google|facebook) · provider_user_id

refresh_tokens
  id · user_id → users · token_hash (SHA-256) · device_info · expires_at · revoked_at

projects
  id · user_id → users · name · description · status (active|completed|archived)
  ai_model · created_at · updated_at

micro_tasks
  id · project_id → projects · title · order_index · is_completed · completed_at

pomodoro_sessions
  id · user_id → users · micro_task_id → micro_tasks
  type (work|short_break|long_break) · started_at · ended_at · was_skipped · task_completed
```

---

## Ciclo Pomodoro

```
[Trabajo 25min] → modal "¿Completaste la tarea?"
        ↓
   respuesta del usuario
        ↓
[Descanso corto 5min]  — si completedPomodoros % 4 ≠ 0
[Descanso largo 20min] — si completedPomodoros % 4 == 0
        ↓
[Trabajo 25min] — siguiente ciclo
```

Alarma sonora al finalizar cada fase; se detiene al iniciar el siguiente Pomodoro.

---

## Licencia

MIT
