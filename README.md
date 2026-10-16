# Tutor Virtual Adaptativo (TutorMind AI)

Plataforma web de tutoría virtual con inteligencia artificial que adapta sus explicaciones al estilo de aprendizaje de cada estudiante universitario. Detecta señales de comprensión y frustración, guarda el historial por sesiones y le permite al profesor hacer seguimiento de sus estudiantes.

Proyecto de la asignatura **Proyecto**, Ingeniería de Software, UNINPAHU. Docente: Brayan Sebastián Salas Rico.

## Integrantes

- Sergio Andrés Gutiérrez Marín
- Edilson Mirllan Suarez Gutiérrez
- David Humberto Mahecha Cardozo

## Tecnologías

| Capa | Tecnología |
|------|------------|
| Frontend | Angular 17 (standalone components) |
| Backend | Python + FastAPI |
| Base de datos | SQLite + SQLAlchemy |
| IA generativa | Google Gemini (`gemini-1.5-flash` por defecto) |
| Streaming | Server-Sent Events (SSE) |
| Seguridad | Contraseñas con PBKDF2-SHA256, CORS configurable |
| Control de versiones | Git y GitHub |

## Arquitectura general

Arquitectura cliente-servidor en tres capas:

1. **Aplicación web (Angular):** pantallas de chat de estudio, registro y panel del docente.
2. **API backend (FastAPI):** autenticación, sesiones, armado del prompt con el perfil del estudiante, actualización del perfil, progreso y panel docente.
3. **Servicios de datos e IA:** base de datos SQLite y API de Gemini. Solo el backend se comunica con ellos.

Componentes del backend: routers (`users`, `chat`, `profile`, `teachers`), `auth_utils.py`, `prompt_builder.py`, `memory_manager.py`, `analytics.py`, `gemini_client.py`, `models.py` y `database.py`.

## Estructura del proyecto

```
tutormind/
├── backend/            # API FastAPI
│   ├── routers/        # users, chat, profile, teachers
│   └── ...
├── frontend/           # App Angular
├── .env.example        # Plantilla de variables de entorno
├── start-backend.bat   # Arranque del backend en Windows
└── README.md
```

## Requisitos

- Python 3.10 o superior
- Node.js 18 o superior
- API key de [Google AI Studio](https://aistudio.google.com/app/apikey)

## Instalación y ejecución

### 1. Variables de entorno

En la raíz del proyecto:

```bash
cp .env.example .env
```

Edita `.env` y coloca tu clave. El archivo `.env` está en `.gitignore` y no se sube al repositorio.

### 2. Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

La API queda en `http://localhost:8000`. Documentación interactiva en `http://localhost:8000/docs`.

Ejecuta `uvicorn` desde la carpeta `backend` para que la base de datos se cree en el lugar correcto. En Windows también puedes usar `start-backend.bat`.

### 3. Frontend

```bash
cd frontend
npm install
npm start
```

Abre `http://localhost:4200`.

## Variables de entorno

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Clave de la API de Gemini (secreta, no publicar) | `tu_clave_de_google_ai_studio` |
| `GEMINI_MODEL` | Modelo de Gemini a usar | `gemini-1.5-flash` |
| `GEMINI_ALLOWED_MODELS` | Modelos permitidos, separados por coma | `gemini-1.5-flash,gemini-1.5-flash-8b` |
| `DATABASE_URL` | Cadena de conexión de la base de datos | `sqlite:///./tutormind.db` |
| `ALLOWED_ORIGINS` | Orígenes permitidos por CORS | `http://localhost:4200` |

## Flujo de uso

1. El usuario crea una cuenta con nombre, correo, contraseña y rol (estudiante o profesor).
2. El estudiante crea o selecciona una sesión de estudio.
3. Escribe sus dudas y la respuesta llega por partes (SSE).
4. Tras cada respuesta, el backend extrae una señal de aprendizaje (`[SIGNAL:...]`) y actualiza el perfil del estudiante.
5. El estudiante puede generar exámenes de opción múltiple y ver sus estadísticas.
6. El docente vincula estudiantes por correo y consulta su progreso en el panel.

## Endpoints principales

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/users` | Crear usuario |
| POST | `/api/users/login` | Iniciar sesión con correo y contraseña |
| GET | `/api/users/{user_id}` | Consultar usuario |
| GET | `/api/profile/{user_id}` | Perfil de aprendizaje |
| PATCH | `/api/profile/{user_id}` | Actualizar perfil |
| GET | `/api/profile/{user_id}/stats` | Estadísticas de aprendizaje |
| POST | `/api/chat/{user_id}/session` | Crear sesión |
| GET | `/api/chat/{user_id}/sessions` | Listar sesiones |
| PATCH | `/api/chat/{user_id}/session/{session_id}` | Actualizar sesión |
| DELETE | `/api/chat/{user_id}/session/{session_id}` | Eliminar sesión |
| GET | `/api/chat/{user_id}/session/{session_id}/messages` | Mensajes de una sesión |
| GET / POST | `/api/chat/{user_id}/message` | Chat por SSE |
| POST | `/api/chat/{user_id}/exam/generate` | Generar examen |
| POST | `/api/chat/{user_id}/exam/submit` | Enviar respuestas del examen |
| GET | `/api/teachers/{teacher_id}/students` | Estudiantes vinculados al docente |
| POST | `/api/teachers/{teacher_id}/students` | Vincular estudiante por correo |
| DELETE | `/api/teachers/{teacher_id}/students/{enrollment_id}` | Desvincular estudiante |
| GET | `/api/health` | Estado del servicio |

## Limitaciones conocidas

- La API no usa tokens (JWT): confía en el id de usuario que llega en la URL.
- La base de datos es SQLite, pensada para desarrollo y pocos usuarios.
- Por ahora solo se ejecuta en local.

## Despliegue

Por ahora el sistema se ejecuta de forma local. No hay servicio en la nube definido.

## Notas

- El login usa correo y contraseña. Las contraseñas se guardan con hash.
- Si Gemini no responde, verifica `GEMINI_API_KEY` y que el modelo configurado siga disponible.