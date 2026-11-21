# Guía de defensa — TutorMind AI

**Para qué sirve:** prepararnos para cualquier pregunta del docente, del jurado o del público de la Expo UNINPAHU (23/11/2026) sobre el Documento Técnico (Avance II), el Plan de Trabajo y el código. La sección más importante es la 2: responde la pregunta **"¿TutorMind no es solo una fachada (un *wrapper* o "front") de Gemini?"**.

**Cómo usarla:**

- Cada respuesta tiene una versión corta para decir en voz alta y, cuando hace falta, el detalle técnico con el archivo de código que la respalda.
- Los códigos (RF-07, RN-05, etc.) son los mismos del documento técnico. Citarlos da seguridad y muestra trazabilidad.
- La sección 7 lista las debilidades reales del sistema. Es mejor reconocerlas nosotros antes de que nos las señalen.

**Índice**

- 1. TutorMind en 30 segundos
- 2. LA PREGUNTA CLAVE: "¿No están haciendo solo un front para una IA?"
- 3. Preguntas por sección del documento técnico
- 4. Preguntas técnicas sobre el código
- 5. Números clave para memorizar
- 6. Glosario rápido
- 7. Debilidades reales y cómo responder con honestidad
- 8. Otras preguntas que pueden salir
- 9. Plan de trabajo y puntos de dolor (archivo "PLAN DE TRABAJO - TutorMind.xlsx")
- 10. Base de datos, adaptación de la IA y prompts (explicado a fondo)
- 11. Mapa completo de archivos (rutas)
- 12. Frase de cierre para la defensa

---

## 1. TutorMind en 30 segundos

> TutorMind AI es un tutor virtual para estudiantes universitarios que **recuerda cómo aprende cada estudiante** y cambia su forma de explicar según eso. Guarda un perfil cognitivo con su estilo de aprendizaje, los temas que domina y los que lo frustran. Después de cada respuesta detecta si el estudiante entendió, se confundió o se frustró, y con reglas propias actualiza ese perfil. Además, el profesor tiene un panel donde ve en qué temas se traban sus estudiantes. Gemini solo redacta el texto; la memoria, las reglas pedagógicas, las métricas y el seguimiento docente son nuestros.

**Problema:** en la universidad se explica igual para todos, los chatbots genéricos no recuerdan qué temas dominamos ni qué tipo de explicación nos sirvió, y el profesor no ve en qué se traban sus estudiantes cuando estudian solos.

**Objetivo general:** una aplicación web de tutoría con IA que detecte el estilo de aprendizaje, adapte las explicaciones en tiempo real, mida el progreso por tema y permita al profesor hacer seguimiento.

---

## 2. LA PREGUNTA CLAVE: "¿No están haciendo solo un front para una IA?"

### 2.1 Respuesta corta (decirla en menos de un minuto)

> No. Gemini es un **componente** de nuestro sistema, como lo es SQLite. Gemini no sabe quién es el estudiante, no recuerda sus sesiones anteriores, no sabe qué temas domina ni cuáles lo frustran, no cambia de estrategia por su cuenta con una regla y no tiene un panel para el profesor. Todo eso lo hace nuestro backend. Antes de cada pregunta, TutorMind construye un prompt distinto para cada estudiante a partir de su perfil guardado en la base de datos. Después de cada respuesta, lee la señal de aprendizaje, la guarda como evento y aplica nuestras reglas de negocio: por ejemplo, tres confusiones con el mismo estilo hacen que el sistema cambie de estilo. Si mañana cambiamos Gemini por otro modelo, solo se toca un archivo, `backend/gemini_client.py`, que es menos del 10 % del backend. El resto del sistema sigue igual, y ahí está el valor del proyecto.

### 2.2 La analogía que más ayuda

- **Gemini es el motor; TutorMind es el carro.** Nadie dice que un fabricante de carros "solo hace un front para un motor": el chasis, la dirección, los frenos, el tablero y los sensores son el producto. Nosotros no fabricamos el motor (el modelo de lenguaje), pero sí todo lo que decide hacia dónde va y cómo se mide el recorrido.
- **Otra opción:** un sistema bancario usa una base de datos que no construyó (Oracle o PostgreSQL) y nadie dice que sea "un front de Oracle". Lo mismo pasa con Gemini: es infraestructura, no el producto.
- **Para un profesor de pedagogía:** Gemini es como un profesor sustituto muy bien informado que llega cada clase sin conocer a nadie. TutorMind es la libreta de seguimiento que le entrega antes de cada clase: "este estudiante aprende con ejemplos, ya domina recursión, se frustra con punteros y lleva 25 mensajes, está cansado".

### 2.3 Qué hace Gemini y qué hace TutorMind

| Función | ¿Quién la hace? | Dónde está en el código |
|---|---|---|
| Redactar el texto de la explicación | Gemini | `backend/gemini_client.py` → `stream_chat()` |
| Identificar al usuario, su rol y su carrera | TutorMind | `backend/routers/users.py`, `backend/models.py` |
| Guardar el perfil cognitivo (estilo, temas dominados, temas con frustración, umbral de fatiga, personalidad) | TutorMind | `backend/models.py` → `CognitiveProfile` |
| Construir un prompt distinto para cada estudiante en cada mensaje | TutorMind | `backend/prompt_builder.py` → `build_system_prompt()` |
| Recordar las últimas 3 sesiones y los últimos 20 mensajes | TutorMind | `backend/memory_manager.py` |
| Mantener la conversación en el tema de la sesión (guardrail) | TutorMind (instrucción) + Gemini (la cumple) | `backend/prompt_builder.py` → `topic_guardrail` |
| Detectar fatiga (20 mensajes) y pedir bajar la complejidad | TutorMind | `backend/prompt_builder.py` → `fatigue_note` |
| Clasificar la reacción del estudiante (dato crudo) | Gemini, con el formato que le exigimos | `SIGNAL_INSTRUCTION` |
| Extraer esa señal, ocultarla y guardarla como evento | TutorMind | `backend/memory_manager.py` → `extract_and_update_signals()`, `backend/routers/chat.py` → `_safe_yield_text()` |
| Decidir cambiar de estilo (3 confusiones) o fijar el estilo (primer "entendió") | TutorMind (regla determinista) | `backend/memory_manager.py` → `update_cognitive_profile()` |
| Clasificar cada tema: dominado, aprendiendo, con dificultad, explorando | TutorMind | `backend/analytics.py` → `_topic_status()` |
| Calcular el índice de comprensión (0–100) | TutorMind | `backend/routers/profile.py` |
| Panel del profesor, inscripciones activas y pendientes | TutorMind | `backend/routers/teachers.py`, `frontend/src/app/components/teacher/teacher-dashboard.component.ts` |
| Generar las preguntas del parcial | Gemini | `backend/routers/chat.py` → `generate_exam()` |
| Validar el parcial (4 opciones, índice correcto entre 0 y 3, de 3 a 10 preguntas) y calificarlo (aprueba con 80 %) | TutorMind | `backend/routers/chat.py`, `frontend/src/app/components/chat/chat.component.ts` |
| Proteger la API key y las contraseñas | TutorMind | `.env`, `backend/auth_utils.py` |
| Reintentar con otro modelo y dar mensajes claros si hay error 429 | TutorMind | `backend/gemini_client.py` |

**Conclusión de la tabla:** Gemini aparece en 3 filas (redactar, clasificar la reacción y generar preguntas). Las demás las resuelve nuestro código.

### 2.4 Las siete capas que agregamos sobre la IA

1. **Memoria persistente y estructurada por estudiante (RF-02, RF-11).** Un chatbot genérico empieza de cero o guarda una "memoria" de texto libre. Nosotros guardamos datos estructurados en 6 tablas: estilo, temas dominados, temas con frustración, eventos con fecha, tema y estilo usado.
2. **Prompt dinámico (RF-07).** El prompt no es fijo: se arma en cada mensaje con nombre, carrera, estilo, personalidad, temas dominados, temas con frustración, contexto de las últimas 3 sesiones, tema activo y nota de fatiga. Dos estudiantes que hacen la misma pregunta reciben instrucciones distintas.
3. **Ciclo de retroalimentación con reglas propias (RF-09, RF-10, RN-05 a RN-07).** La IA entrega un dato crudo (`[SIGNAL: event_type=confused, topic=..., style=...]`), pero **la decisión la toma nuestro código**: registrar el evento, agregar el tema a "dominados" o "con frustración" sin duplicados, rotar el estilo tras 3 confusiones con el mismo estilo (analogías → ejemplos → visual → listas → socrático → narrativa) y fijar el estilo con el primer "entendió".
4. **Analítica de aprendizaje (RF-14, RF-15, RN-08, RN-09).** Clasificación de temas e índice de comprensión con fórmulas nuestras, calculadas en Python a partir de la base de datos, sin llamar a la IA.
5. **Rol docente (RF-16 a RF-19, RN-10, RN-11).** El profesor inscribe estudiantes por correo, incluso antes de que se registren (inscripción pendiente que se activa sola), y ve su estilo, sus eventos y su resumen. Ningún chatbot genérico ofrece esto.
6. **Control pedagógico de la conversación (RF-08, RN-03, RN-04).** Sesiones por tema, una sola sesión abierta, guardrail que redirige preguntas fuera del tema y manejo de la fatiga.
7. **Ingeniería de integración (RNF-01 a RNF-05).** Streaming SSE con filtrado en vivo de la etiqueta oculta, API key solo en el servidor, respaldo de modelos y manejo de cuota, validación del JSON del parcial antes de mostrarlo.

