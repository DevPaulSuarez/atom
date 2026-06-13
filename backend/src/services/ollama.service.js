const { env } = require('../config/env');

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

const FALLBACK_TASKS = {
  simple: [
    'Definir los requisitos del proyecto y escribir los criterios de aceptación',
    'Crear la estructura de carpetas e instalar las dependencias necesarias',
    'Implementar la funcionalidad principal con el caso de uso más importante',
    'Agregar validaciones y manejo de errores a la funcionalidad core',
    'Escribir pruebas para los flujos críticos y corregir los fallos encontrados',
    'Documentar cómo ejecutar el proyecto y hacer la entrega final',
  ],
  medio: [
    'Definir los requisitos y crear el esquema de la base de datos con tablas e índices',
    'Configurar el proyecto base: repositorio, estructura de carpetas y variables de entorno',
    'Crear los modelos de datos y las migraciones de base de datos',
    'Implementar el endpoint o función principal con validación de entrada',
    'Conectar la capa de datos con la lógica de negocio y verificar el flujo end-to-end',
    'Diseñar y construir la pantalla o interfaz principal con los componentes necesarios',
    'Agregar la pantalla de detalle y la navegación entre vistas',
    'Implementar el manejo de estados de carga, error y vacío en la UI',
    'Conectar el frontend con el backend y probar el flujo completo',
    'Agregar autenticación o control de acceso según los requisitos',
    'Escribir pruebas para los endpoints o funciones críticas',
    'Revisar seguridad, limpiar código y preparar para despliegue',
  ],
  complejo: [
    'Definir la arquitectura del sistema y crear el diagrama de componentes',
    'Diseñar el modelo de datos completo: entidades, relaciones e índices',
    'Configurar el entorno de desarrollo con CI/CD y gestión de secretos',
    'Crear las migraciones de base de datos y verificar que aplican correctamente',
    'Implementar el sistema de autenticación: registro, login y manejo de tokens JWT',
    'Crear el módulo de usuarios: endpoints CRUD y validación de permisos',
    'Implementar el endpoint POST del recurso principal con validación y persistencia',
    'Implementar los endpoints GET con paginación y filtros',
    'Implementar los endpoints PATCH y DELETE con verificación de propietario',
    'Diseñar y construir la pantalla principal con lista y estado vacío',
    'Crear la pantalla de detalle con navegación y carga de datos desde la API',
    'Implementar el flujo de creación y edición con formularios validados',
    'Conectar todos los flujos del frontend con la API y manejar errores de red',
    'Agregar notificaciones, feedback visual y estados de carga en toda la app',
    'Implementar caché local para uso offline básico',
    'Escribir pruebas de integración para los endpoints críticos',
    'Revisar seguridad: CORS, rate limiting, validación de entradas y headers HTTP',
    'Preparar el despliegue: variables de producción y checklist de go-live',
    'Monitorear métricas post-lanzamiento y cerrar issues detectados en las primeras 24h',
  ],
};

const LIMITS = { simple: [5, 7], medio: [9, 13], complejo: [15, 20] };

const DEFAULT_POMODOROS = 2;
const MAX_POMODOROS = 4;

const clampPomodoros = (n, max = MAX_POMODOROS) => {
  const v = parseInt(n, 10);
  if (!Number.isFinite(v)) return DEFAULT_POMODOROS;
  return Math.min(max, Math.max(1, v));
};

// Normaliza una entrada (string u objeto) a { title, pomodoros }.
const normalizeTask = (entry, max = MAX_POMODOROS) => {
  if (typeof entry === 'string') {
    return { title: entry.trim(), pomodoros: DEFAULT_POMODOROS };
  }
  if (entry && typeof entry === 'object' && entry.title) {
    return { title: String(entry.title).trim(), pomodoros: clampPomodoros(entry.pomodoros, max) };
  }
  return null;
};