### 2.5 La prueba del "cambio de motor" (argumento con números)

- El backend tiene unas **1.920 líneas de Python**. El único archivo que habla con Gemini es `backend/gemini_client.py`, con **185 líneas (≈10 %)**.
- Si cambiáramos Gemini por Claude, GPT o un modelo local (Llama con Ollama), se reescribe solo ese archivo. Perfil, reglas, analítica, panel docente, sesiones, seguridad y base de datos quedan intactos.
- Si TutorMind fuera "solo un front de Gemini", cambiar de modelo obligaría a rehacer el sistema completo. Aquí no pasa eso, y es la prueba de que el valor está en nuestra capa.
- Esto es justo lo que dice la sección 3.3 del documento: "podemos cambiar el modelo de IA (solo se toca `backend/gemini_client.py`)".

### 2.6 Demostración en vivo para convencer (2 minutos)

1. Mostrar el **perfil** de un estudiante en la barra lateral (estilo "en detección").
2. Hacer una pregunta y responder "No entendí" varias veces con el mismo estilo. Mostrar que **el estilo del perfil cambia solo** (RN-05). Eso lo decidió nuestro código, no Gemini.
3. Abrir el **panel del profesor**: aparece el tema "con dificultad", la gráfica de eventos y el resumen. Nada de eso lo produjo la IA en ese momento; se calculó desde la base de datos.
4. Hacer una pregunta fuera del tema: el tutor redirige al tema de la sesión (RF-08).
5. (Opcional) Abrir `http://localhost:8000/docs` y mostrar que hay 18 endpoints y solo 3 llaman a Gemini (mensaje, parcial y título automático).

### 2.7 Repreguntas difíciles y cómo responderlas

**"Pero la señal [SIGNAL] la genera la propia IA. Entonces la adaptación sigue siendo de la IA."**
> La IA hace de **sensor**: clasifica la reacción del estudiante, igual que un termómetro mide la temperatura. Pero el termostato es nuestro: qué se guarda, cuándo se cambia el estilo, cuándo un tema pasa a "con dificultad" y qué ve el profesor lo deciden reglas deterministas que escribimos (RN-05 a RN-09). Además, el estudiante también genera señales directas con los botones "Ya entendí" y "No entendí". Reconocemos que el sensor puede equivocarse, y por eso en el siguiente avance tenemos planeadas pruebas de calidad de la detección.

**"ChatGPT y Gemini ya tienen memoria. ¿Qué aportan?"**
> Esa memoria es genérica, de texto libre, y no la ve nadie más que el usuario. La nuestra está **estructurada por tema y por evento**, aplica reglas pedagógicas (rotación de estilos, fatiga), produce métricas (índice de comprensión, estado de cada tema) y **la ve el profesor**. Además, nadie ofrece por defecto un vínculo profesor–estudiante con inscripciones.

**"¿Por qué no usar un GPT personalizado o una Gem de Gemini?"**
> Una Gem tiene instrucciones **fijas**, iguales para todos. Nuestro prompt cambia con cada estudiante y con cada mensaje. Una Gem no guarda eventos en una base de datos, no calcula estadísticas, no tiene roles ni panel docente y no podemos poner reglas como "3 confusiones = cambio de estilo".

**"¿Por qué no entrenaron su propio modelo?"**
> Porque no es el problema que resolvemos. Entrenar un modelo de lenguaje cuesta millones de dólares y requiere datos que no tenemos. En ingeniería de software lo normal es **integrar componentes** probados: no construimos nuestra propia base de datos ni nuestro propio framework web, y tampoco nuestro propio LLM. Lo que diseñamos es la lógica de negocio alrededor. Además, **ajustar (fine-tuning)** un modelo no daría memoria por estudiante, que es lo central del proyecto.

**"Si Gemini se cae, ¿el sistema no sirve?"**
> El chat depende de Gemini (está en las restricciones, sección 1.7). Pero el registro, el login, las sesiones, el historial, las estadísticas y el panel docente siguen funcionando porque no dependen de la IA. Además, el cliente tiene un mecanismo de respaldo para probar otro modelo permitido y muestra mensajes claros si hay error 429.

**"¿Qué parte del proyecto es realmente ingeniería?"**
> Los requerimientos con criterios de aceptación (20 RF, 10 RNF, 12 RN), el MER con 6 entidades normalizadas, el BPMN del ciclo de tutoría, el modelo C4 en 4 niveles, la arquitectura en capas, la seguridad (hash, CORS, `.env`), el streaming y la trazabilidad completa desde la necesidad hasta el archivo de código.

**"¿Cualquiera podría hacer esto en un fin de semana?"**
> El chat básico, quizás. Pero no el perfil cognitivo, el ciclo de señales con reglas, la analítica por tema, las inscripciones pendientes que se activan solas, el filtrado en vivo de la etiqueta durante el streaming ni la trazabilidad. Esa es la diferencia entre un prototipo de chat y un sistema.

---

## 3. Preguntas por sección del documento técnico

### 3.1 Requerimientos (sección 1)

**¿Quiénes son los actores?** Estudiante (rol `student`), Profesor (rol `teacher`), Google Gemini (sistema externo) y el propio sistema TutorMind como actor interno que procesa señales y actualiza el perfil sin que el estudiante lo note.

**¿Por qué Gemini es un actor?** En UML y en C4 un sistema externo con el que interactuamos se modela como actor: no lo controlamos, solo intercambiamos mensajes.

**¿Cuántos requerimientos hay?** 20 funcionales (RF-01 a RF-20), 10 no funcionales (RNF-01 a RNF-10) y 12 reglas de negocio (RN-01 a RN-12). Cada RF tiene un criterio de aceptación para poder probarlo.

**Diferencia entre RF, RNF y RN.** RF: lo que el sistema hace (registrar, chatear, generar parcial). RNF: cómo lo hace (rendimiento, seguridad, usabilidad, portabilidad). RN: políticas del dominio que el sistema debe respetar (correo único, 3 confusiones cambian el estilo, se aprueba con 80 %).

**Ejemplos de criterio de aceptación para memorizar:**

- RF-01: correo ya usado → error 400.
- RF-03: contraseña errónea → 401; correo inexistente → 404.
- RF-10: 3 confusiones con el mismo estilo → siguiente estilo de la rotación.
- RF-12: de 3 a 10 preguntas, cada una con 4 opciones.
- RF-15: 2 o más frustraciones → tema "con dificultad".
- RF-20: si la sesión se llama "Nueva sesión", se genera un título de 2 a 5 palabras; si la IA tarda más de 8 s, se usan las primeras palabras de la pregunta.

**Reglas de negocio más preguntables:**

- RN-03: un estudiante solo tiene una sesión abierta; al crear otra, las anteriores se cierran (`ended_at`).
- RN-04: umbral de fatiga de 20 mensajes → bajar complejidad y sugerir pausas.
- RN-05: rotación analogías → ejemplos → visual → listas → socrático → narrativa.
- RN-06: el primer "entendió", si el estilo es `unknown`, fija ese estilo.
- RN-08: estado de un tema: dominado si está en la lista; con dificultad si tiene 2+ frustraciones o 3+ confusiones sin ningún "entendió"; aprendiendo si tiene 2+ "entendió" o 1 dominado; si no, explorando.
- RN-09: índice = (entendió + dominado) / (entendió + confusión + frustración) × 100, limitado entre 0 y 100.
- RN-10 / RN-11: un profesor no puede inscribirse a sí mismo, ni inscribir a otro profesor, ni repetir correo; solo `teacher` usa el panel (si no, 403).

**¿Por qué el índice puede pasar de 100 y por eso se limita?** Porque "dominado" suma en el numerador pero no en el denominador. Se limita con `max(0, min(100, ...))`.

### 3.2 Stack tecnológico (sección 2)

| Pregunta | Respuesta |
|---|---|
| ¿Por qué Angular? | Trae rutas, formularios, cliente HTTP e inyección de dependencias integrados. Componentes *standalone* (sin NgModule) y *signals* para refrescar el perfil tras cada respuesta. TypeScript detecta errores al compilar. |
| ¿Por qué FastAPI? | Asíncrono, rápido, soporta `StreamingResponse` (necesario para SSE), valida con Pydantic y genera Swagger en `/docs` automáticamente. |
| ¿Por qué Python? | Mejor ecosistema para IA, SDK oficial de Gemini y expresiones regulares cómodas para leer `[SIGNAL]`. |
| ¿Por qué SQLite? | Datos relacionados (claves foráneas), cero instalación, un solo archivo: el docente lo ejecuta sin configurar nada. |
| ¿Por qué SQLAlchemy? | ORM: trabajamos con clases en vez de SQL a mano y cambiamos a PostgreSQL solo con `DATABASE_URL`. |
| ¿Por qué SSE y no WebSockets? | La comunicación es en un solo sentido (servidor → navegador), SSE funciona sobre HTTP normal y es más simple. WebSockets sería bidireccional y no lo necesitamos. |
| ¿Por qué Gemini y no OpenAI? | Plan gratuito, instrucciones de sistema (para inyectar el perfil), historial de chat y streaming. Flash es rápido y barato. |
| ¿Por qué `gemini-3.5-flash-lite`? | Plan gratuito con límite de peticiones por minuto; los modelos 1.5 ya no están disponibles para cuentas nuevas y los Flash más grandes no respondían a tiempo con nuestra clave. |
| ¿Por qué PBKDF2 y no bcrypt? | Viene en la librería estándar de Python (`hashlib`), sin dependencias extra, y es un algoritmo recomendado con sal y 100.000 iteraciones. bcrypt o Argon2 también serían válidos. |

### 3.3 Arquitectura (sección 3)

**¿Qué arquitectura es?** Cliente-servidor en tres capas: SPA Angular → API REST FastAPI → datos (SQLite) e IA (Gemini). El navegador nunca habla directo con Gemini ni con la base de datos.

**¿Por qué no llamar a Gemini directo desde Angular?** 1) La API key quedaría visible en el navegador. 2) El ciclo "leer perfil → armar prompt → llamar IA → leer señal → guardar evento" debe ser una sola operación en un punto central. 3) Esa es justamente la capa que hace que no seamos un front de la IA.

**¿Por qué no microservicios?** Equipo pequeño, un solo dominio y dos procesos. Los microservicios agregarían complejidad (red, despliegue, consistencia) sin beneficio a este tamaño.

**Capas del backend:** routers (API) → lógica de dominio (`prompt_builder`, `memory_manager`, `analytics`, `auth_utils`) → datos (`models`, `database`, `schemas`) → integración (`gemini_client`).

**Formatos de comunicación:** navegador–API con HTTP/JSON (REST); API–navegador en el chat con SSE (`text/event-stream`, eventos `data`, `session-title`, `done`, `stream-error`); API–SQLite con SQL generado por SQLAlchemy; API–Gemini con HTTPS mediante el SDK `google-generativeai` y `stream=True`.

**¿Qué es el proxy de Angular?** `frontend/proxy.conf.json` redirige `/api` a `http://127.0.0.1:8000` en desarrollo, así no hay problemas de CORS.

### 3.4 MER (sección 4)

**Entidades (6):** `users`, `cognitive_profiles`, `sessions`, `messages`, `learning_events`, `teacher_students`.

**Relaciones:**

- users 1 : 0..1 cognitive_profiles (solo estudiantes; `user_id` UNIQUE garantiza el 1 a 1).
- users 1 : N sessions; sessions 1 : N messages.
- users 1 : N learning_events.
- users (profesor) 1 : N teacher_students; users (estudiante) 1 : N teacher_students.

**¿Por qué existe `teacher_students`?** Resuelve la relación muchos a muchos profesor–estudiante y además guarda `status` (`pending`/`active`) y `student_email`, para poder inscribir a alguien que aún no se ha registrado. Por eso `student_id` admite NULL.

**¿Por qué los temas se guardan como JSON en texto?** Para no crear una tabla extra en esta versión. Lo reconocemos en el documento: si el sistema crece, se normalizan en una tabla `topics`. Si preguntan por normalización: técnicamente viola la primera forma normal (no es atómico), y fue una decisión consciente de simplicidad.

**¿Por qué no hay CHECK en la base para `role`, `event_type` y `status`?** Se controlan en la aplicación (Pydantic y lógica del backend). Es una decisión aceptable en SQLite; en PostgreSQL se agregarían CHECK o ENUM.

**¿Cómo se borra una sesión?** El código borra primero sus mensajes y luego la sesión (cascada hecha en código, en `delete_session`).

**¿Por qué `learning_events` guarda `explanation_style`?** Para aplicar RN-05: contar confusiones *con el mismo estilo* y decidir la rotación.

### 3.5 BPMN (sección 5)

**¿Qué proceso modelaron?** El proceso central del negocio, el ciclo de tutoría adaptativa, no la navegación entre pantallas.

**Elementos:** 2 pools (TutorMind AI y Google Gemini), 2 lanes dentro de TutorMind (Estudiante y Sistema), 4 gateways exclusivos, flujos de secuencia (líneas continuas) dentro del pool y flujos de mensaje (punteadas) con Gemini.

**Los 4 gateways:**

1. ¿Mensajes ≥ umbral de fatiga? (RN-04)
2. ¿Trae etiqueta [SIGNAL]? (RF-09)
3. ¿3 confusiones con el mismo estilo? (RF-10, RN-05)
4. ¿Sigue estudiando? (bucle que vuelve a "Escribir pregunta")

**¿Por qué Gemini es un pool separado y no una lane?** Porque es un participante externo que no controlamos; en BPMN, los participantes externos van en su propio pool y solo se comunican por flujos de mensaje.

**¿Qué es un gateway exclusivo (XOR)?** Un rombo con X donde solo se toma un camino según la condición.

**Excepción:** si Gemini falla o no hay cuota, se prueba otro modelo permitido; si todos fallan, se envía `stream-error` y el estudiante puede reintentar.

### 3.6 Modelo C4 (sección 6)

| Nivel | Qué muestra | En TutorMind |
|---|---|---|
| 1. Contexto | El sistema, sus usuarios y los sistemas externos | Estudiante, Profesor → TutorMind AI → Google Gemini |
| 2. Contenedores | Unidades que se ejecutan por separado | SPA Angular (4200), API FastAPI (8000), SQLite (`tutormind.db`) |
| 3. Componentes | Partes internas de un contenedor | API: 4 routers + 6 componentes (Auth Utils, Prompt Builder, Memory Manager, Analytics, Gemini Client, Capa de datos) |
| 4. Código | Clases y funciones de un flujo | Flujo "enviar mensaje": `ChatService.sendMessage()` → `send_message()` → `_sse_generator_body()` → `build_system_prompt()` + `get_conversation_history()` → `stream_chat()` → `_safe_yield_text()` → `extract_and_update_signals()` → `update_cognitive_profile()` |

**¿Por qué descompusieron la API en el nivel 3 y no el frontend?** Porque ahí está la lógica que hace único al sistema (y la que responde a la pregunta del "front de una IA").

**¿Gemini es un contenedor?** No. Es un sistema externo; aparece en el nivel 1 y se mantiene como externo en los demás niveles.

**¿Qué significa "coherencia entre niveles"?** Cada nivel abre una caja del anterior y los nombres se repiten a propósito (tabla 6.5 del documento).

### 3.7 Repositorio y trazabilidad (secciones 7 y 8)

- Repositorio público: `github.com/David78-beto/TutorMind`.
- El `.env` está en `.gitignore`; solo se sube `.env.example` sin secretos.
- Variables: `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_ALLOWED_MODELS`, `DATABASE_URL`, `ALLOWED_ORIGINS`.
- Ejecución: `uvicorn main:app --reload` en `backend` (puerto 8000, Swagger en `/docs`) y `npm start` en `frontend` (puerto 4200), o `iniciar.bat` con doble clic.
- **Trazabilidad:** cada necesidad se sigue hasta el requerimiento, el proceso BPMN, el componente C4, la tabla del MER y el archivo de código. Ejemplo para decir de memoria: *"Explicaciones adaptadas" → RF-07, RF-10, RN-05 → tarea "Construir prompt con el perfil" → Prompt Builder y Memory Manager → `cognitive_profiles` → `backend/prompt_builder.py` y `backend/memory_manager.py`.*