const SYSTEM_PROMPT = `Eres un experto en planificación de proyectos de software y productividad.

REGLA FUNDAMENTAL: Una microtarea = UNA acción técnica concreta con UN resultado verificable. Duración: 15-60 min.

Ejemplos CORRECTOS:
- "Crear endpoint POST /projects en Express con validación de nombre y descripción"
- "Configurar navegación Flutter entre pantallas Home y Detalle con Named Routes"
- "Implementar timer de cuenta regresiva de 25 minutos con pausa y reinicio en Flutter"
- "Guardar proyecto en PostgreSQL e insertar microtareas en tabla micro_tasks"

Ejemplos INCORRECTOS (demasiado vagos):
- "Implementar backend" ✗
- "Hacer la UI" ✗
- "Desarrollar funcionalidad principal" ✗

Complejidad del proyecto:
- "simple"   (1-2 días)  → genera 5 a 7 tareas
- "medio"    (3-7 días)  → genera 9 a 13 tareas
- "complejo" (semanas)   → genera 15 a 20 tareas

Reglas de formato para cada tarea:
1. Empieza con verbo de acción: Crear / Configurar / Implementar / Conectar / Diseñar / Agregar / Escribir
2. Menciona el artefacto concreto: endpoint, pantalla, función, tabla, modelo, componente
3. Añade la tecnología si aporta claridad: Flutter, Express, PostgreSQL, etc.
4. Las tareas siguen orden secuencial: estructura → datos → lógica → UI → integración → pruebas

ESTIMACIÓN: para cada tarea estima cuántos pomodoros (bloques de enfoque) toma completarla.
- 1 pomodoro  = tarea pequeña y directa
- 2 pomodoros = tarea media
- 3-4 pomodoros = tarea grande o con varias partes
Usa solo números enteros del 1 al 4. Sé realista, no infles las estimaciones.

Responde ÚNICAMENTE con JSON válido, sin texto adicional:
{"complexity":"simple|medio|complejo","tasks":[{"title":"Tarea 1","pomodoros":2},{"title":"Tarea 2","pomodoros":1}]}`;

const generateMicroTasks = async (name, description) => {
  try {
    if (!env.GROQ_API_KEY) throw new Error('GROQ_API_KEY no configurada');

    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: env.GROQ_MODEL,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: `Proyecto: ${name}\nDescripción: ${description || 'Sin descripción adicional'}` },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
        max_tokens: 2048,
      }),
      signal: AbortSignal.timeout(30_000),
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      throw new Error(`Groq HTTP ${response.status}: ${err?.error?.message || 'error desconocido'}`);
    }

    const data = await response.json();
    const parsed = JSON.parse(data.choices[0].message.content);

    if (!Array.isArray(parsed?.tasks) || parsed.tasks.length === 0) {
      throw new Error('Formato de respuesta inválido');
    }

    const complexity = parsed.complexity || 'medio';
    const [min, max] = LIMITS[complexity] ?? LIMITS.medio;
    const tasks = parsed.tasks.map((t) => normalizeTask(t)).filter((t) => t && t.title);

    if (tasks.length < min) throw new Error(`Pocas tareas: ${tasks.length}`);

    console.log(`[Groq] Complejidad: ${complexity}, tareas generadas: ${tasks.length}`);
    return tasks.slice(0, max);
  } catch (err) {
    console.warn(`[Groq] Falló (${err.message}), usando tareas predeterminadas`);
    const words = (description || '').split(/\s+/).filter(Boolean).length;
    const key = words < 20 ? 'simple' : words < 60 ? 'medio' : 'complejo';
    return FALLBACK_TASKS[key].map((t) => normalizeTask(t));
  }
};