---

## 4. Preguntas técnicas sobre el código

**¿Cómo funciona el streaming?** Gemini devuelve fragmentos (`stream=True`). El backend los reenvía como eventos SSE (`data: "..."`) dentro de un `StreamingResponse`. El frontend lee la respuesta por partes con `readSseResponse()` (`frontend/src/app/services/chat.service.ts`) y pinta el texto mientras llega. Al final se envía el evento `done`.

**¿Cómo evitan que el estudiante vea la etiqueta [SIGNAL] si llega por partes?** Con `_safe_yield_text()` en `backend/routers/chat.py`: si el texto acumulado contiene `[SIGNAL:`, solo se envía lo anterior. Si el texto termina con un pedazo que *podría* ser el comienzo de la etiqueta (por ejemplo `[SIG`), se retiene hasta saber si lo es. Es un detalle fino de ingeniería: la etiqueta puede llegar cortada entre dos fragmentos.

**¿Cómo leen la señal?** Con una expresión regular en `backend/memory_manager.py`:
`\[SIGNAL:\s*event_type=(\w+),\s*topic=([^,\]]+),\s*style=([^\]]+)\]`. Si coincide, se llama a `update_cognitive_profile()` y se guarda el mensaje ya sin la etiqueta.

**¿Qué pasa si la IA no pone la señal?** No se registra evento y la respuesta se guarda tal cual. El sistema no falla (gateway 2 del BPMN).

**¿Cómo se guarda la contraseña?** `pbkdf2_sha256$<sal>$<hash>`: sal aleatoria de 16 bytes con `secrets.token_hex`, 100.000 iteraciones de SHA-256. Para verificar se recalcula y se compara con `secrets.compare_digest` (comparación en tiempo constante, evita ataques de temporización).

**¿Qué es CORS?** La regla del navegador que define qué páginas pueden llamar a la API. Solo se aceptan los orígenes de `ALLOWED_ORIGINS`.

**¿Qué valida Pydantic?** Correo válido, contraseña de 6 a 128 caracteres, rol `student` o `teacher`, y la forma de las respuestas.

**¿Cuánto historial se envía a Gemini?** Los últimos 20 mensajes de la sesión, más un resumen de las últimas 3 sesiones en el prompt de sistema. Así se controla el costo en tokens y la latencia.

**¿Cómo se genera el parcial?** Se le pide a Gemini un JSON estricto. El backend lo parsea, descarta preguntas sin texto o sin exactamente 4 opciones, limita `correct_index` entre 0 y 3 y el número de preguntas entre 3 y 10. Si el JSON es inválido, responde 500 con un mensaje claro. La calificación se hace en el frontend y se aprueba con 80 %.

**¿Cómo funciona el título automático?** Si la sesión se llama "Nueva sesión", después de la primera respuesta se hace una llamada corta a Gemini con un tiempo límite de 8 s. Si falla, se toman las primeras 5 palabras de la pregunta. Se envía al frontend con el evento SSE `session-title`.

**¿Cómo funciona el respaldo de modelos?** `_resolve_models_to_try()` cruza los modelos preferidos con los disponibles y permitidos. Si uno falla, se intenta el siguiente. Si es error de cuota (429), se extrae el tiempo de espera del mensaje y se muestra "Espera ~N s y reintenta".

**¿Cómo se activa una inscripción pendiente?** Al registrarse un estudiante, `backend/routers/users.py` busca inscripciones con su correo en estado `pending`, les asigna el `student_id` y las pasa a `active` (RF-17).

---

## 5. Números clave para memorizar

| Dato | Valor |
|---|---|
| Requerimientos funcionales / no funcionales / reglas de negocio | 20 / 10 / 12 |
| Entidades del MER | 6 |
| Componentes del backend en C4 nivel 3 | 10 (4 routers + 6 de apoyo) |
| Endpoints de la API | 18 |
| Estilos de aprendizaje en la rotación | 6 |
| Personalidades del tutor | 4 (neutral, patient, challenger, playful) |
| Tipos de evento | 5 (understood, confused, frustrated, mastered, neutral) |
| Umbral de fatiga por defecto | 20 mensajes |
| Duración preferida de sesión por defecto | 25 minutos |
| Confusiones para cambiar de estilo | 3 con el mismo estilo |
| Frustraciones para "con dificultad" | 2 o más |
| Historial enviado a Gemini | últimos 20 mensajes + últimas 3 sesiones |
| Parcial | 3 a 10 preguntas, 4 opciones, aprueba con 80 % |
| Título automático | 2 a 5 palabras, tiempo límite de 8 s |
| Contraseña | 6 a 128 caracteres; PBKDF2-SHA256, 100.000 iteraciones |
| Líneas del backend / del cliente de IA | ≈1.920 / 185 (≈10 %) |
| Puertos | 4200 (Angular), 8000 (API) |

---

## 6. Glosario rápido

- **Wrapper / "front de una IA":** aplicación que solo pasa el mensaje del usuario a un modelo y devuelve la respuesta, sin lógica propia. TutorMind no lo es (sección 2).
- **LLM:** modelo de lenguaje grande (Gemini, GPT, Claude). Genera texto, pero no guarda estado entre llamadas.
- **Prompt de sistema (system instruction):** instrucciones que definen cómo se comporta el modelo. El nuestro se construye en cada mensaje.
- **SSE (Server-Sent Events):** el servidor envía datos al navegador por partes sobre una conexión HTTP.
- **ORM:** mapeo objeto-relacional; trabajar con clases en vez de SQL.
- **SPA:** aplicación de una sola página que cambia de vista sin recargar.
- **Hash con sal:** transformación irreversible de la contraseña con un valor aleatorio para que dos contraseñas iguales no den el mismo hash.
- **Rate limit / 429:** límite de peticiones por minuto del proveedor.
- **Guardrail:** regla que limita lo que la IA puede responder (aquí, mantenerse en el tema).
- **Gateway exclusivo (BPMN):** decisión en la que solo se toma un camino.
- **Fine-tuning:** reentrenar un modelo con datos propios. No lo usamos porque no da memoria por estudiante.

---

## 7. Debilidades reales y cómo responder con honestidad

Es mejor reconocerlas nosotros. La fórmula es: **"Sí, es una limitación conocida; la decidimos por X y la resolvemos así en el siguiente avance."**

| Debilidad | Respuesta preparada |
|---|---|
| **No hay JWT: la API confía en el id que llega en la URL.** Cualquiera que cambie el número en la URL podría ver datos de otro usuario. | Está declarada en la sección 1.7 y en el README. Priorizamos el núcleo adaptativo; en el siguiente avance se implementa JWT y cada endpoint validará que el token corresponda al usuario. |
| **La señal la decide la IA y puede equivocarse** (por ejemplo, marcar "understood" cuando el estudiante no entendió). | La IA es el sensor y las reglas son nuestras. Mitigamos con botones explícitos ("Ya entendí", "No entendí") y con umbrales (3 confusiones, 2 frustraciones) que evitan reaccionar a un solo error. Las pruebas de calidad de la detección están planeadas en las conclusiones. |
| **El tema de la señal es texto libre**: "Recursión" y "recursividad" pueden contarse como temas distintos. | Es cierto. Mejora prevista: normalizar los temas en una tabla `topics` (ya mencionada en la sección 4.3) o usar el tema de la sesión como referencia. |
| **La rotación cuenta las últimas 3 confusiones con ese estilo, no necesariamente seguidas ni de la misma sesión.** | Es una simplificación intencional del criterio. Se puede refinar limitando la ventana a la sesión actual o a un periodo de tiempo. |
| **Las respuestas correctas del parcial viajan al navegador** (`correct_index`) y la calificación es local; un estudiante técnico podría verlas. | El parcial es de autoevaluación, no calificable. Si fuera evaluativo, la corrección debe hacerse en el servidor (el endpoint `exam/submit` ya existe para eso). |
| **El resultado del parcial no alimenta el perfil cognitivo.** | Mejora natural: registrar cada pregunta fallada como evento `confused` del tema y cada parcial aprobado como `mastered`. |
| **La personalidad del tutor no se elige desde la interfaz** (solo por la API `PATCH /api/profile`). | El backend ya la soporta; falta la pantalla de configuración en el frontend. |
| **No hay pruebas automatizadas.** | Los RF tienen criterios de aceptación pensados para convertirse en pruebas (pytest para el backend). Está en las conclusiones como pendiente. |
| **SQLite no escala a muchos usuarios simultáneos.** | Se pasa a PostgreSQL cambiando solo `DATABASE_URL` gracias a SQLAlchemy (RNF-08). |
| **Solo hay un modelo configurado, así que el respaldo no actúa en la práctica.** | El mecanismo está en el código; basta con agregar más modelos en `GEMINI_ALLOWED_MODELS`. |
| **Dependencia total de Gemini para el chat.** | Declarada en restricciones. La arquitectura aísla la IA en un archivo, así que cambiar de proveedor o usar un modelo local es viable. |
| **Privacidad:** los mensajes del estudiante se envían a Google. | Se debe informar al usuario y aceptar términos. En producción se revisaría con la Ley 1581 de 2012 (protección de datos personales en Colombia) y se evitaría enviar datos sensibles innecesarios. |
| **Sin despliegue en la nube.** | Propuesta: backend en Render o Railway, frontend en Vercel o Netlify, PostgreSQL gestionado. |

---

## 8. Otras preguntas que pueden salir

**¿Cómo detectan el estilo de aprendizaje si el estudiante nunca lo dice?** Empieza en `unknown`, y en ese caso el prompt pide variar entre analogías, ejemplos, listas y preguntas. El primer "entendió" con un estilo lo fija (RN-06). Si después se confunde 3 veces con ese estilo, rota al siguiente (RN-05).

**¿Los estilos de aprendizaje tienen base científica?** Pregunta delicada. Responder: *"La teoría de estilos fijos (VARK) es discutida en la literatura. Por eso no le preguntamos al estudiante su estilo ni lo dejamos fijo para siempre: lo inferimos de su comportamiento y lo cambiamos cuando no funciona. Es más bien una estrategia de enseñanza adaptativa basada en evidencia de uso."*

**¿Qué pasa si el estudiante pregunta algo que no es del tema?** El guardrail del prompt hace que el tutor responda que está fuera del tema y lo invite a crear una sesión nueva o cambiar el tema (RF-08).

**¿La IA puede dar respuestas incorrectas (alucinaciones)?** Sí, es un riesgo de cualquier LLM. Mitigaciones: instrucciones de verificación ("haz una pregunta de verificación al final"), tema acotado por sesión y, a futuro, pruebas de calidad y la opción de que el profesor revise. TutorMind es un apoyo, no reemplaza al docente.

**¿El estudiante puede hacer trampa pidiéndole las respuestas de una tarea?** El estilo socrático y las reglas del prompt priorizan la comprensión. Se podría reforzar con una regla explícita de no resolver tareas completas.

**¿Cuánto cuesta operar el sistema?** Hoy, nada: plan gratuito de Gemini y ejecución local. En producción, el costo principal sería por tokens; por eso se envían solo 20 mensajes de historial y se usa un modelo Flash ligero.

**¿Qué haría falta para usarlo en la universidad?** JWT, despliegue en la nube, PostgreSQL, pruebas, aviso de privacidad, una pantalla de configuración del perfil y, quizás, integración con el LMS de la universidad.

**¿Qué aprendieron?** Integrar un servicio de IA en una arquitectura en capas, diseñar reglas de negocio medibles, modelar con MER, BPMN y C4, y mantener trazabilidad entre documentación y código.

**¿Cuál es la parte más interesante?** El ciclo de señales: el tutor responde, se autoevalúa con `[SIGNAL]` y el sistema usa eso para cambiar cómo explica la siguiente vez (conclusión 3 del documento).

---

## 9. Plan de trabajo y puntos de dolor (archivo "PLAN DE TRABAJO - TutorMind.xlsx")

### 9.1 Contexto que hay que saber decir

- El proyecto **viene del semestre 2026-1** (idea, requerimientos, arquitectura y primera versión del chat). En el **semestre 2026-2 (29/09/2026 – 20/11/2026)** lo estamos puliendo.
- **Por indicación de los docentes, el foco de este semestre es el diseño** (inicio de sesión y cómo se ve la app) **con una IA básica integrada**.
- Fechas clave: entrega final el **20/11/2026** y **Expo UNINPAHU el lunes 23/11/2026**.
- **Avance general: 69 %**. Es el promedio de las 7 fases sin contar "Fuera de alcance".

### 9.2 Fases, avance y responsables

| Fase | Avance | Qué incluye | Responsables |
|---|---|---|---|
| 1. Base del proyecto (2026-1) | 100 % | Idea y propuesta; requerimientos; stack y arquitectura; primera versión del chat con IA | Sergio (idea), Edilson (requerimientos), David (arquitectura y chat) |
| 2. Planeación 2026-2 | 100 % | Revisión del alcance con docentes; Entrega 1 (SRS, UML, presentación); plan de trabajo y puntos de dolor | Equipo; Sergio (Entrega 1) |
| 3. Diseño de la interfaz (foco del semestre) | 83 % | Rediseño de login y registro; chat y barra lateral; panel de estadísticas; panel del profesor; gestión de sesiones (renombrar, íconos por materia, orden). **Pendiente:** ajustes visuales finales y pantallas pequeñas | Edilson (login, panel del profesor), David (chat, ajustes finales), Sergio (estadísticas, sesiones) |
| 4. Integración básica de IA | 100 % | Conexión con Gemini y SSE; cambio a `gemini-3.5-flash-lite`; nombre automático de sesiones | David (Gemini + SSE), Sergio (cambio de modelo), Edilson (título automático) |
| 5. Documentación técnica | 100 % | Avance II (MER, BPMN, C4); actualización del documento, README e `iniciar.bat` | Sergio (Avance II), Edilson (actualización) |
| 6. Pruebas de la IA | 0 % (programadas del 16 al 19/11) | Calidad de respuestas por materia; detección de estilo y señales; parcial; errores, cuota y lentitud; pruebas manuales de la interfaz | David (calidad, errores), Sergio (estilo y señales), Edilson (parcial, interfaz) |
| 7. Cierre y Expo | 0 % (programado del 17 al 23/11) | Presentación y guion de la demo; ensayo; entrega final; Expo | Sergio (presentación), David (ensayo), Edilson (entrega), Equipo (Expo) |
| 8. Fuera de alcance 2026-2 | — | JWT; pruebas automatizadas; PostgreSQL y nube | Próximo semestre |

> **Importante antes de la defensa:** el Excel muestra las fases 6 y 7 en 0 %, pero ya estamos en la fecha de entrega. Si hicieron pruebas o ensayaron la demo, **actualicen los porcentajes** antes de mostrar el archivo. Si no, digan con honestidad que las pruebas formales de la IA son el pendiente principal (así está escrito en el punto de dolor "Pruebas de la IA pendientes" y en las conclusiones del documento técnico).

**¿Cómo se repartió el trabajo?** Por igual entre los tres. Cada actividad tiene un responsable y las marcadas "Equipo (los 3)" son compartidas. Cada integrante debe poder explicar al menos sus propias actividades:

- **Edilson:** requerimientos (RF, RNF, RN), login y registro (`frontend/src/app/components/onboarding/onboarding.component.ts`), panel del profesor (`frontend/src/app/components/teacher/teacher-dashboard.component.ts`), título automático de sesiones, actualización del documento técnico.
- **David:** stack y arquitectura, primera versión del chat, chat y barra lateral (`frontend/src/app/components/chat/chat.component.ts`), conexión con Gemini y SSE (`backend/gemini_client.py`), ensayo de la demo.
- **Sergio:** idea y problema, Entrega 1 (SRS y UML), panel de estadísticas (`frontend/src/app/components/bar-chart/bar-chart.component.ts`), gestión de sesiones, cambio de modelo, Avance II (MER, BPMN, C4), presentación.

### 9.3 Puntos de dolor (riesgos) y cómo los manejamos

| Punto de dolor | Peso | Cómo lo manejamos | Estado |
|---|---|---|---|
| Tiempo limitado del semestre (≈8 semanas y otras materias) | 20 % | Alcance reducido a diseño + IA básica, acordado con los docentes; plan semanal | Controlado |
| Dependencia de la API de Gemini (Google retiró los modelos que usábamos) | 18 % | Cambio a `gemini-3.5-flash-lite`; el código prueba otro modelo si uno falla | Ocurrió, mitigado |
| Pruebas de la IA pendientes | 15 % | Semana del 16/11 dedicada a pruebas, repartidas entre los tres | Abierto |
| Curva de aprendizaje (Angular + FastAPI) | 10 % | Trabajo en pareja y documentación del repositorio | Controlado |
| Coordinación del equipo | 10 % | Responsable por actividad y revisión del avance en cada clase | Controlado |
| Demo en vivo en la Expo (internet y cuota gratuita) | 7 % | Ensayo previo, `iniciar.bat` y conversaciones de ejemplo ya guardadas | Abierto |
| Seguridad básica (sin JWT) | 7 % | Limitación aceptada del prototipo; JWT el próximo semestre | Aceptado |
| Manejo de la clave de la API | 7 % | `.env` en `.gitignore`; solo `.env.example` en el repositorio | Controlado |
| Base de datos local, sin despliegue | 6 % | Suficiente para la demo; PostgreSQL y nube el próximo semestre | Aceptado |