const SPLIT_SYSTEM_PROMPT = `Eres un experto en productividad. Una tarea está bloqueada y necesita dividirse en pasos más pequeños.

Reglas:
- Genera exactamente 3 subtareas concretas y accionables
- Cada subtarea toma 15-30 minutos (1 o 2 pomodoros)
- Empieza con verbo de acción: Identificar / Implementar / Conectar / Crear / Verificar
- Las 3 subtareas juntas completan la tarea original
- Estima los pomodoros de cada subtarea (entero, 1 o 2)

Responde ÚNICAMENTE con JSON válido:
{"subtasks":[{"title":"Subtarea 1","pomodoros":1},{"title":"Subtarea 2","pomodoros":2},{"title":"Subtarea 3","pomodoros":1}]}`;

const splitBlockedTask = async (taskTitle, projectName, projectDescription) => {
  try {
    if (!env.GROQ_API_KEY) throw new Error('GROQ_API_KEY no configurada');

    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: env.GROQ_MODEL,
        messages: [
          { role: 'system', content: SPLIT_SYSTEM_PROMPT },
          { role: 'user', content: `Proyecto: ${projectName}\nDescripción: ${projectDescription || ''}\nTarea bloqueada: ${taskTitle}` },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.4,
        max_tokens: 512,
      }),
      signal: AbortSignal.timeout(20_000),
    });

    if (!response.ok) throw new Error(`Groq HTTP ${response.status}`);

    const data = await response.json();
    const parsed = JSON.parse(data.choices[0].message.content);

    if (!Array.isArray(parsed?.subtasks) || parsed.subtasks.length < 2) {
      throw new Error('Formato inválido');
    }

    console.log(`[Groq split] Generadas ${parsed.subtasks.length} subtareas para: "${taskTitle}"`);
    // Subtareas: máximo 2 pomodoros cada una.
    return parsed.subtasks
        .map((s) => normalizeTask(s, 2))
        .filter((s) => s && s.title)
        .slice(0, 4);
  } catch (err) {
    console.warn(`[Groq split] Falló (${err.message}), usando subtareas predeterminadas`);
    return [
      { title: `Identificar el punto exacto de bloqueo en: ${taskTitle}`, pomodoros: 1 },
      { title: `Implementar la parte principal de: ${taskTitle}`, pomodoros: 2 },
      { title: `Verificar y finalizar: ${taskTitle}`, pomodoros: 1 },
    ];
  }
};

const COACH_SYSTEM_PROMPT = `Eres un coach de productividad que habla como un amigo cercano. El usuario se atascó y ya dividió la tarea. Necesita sentir que puede seguir.

Escribe UNA sola oración corta (máximo 20 palabras) que:
- Sea honesta y cálida, como si viniera del corazón
- Lo anime a no rendirse y dar el primer paso ahora mismo
- Evite clichés como "tú puedes", "ánimo", "excelente"

Solo la oración. Sin comillas, sin signos de exclamación múltiples, en español, tuteo.`;

const generateCoachMessage = async (taskTitle, motivation) => {
  try {
    if (!env.GROQ_API_KEY) throw new Error('GROQ_API_KEY no configurada');

    const userContent = motivation
      ? `Tarea bloqueada: "${taskTitle}"\nMotivación del usuario: "${motivation}"`
      : `Tarea bloqueada: "${taskTitle}"`;

    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: env.GROQ_MODEL,
        messages: [
          { role: 'system', content: COACH_SYSTEM_PROMPT },
          { role: 'user', content: userContent },
        ],
        temperature: 0.7,
        max_tokens: 200,
      }),
      signal: AbortSignal.timeout(15_000),
    });

    if (!response.ok) throw new Error(`Groq HTTP ${response.status}`);

    const data = await response.json();
    const message = data.choices[0].message.content.trim();
    console.log(`[Groq coach] Mensaje generado para: "${taskTitle}"`);
    return message;
  } catch (err) {
    console.warn(`[Groq coach] Falló (${err.message}), usando mensaje predeterminado`);
    return 'No te rindas — el primer paso pequeño es todo lo que necesitas dar ahora.';
  }
};

module.exports = { generateMicroTasks, splitBlockedTask, generateCoachMessage };