**Si preguntan "¿cuál fue el problema más grande?":** la dependencia de Gemini. Google retiró los modelos 1.5 y los Flash más grandes no respondían a tiempo con nuestra clave. Gracias a que la IA está aislada en `backend/gemini_client.py`, el cambio se hizo en un día (actividad 4.2, 14/11) cambiando una variable de entorno, sin tocar el resto del sistema. **Este caso real es la mejor prueba de que no somos un front de la IA:** cambiamos de modelo y TutorMind siguió funcionando igual.

### 9.4 Cuidado con la frase "IA básica"

El plan dice que el foco del semestre es "diseño con una IA básica integrada". Alguien puede usarlo en nuestra contra: *"Si la IA es básica y el foco fue el diseño, entonces es solo una interfaz bonita sobre Gemini."* Respuesta:

> "Básica se refiere a que **no entrenamos ni ajustamos un modelo propio**: usamos Gemini tal como lo ofrece Google, con su plan gratuito, que fue lo acordado con los docentes. Pero la lógica que lo rodea no es básica: perfil cognitivo persistente, prompt dinámico por estudiante, ciclo de señales con reglas de negocio, analítica por tema y panel del profesor. Esa lógica ya existía desde 2026-1 y este semestre la hicimos visible con el diseño: la barra lateral muestra el estilo detectado, las estadísticas muestran el índice de comprensión y el panel docente muestra los temas con dificultad. El diseño no tapa la IA: muestra lo que nuestro sistema sabe del estudiante."

### 9.5 Preguntas típicas de una Expo (público general)

En la Expo pueden preguntar personas que no son ingenieros. Respuestas cortas y sin tecnicismos:

- **"¿Qué es esto?"** Un tutor con inteligencia artificial que aprende cómo aprendes tú. Si no entiendes con un ejemplo, cambia a una analogía o a pasos; y tu profesor puede ver en qué temas necesitas ayuda.
- **"¿En qué se diferencia de ChatGPT?"** ChatGPT te responde igual que a todos. TutorMind recuerda tus temas, nota cuando te frustras, cambia su forma de explicar y le avisa a tu profesor.
- **"¿La IA la hicieron ustedes?"** El modelo que escribe el texto es de Google (Gemini), así como una app usa los mapas de Google sin haber hecho los satélites. Lo nuestro es todo lo que decide cómo explicar, qué recordar y qué mostrar al profesor.
- **"¿Es gratis?"** Hoy sí: corre en local con el plan gratuito de Gemini.
- **"¿Mis datos están seguros?"** Las contraseñas se guardan cifradas y la clave de la IA nunca llega al navegador. Para usarlo en la universidad falta agregar tokens de sesión (JWT), que es lo siguiente en el plan.
- **"¿Ya se puede usar?"** Es un prototipo funcional que corre en local; el próximo paso es desplegarlo en la nube.

**Plan B para la demo** (punto de dolor "Demo en vivo"): tener conversaciones de ejemplo ya guardadas y capturas de pantalla del perfil, las estadísticas y el panel del profesor por si falla internet o se acaba la cuota. Si aparece el error 429, explicarlo como ventaja: "el sistema detectó el límite de Google y muestra un mensaje claro; en 30 segundos se puede reintentar".

---


## 10. Base de datos, adaptación de la IA y prompts (explicado a fondo)

### 10.1 ¿Qué base de datos usamos y por qué?

**Usamos SQLite**, manejada con el ORM **SQLAlchemy**. La base de datos es un solo archivo: `backend/tutormind.db`, que se crea solo al arrancar el backend desde la carpeta `backend` (por eso el README pide ejecutar `uvicorn` ahí). La ruta se define con la variable `DATABASE_URL=sqlite:///./tutormind.db` en `.env`.

**Por qué SQLite (decirlo así):**

1. **Nuestros datos son relacionales.** Usuarios → sesiones → mensajes, usuarios → eventos, profesor ↔ estudiante. Necesitamos claves foráneas y consultas con JOIN, así que una base relacional es lo correcto (no una NoSQL como MongoDB).
2. **No requiere instalar un servidor.** Es un archivo; el docente o cualquier evaluador clona el repositorio y funciona sin configurar MySQL o PostgreSQL.
3. **Es suficiente para el alcance.** Prototipo local, pocos usuarios a la vez, demo en la Expo.
4. **No nos amarra.** Con SQLAlchemy, pasar a PostgreSQL en producción es cambiar `DATABASE_URL` (RNF-08), sin reescribir consultas.

**Repreguntas:**

- *"¿Por qué no MySQL o PostgreSQL desde el inicio?"* Exigen instalar y configurar un servidor; para un prototipo local no aportan nada y complican la ejecución. PostgreSQL es el destino planeado para producción (punto 8.3 del plan de trabajo).
- *"¿Por qué no MongoDB?"* Los datos tienen relaciones fijas y necesitamos integridad (correo único, perfil 1 a 1). Lo relacional encaja mejor.
- *"¿Limitaciones de SQLite?"* Una sola escritura a la vez y no está pensado para muchos usuarios concurrentes ni para un servidor en la nube con varias instancias.
- *"¿Dónde se crean las tablas?"* Se definen como clases en `backend/models.py` y se crean y migran al arrancar con `backend/database.py` (`run_migrations()`, línea 17).
- *"¿Qué tablas hay?"* `users`, `cognitive_profiles`, `sessions`, `messages`, `learning_events`, `teacher_students` (sección 3.4 de esta guía).

### 10.2 Aclaración clave: NO entrenamos a la IA

Si alguien dice "¿dónde están los prompts para **entrenar** la IA?", hay que corregir con cuidado:

> "No entrenamos el modelo. Entrenar significa cambiar los pesos internos de la red neuronal con miles de ejemplos, y eso lo hizo Google. Nosotros hacemos **ingeniería de prompts con contexto dinámico**: en **cada mensaje** le enviamos a Gemini unas instrucciones de sistema construidas a partir del perfil del estudiante guardado en nuestra base de datos. La IA no aprende ni recuerda nada entre llamadas; **quien aprende y recuerda es TutorMind**, porque guarda el perfil y los eventos en SQLite y los vuelve a inyectar en el siguiente mensaje."

| Concepto | ¿Lo usamos? | Explicación |
|---|---|---|
| Entrenamiento (training) | No | Crear o modificar el modelo desde cero. Cuesta millones. |
| Ajuste fino (fine-tuning) | No | Reentrenar el modelo con datos propios. No daría memoria por estudiante y requiere miles de ejemplos. |
| Instrucciones de sistema (system prompt) | **Sí** | Texto que define el comportamiento del modelo en esa llamada. El nuestro cambia para cada estudiante y cada mensaje. |
| Historial de conversación | **Sí** | Se le envían los últimos 20 mensajes de la sesión para que tenga contexto. |
| Contexto de sesiones anteriores | **Sí** | Resumen de las últimas 3 sesiones dentro del prompt. |
| Salida estructurada | **Sí** | Le exigimos la etiqueta `[SIGNAL: ...]` y, en el parcial, un JSON con formato estricto. |

### 10.3 ¿Dónde están los prompts? (archivos y líneas)

Todos los prompts están en **tres archivos del backend**:

| Prompt | Archivo y línea | Qué le dice a la IA |
|---|---|---|
| Instrucciones por estilo de aprendizaje (7: analogías, ejemplos, visual, listas, socrático, narrativa, desconocido) | `backend/prompt_builder.py`, `LEARNING_STYLE_INSTRUCTIONS`, línea 6 | Ej.: "El estudiante aprende mejor con EJEMPLOS. Usa ejemplos concretos del mundo real primero; la teoría viene después." |
| Instrucciones por personalidad del tutor (4) | `backend/prompt_builder.py`, `PERSONALITY_INSTRUCTIONS`, línea 37 | challenger: directo y retador; patient: muy paciente; playful: humor sutil; neutral: equilibrado |
| Instrucción de la señal oculta | `backend/prompt_builder.py`, `SIGNAL_INSTRUCTION`, línea 44 | "Al final de CADA respuesta incluye `[SIGNAL: event_type=<understood\|confused\|frustrated\|mastered\|neutral>, topic=<tema_actual>, style=<estilo_usado>]`" |
| Prompt de sistema completo (ensambla todo) | `backend/prompt_builder.py`, `build_system_prompt()`, línea 53 | Une los datos del estudiante, estilo, personalidad, temas, fatiga, contexto, tema activo y reglas |
| Nota de fatiga | `backend/prompt_builder.py`, línea 93 | "La sesión lleva N mensajes (umbral: 20). Reduce la complejidad y ofrece pausas." |
| Guardrail del tema | `backend/prompt_builder.py`, línea 105 | "Mantén TODA la conversación centrada en el tema activo… si pregunta algo fuera del tema, NO desarrolles esa respuesta y redirígelo." |
| Prompt del parcial | `backend/routers/chat.py`, `generate_exam()`, línea 303 | "Genera un mini parcial TIPO TEST de N preguntas… formato estricto JSON… options siempre de 4 elementos, correct_index entre 0 y 3… sin markdown." |
| Prompt del título automático | `backend/gemini_client.py`, `generate_session_title()`, línea 163 | "Genera un título corto (2 a 5 palabras, en español)… responde SOLO con el título." |

**Estructura del prompt de sistema que recibe Gemini** (lo arma `build_system_prompt()`):

```
Eres TutorMind AI, un tutor educativo adaptativo para estudiantes universitarios.
Estudiante: <nombre>   Carrera: <carrera>   Universidad: <universidad>

## Estilo de enseñanza        ← sale de cognitive_profiles.learning_style
## Personalidad del tutor     ← sale de cognitive_profiles.personality_type
Temas que han generado frustración: ...   ← cognitive_profiles.frustration_topics
Temas que el estudiante ya domina: ...    ← cognitive_profiles.mastered_topics
Nota de fatiga (si message_count ≥ 20)    ← sessions.message_count
Contexto de sesiones recientes: ...       ← últimas 3 filas de sessions
## Tema obligatorio de la sesión actual   ← sessions.subject
## Reglas de comportamiento (adaptar estilo, cambiar estrategia si hay
   confusión, pregunta de verificación, responder en español, ser conciso)
IMPORTANTE: al final incluye [SIGNAL: ...]
```

Cada línea marcada con ← sale de la base de datos. Por eso dos estudiantes que hacen la misma pregunta reciben respuestas distintas.

### 10.4 ¿Cómo se adapta la IA? El ciclo paso a paso

```
 Estudiante escribe          Angular                    FastAPI (TutorMind)                       Gemini
 ─────────────────          ─────────                  ────────────────────                      ──────
 "¿Qué es recursión?" ──►  chat.service.ts  ──POST──►  1. Lee perfil (SQLite)
                           sendMessage()               2. Lee últimos 20 mensajes y 3 sesiones
                                                       3. build_system_prompt()  ─────────────►  Genera la
                                                       4. stream_chat()                          explicación
                                                       5. _safe_yield_text() oculta [SIGNAL] ◄── por partes
                           readSseResponse() ◄──SSE──  6. Envía el texto limpio por partes
 Lee la respuesta  ◄─────  pinta el texto              7. extract_and_update_signals()
                                                       8. update_cognitive_profile():
                                                          guarda evento, actualiza temas,
                                                          rota o fija el estilo
                                                       9. Guarda el mensaje limpio
                                                       → El PRÓXIMO prompt ya sale distinto
```

**Detalle de cada paso con su archivo:**

1. **Cargar el perfil.** `backend/routers/chat.py`, `_sse_generator_body()` (línea 71) consulta `CognitiveProfile` del estudiante.
2. **Cargar la memoria.** `backend/memory_manager.py`: `get_conversation_history()` (línea 25, últimos 20 mensajes) y `get_session_context()` (línea 37, últimas 3 sesiones).
3. **Construir el prompt personalizado.** `backend/prompt_builder.py`, `build_system_prompt()` (línea 53).
4. **Llamar a la IA.** `backend/gemini_client.py`, `stream_chat()` (línea 93): crea el modelo con `system_instruction=<nuestro prompt>`, le pasa el historial y pide `stream=True`.
5. **Ocultar la señal mientras llega.** `backend/routers/chat.py`, `_safe_yield_text()` (línea 44).
6. **Enviar al navegador por SSE.** El frontend la lee en `frontend/src/app/services/chat.service.ts`, `readSseResponse()` (línea 188).
7. **Leer la señal.** `backend/memory_manager.py`, `extract_and_update_signals()` (línea 133) con la expresión regular `SIGNAL_PATTERN` (línea 10).
8. **Aplicar las reglas (aquí está la adaptación real).** `backend/memory_manager.py`, `update_cognitive_profile()` (línea 69):
   - Siempre guarda un `LearningEvent` (tipo, tema, estilo, fecha).
   - `mastered` → agrega el tema a `mastered_topics` (RN-07).
   - `frustrated` → agrega el tema a `frustration_topics` (RN-07).
   - `confused` → si ya hay 3 confusiones con ese estilo, cambia `learning_style` al siguiente de `STYLE_ROTATION` (línea 15): analogías → ejemplos → visual → listas → socrático → narrativa (RN-05).
   - `understood` con estilo `unknown` → fija ese estilo como el del estudiante (RN-06).
9. **Guardar el mensaje limpio.** En la tabla `messages`, sin la etiqueta.

**Ejemplo concreto para contar en la defensa:**

> Ana es nueva: su estilo es `unknown`, así que el prompt le pide a Gemini variar entre estilos. Pregunta por recursión, Gemini responde con un ejemplo y Ana dice "Ya entendí". La señal llega como `understood, style=examples`, y nuestro código fija su estilo en "ejemplos". Desde ese momento, todos sus prompts dicen "aprende mejor con EJEMPLOS". Días después, con punteros, se confunde tres veces con ejemplos: el código cambia su estilo a "visual" y la siguiente respuesta empieza con "imagina que…". El profesor ve en su panel "Punteros: con dificultad". Gemini nunca supo nada de esto: cada vez recibió un prompt distinto armado por TutorMind.

### 10.5 ¿Y las respuestas a los botones "Ya entendí" / "No entendí"?

Están en `frontend/src/app/components/chat/chat.component.ts`, `quickActions` (línea 81). Envían ese texto como un mensaje normal; Gemini lo interpreta y lo devuelve en la señal (`understood` o `confused`), que nuestro código procesa igual que en el paso 8.

---

## 11. Mapa completo de archivos (rutas)

**Carpeta del proyecto en este computador:**
`C:\Users\dc214\Downloads\Actividades\Proyecto\tutormind-main\tutormind-main\`

Todas las rutas de abajo son relativas a esa carpeta (igual que en GitHub: `github.com/David78-beto/TutorMind`).

### 11.1 Documentos

| Archivo | Ruta | Contenido |
|---|---|---|
| Documento técnico (PDF) | `docs/TutorMind_Documento_Tecnico.pdf` | Requerimientos, stack, arquitectura, MER, BPMN, C4, repositorio, trazabilidad |
| Documento técnico (Word) | `docs/TutorMind_Documento_Tecnico.docx` | Versión editable del anterior |
| Plan de trabajo | `docs/PLAN DE TRABAJO - TutorMind.xlsx` (copia también en `C:\Users\dc214\Downloads\PLAN DE TRABAJO - TutorMind.xlsx`) | Hojas "Plan de Proyecto" (cronograma, responsables, avance) y "Puntos de Dolor" |
| Esta guía | `docs/Guia_Defensa_TutorMind.md` y `docs/Guia_Defensa_TutorMind.docx` | Preparación para preguntas |
| README | `README.md` | Descripción, tecnologías, instalación, variables, endpoints, limitaciones |

### 11.2 Raíz del proyecto

| Archivo | Ruta | Para qué sirve |
|---|---|---|
| Plantilla de variables | `.env.example` | Variables sin secretos (`GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_ALLOWED_MODELS`, `DATABASE_URL`, `ALLOWED_ORIGINS`) |
| Variables reales | `.env` (no se sube; está en `.gitignore`) | Contiene la API key real |
| Exclusiones de Git | `.gitignore` | Evita subir `.env`, dependencias y la base de datos |
| Arranque completo | `iniciar.bat` | Arranca backend y frontend y abre el navegador |
| Arranque del backend | `start-backend.bat` | Instala dependencias y levanta la API |
| Base de datos | `backend/tutormind.db` (se crea al arrancar) | Archivo SQLite con las 6 tablas |

### 11.3 Backend (Python + FastAPI): carpeta `backend/`

| Componente C4 | Ruta | Responsabilidad | Funciones y líneas clave |
|---|---|---|---|
| Arranque de la API | `backend/main.py` | Crea la app, configura CORS y registra los routers | CORS con `ALLOWED_ORIGINS` (líneas 20–22); `health()` (37) |
| Conexión a la base | `backend/database.py` | Motor SQLAlchemy, sesión y migraciones simples | `run_migrations()` (17); `get_db()` (32) |
| Entidades del MER | `backend/models.py` | Las 6 tablas | `User` (9), `TeacherStudent` (38), `CognitiveProfile` (55), `Session` (71), `Message` (86), `LearningEvent` (98) |
| Validación | `backend/schemas.py` | Esquemas Pydantic de entrada y salida | Correo válido, contraseña de 6 a 128, rol |
| Auth Utils | `backend/auth_utils.py` | Hash de contraseñas | `hash_password()` (5); `verify_password()` (11) |
| Prompt Builder | `backend/prompt_builder.py` | Traduce el perfil a instrucciones para la IA | `LEARNING_STYLE_INSTRUCTIONS` (6); `PERSONALITY_INSTRUCTIONS` (37); `SIGNAL_INSTRUCTION` (44); `build_system_prompt()` (53); nota de fatiga (93); guardrail del tema (105) |
| Memory Manager | `backend/memory_manager.py` | Historial, contexto, señales y reglas del perfil | `SIGNAL_PATTERN` (10); `STYLE_ROTATION` (15); `get_conversation_history()` (25); `get_session_context()` (37); `update_cognitive_profile()` (69); `extract_and_update_signals()` (133) |
| Analytics | `backend/analytics.py` | Clasificación de temas, barras y resumen | `_topic_status()` (10, RN-08); `build_topic_insights()` (46); `build_event_bars()` (101); `build_learning_summary()` (115) |
| Gemini Client | `backend/gemini_client.py` | Único archivo que habla con la IA | `MODEL_NAME` (15); `ALLOWED_MODELS` (18); `_resolve_models_to_try()` (61); `_is_quota_error()` (88); `stream_chat()` (93); `generate_session_title()` (163) |
| Dependencias | `backend/requirements.txt` | Paquetes de Python | `pip install -r requirements.txt` |
| Users Router | `backend/routers/users.py` | Registro, login y consulta | `_link_pending_teacher_enrollments()` (56, RF-17); `create_user()` (73); `get_user()` (109); `login()` (122) |
| Chat Router | `backend/routers/chat.py` | Sesiones, chat SSE y parcial | `SIGNAL_START` (34); `_safe_yield_text()` (44); `_sse_generator_body()` (71); `send_message()` (171); `create_session()` (186, RN-03); `list_sessions()` (218); `update_session()` (239); `delete_session()` (261); `get_session_messages()` (281); `generate_exam()` (303); `submit_exam()` (371) |
| Profile Router | `backend/routers/profile.py` | Perfil y estadísticas | `get_profile()` (31); `update_profile()` (41); `get_profile_stats()` (71); índice de comprensión (136, RN-09) |
| Teachers Router | `backend/routers/teachers.py` | Panel del profesor | `_get_teacher()` (30, error 403, RN-11); `_build_student_overview()` (72); `list_students()` (139); `add_student()` (152, RN-10); `remove_student()` (201) |
| Paquete de routers | `backend/routers/__init__.py` | Marca la carpeta como paquete de Python | — |

### 11.4 Frontend (Angular 17): carpeta `frontend/`

| Archivo | Ruta | Para qué sirve |
|---|---|---|
| Configuración de Angular | `frontend/angular.json` | Configuración del proyecto y del build |
| Dependencias | `frontend/package.json`, `frontend/package-lock.json` | Paquetes de npm (`npm install`) |
| Proxy de desarrollo | `frontend/proxy.conf.json` | Redirige `/api` a `http://127.0.0.1:8000` |
| TypeScript | `frontend/tsconfig.json`, `frontend/tsconfig.app.json` | Configuración del compilador |
| Página base | `frontend/src/index.html` | HTML donde se monta la app |
| Arranque | `frontend/src/main.ts` | Inicia la aplicación Angular |
| Estilos globales | `frontend/src/styles.scss` | Estilos generales |
| Componente raíz | `frontend/src/app/app.component.ts` | Contenedor principal |
| Configuración | `frontend/src/app/app.config.ts` | Proveedores (router, HTTP) |
| Rutas (RF-04) | `frontend/src/app/app.routes.ts` | Ruta vacía → chat (línea 7); `profesor` → panel del profesor (8); `onboarding` → registro e inicio de sesión (9) |
| Registro e inicio de sesión | `frontend/src/app/components/onboarding/onboarding.component.ts` (+ `.html`, `.scss`) | Pantalla de login y registro |
| Chat de estudio | `frontend/src/app/components/chat/chat.component.ts` (+ `.html`, `.scss`) | Chat, barra lateral, sesiones y parcial. `quickActions` (línea 81); `submitExam()` (311; aprobación con 80 % en la línea 329) |
| Gráfica de barras | `frontend/src/app/components/bar-chart/bar-chart.component.ts` (+ `.html`, `.scss`) | Barras de eventos de aprendizaje |
| Panel del profesor | `frontend/src/app/components/teacher/teacher-dashboard.component.ts` (+ `.html`, `.scss`) | Inscribir, ver y retirar estudiantes |
| Interfaces | `frontend/src/app/models/user.model.ts` | Tipos `User`, `CognitiveProfile`, `UserStats` |
| Markdown | `frontend/src/app/pipes/markdown-to-html.pipe.ts` | Convierte las respuestas en Markdown a HTML |
| Configuración de la API | `frontend/src/app/services/api.config.ts` | URL base de la API |
| Servicio de chat | `frontend/src/app/services/chat.service.ts` | `submitExam()` (155); `sendMessage()` (166); `readSseResponse()` (188, lee el streaming SSE) |
| Servicio de perfil | `frontend/src/app/services/profile.service.ts` | Perfil, etiquetas de estilo y estadísticas |
| Servicio del profesor | `frontend/src/app/services/teacher.service.ts` | Llamadas a `/api/teachers` |
| Servicio de usuario | `frontend/src/app/services/user.service.ts` | Registro, login y usuario en `localStorage` |

### 11.5 Dónde mirar si preguntan por... (respuesta rápida)

| Pregunta | Abrir |
|---|---|
| "Muéstrenme cómo se adapta al estudiante" | `backend/prompt_builder.py` → `build_system_prompt()` (línea 53) |
| "¿Dónde están los prompts?" | `backend/prompt_builder.py` (líneas 6, 37, 44, 53, 93, 105), `backend/routers/chat.py` (303) y `backend/gemini_client.py` (163) |
| "¿Dónde está la regla de 3 confusiones?" | `backend/memory_manager.py` → `update_cognitive_profile()` (línea 69) |
| "¿Cómo leen la señal?" | `backend/memory_manager.py` → `SIGNAL_PATTERN` (línea 10) y `extract_and_update_signals()` (133) |
| "¿Cómo ocultan la etiqueta en el streaming?" | `backend/routers/chat.py` → `_safe_yield_text()` (línea 44) |
| "¿Dónde llaman a Gemini?" | `backend/gemini_client.py` → `stream_chat()` (línea 93) |
| "¿Qué base de datos usan y dónde se configura?" | `backend/database.py`, `backend/models.py` y `DATABASE_URL` en `.env` |
| "¿Cómo se clasifican los temas?" | `backend/analytics.py` → `_topic_status()` (línea 10) |
| "¿Dónde se calcula el índice de comprensión?" | `backend/routers/profile.py` (línea 136) |
| "¿Cómo guardan las contraseñas?" | `backend/auth_utils.py` |
| "¿Cómo funciona el panel del profesor?" | `backend/routers/teachers.py` y `frontend/src/app/components/teacher/teacher-dashboard.component.ts` |
| "¿Cómo se activa una inscripción pendiente?" | `backend/routers/users.py` → `_link_pending_teacher_enrollments()` (línea 56) |
| "¿Dónde está la API documentada?" | `http://localhost:8000/docs` (Swagger, con el backend corriendo) |

---

## 12. Frase de cierre para la defensa

> "La IA generativa ya es una herramienta común, como una base de datos. Lo que construimos no es la IA: es el sistema que la convierte en un tutor que conoce a cada estudiante, que cambia cuando algo no funciona y que le muestra al profesor dónde intervenir. Si quitamos Gemini y ponemos otro modelo, TutorMind sigue siendo TutorMind."
