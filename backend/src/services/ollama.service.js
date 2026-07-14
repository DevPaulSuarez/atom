const { env } = require('../config/env');

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

// Tareas de respaldo genéricas: sirven para CUALQUIER tipo de proyecto
// (estudio, hogar, salud, trabajo, creatividad, eventos, etc.), no solo software.
// Se guardan en los dos idiomas soportados para responder en el idioma del usuario.
const FALLBACK_TASKS = {
  es: {
    simple: [
      'Definir con claridad qué quieres lograr y cómo sabrás que está terminado',
      'Reunir la información, materiales o herramientas que necesitas para empezar',
      'Dividir el trabajo en partes y decidir por dónde empezar',
      'Avanzar la parte principal del proyecto, paso a paso',
      'Revisar lo hecho y corregir los detalles que falten',
      'Dar los toques finales y dejar todo listo',
    ],
    medio: [
      'Definir el objetivo, el alcance y el resultado que esperas obtener',
      'Investigar y reunir la información necesaria para empezar',
      'Listar todas las tareas y ordenarlas por prioridad',
      'Preparar los materiales, recursos o herramientas requeridos',
      'Avanzar la primera parte principal del proyecto',
      'Avanzar la segunda parte principal del proyecto',
      'Resolver los puntos difíciles o que requieren más atención',
      'Unir las partes y verificar que todo encaje',
      'Revisar la calidad y corregir errores o detalles',
      'Pedir una opinión o validar el resultado con alguien, si aplica',
      'Aplicar los ajustes finales según lo revisado',
      'Cerrar el proyecto y dejar todo ordenado',
    ],
    complejo: [
      'Definir la meta general, el alcance y los criterios de éxito',
      'Investigar a fondo el tema y reunir referencias o ejemplos',
      'Dividir el proyecto en etapas o partes principales',
      'Crear un plan con fechas y prioridades',
      'Preparar todos los recursos, materiales y herramientas',
      'Desarrollar la primera etapa del proyecto',
      'Desarrollar la segunda etapa del proyecto',
      'Desarrollar la tercera etapa del proyecto',
      'Resolver los obstáculos o las partes más complejas',
      'Unir las distintas etapas en un solo resultado',
      'Hacer una primera revisión completa de lo realizado',
      'Corregir los errores y mejorar los puntos débiles',
      'Pedir retroalimentación a otra persona o fuente confiable',
      'Aplicar los cambios sugeridos',
      'Pulir los detalles y la presentación final',
      'Hacer una verificación final de calidad',
      'Preparar la entrega, publicación o puesta en marcha del resultado',
      'Cerrar el proyecto y anotar lo que aprendiste',
    ],
  },
  en: {
    simple: [
      "Clearly define what you want to achieve and how you'll know it's done",
      'Gather the information, materials, or tools you need to get started',
      'Break the work into parts and decide where to begin',
      'Make progress on the main part of the project, step by step',
      "Review what you've done and fix any missing details",
      'Add the finishing touches and get everything ready',
    ],
    medio: [
      'Define the goal, the scope, and the result you expect to get',
      'Research and gather the information you need to get started',
      'List all the tasks and order them by priority',
      'Prepare the required materials, resources, or tools',
      'Make progress on the first main part of the project',
      'Make progress on the second main part of the project',
      'Solve the hard points or the ones that need more attention',
      'Put the parts together and check that everything fits',
      'Review the quality and fix any errors or details',
      'Ask for feedback or validate the result with someone, if it applies',
      'Apply the final adjustments based on the review',
      'Wrap up the project and leave everything tidy',
    ],
    complejo: [
      'Define the overall goal, the scope, and the success criteria',
      'Research the topic in depth and gather references or examples',
      'Break the project into main stages or parts',
      'Create a plan with dates and priorities',
      'Prepare all the resources, materials, and tools',
      'Develop the first stage of the project',
      'Develop the second stage of the project',
      'Develop the third stage of the project',
      'Solve the obstacles or the most complex parts',
      'Combine the different stages into a single result',
      "Do a first full review of what you've done",
      'Fix the errors and improve the weak points',
      'Ask for feedback from another person or a trusted source',
      'Apply the suggested changes',
      'Polish the details and the final presentation',
      'Do a final quality check',
      'Prepare the delivery, publication, or launch of the result',
      'Close the project and note down what you learned',
    ],
  },
};

const LIMITS = { simple: [5, 7], medio: [9, 13], complejo: [15, 20] };

const DEFAULT_POMODOROS = 2;
const MAX_POMODOROS = 4;

// --- Detección de idioma (es | en) ------------------------------------------
// El usuario debe recibir las tareas en el idioma en que escribió el proyecto.
// Detectamos a partir de su texto y, si es ambiguo o muy corto, usamos el
// idioma de la app (hint) que envía el frontend.
const SPANISH_CHARS = /[ñ¿¡áéíóúü]/i;
const ES_WORDS = new Set([
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'y', 'o',
  'que', 'para', 'por', 'con', 'sin', 'como', 'mi', 'mis', 'su', 'sus', 'este',
  'esta', 'estos', 'estas', 'es', 'son', 'hacer', 'crear', 'quiero', 'necesito',
  'proyecto', 'tarea', 'tareas', 'app', 'aplicacion', 'aplicación', 'casa',
  'trabajo', 'estudiar', 'organizar', 'preparar', 'aprender',
]);
const EN_WORDS = new Set([
  'the', 'a', 'an', 'of', 'and', 'or', 'to', 'for', 'with', 'without', 'as',
  'my', 'your', 'this', 'that', 'these', 'those', 'is', 'are', 'do', 'make',
  'create', 'want', 'need', 'project', 'task', 'tasks', 'app', 'application',
  'home', 'work', 'study', 'organize', 'prepare', 'learn', 'build',
]);

const normalizeLang = (lang) => (lang === 'en' ? 'en' : lang === 'es' ? 'es' : null);

const detectLang = (text, fallback = 'es') => {
  const base = normalizeLang(fallback) || 'es';
  const t = (text || '').toLowerCase();
  if (!t.trim()) return base;
  if (SPANISH_CHARS.test(t)) return 'es';

  let es = 0;
  let en = 0;
  for (const w of t.split(/[^a-záéíóúñü]+/i)) {
    if (!w) continue;
    if (ES_WORDS.has(w)) es++;
    if (EN_WORDS.has(w)) en++;
  }
  if (es > en) return 'es';
  if (en > es) return 'en';
  return base;
};

// Instrucción fuerte de idioma para clavar la salida del modelo, ya que el
// resto del prompt está en español y el modelo tiende a responder en español.
const langDirective = (lang) =>
  lang === 'en'
    ? 'CRITICAL: The user is writing in ENGLISH. Write EVERYTHING (every task/subtask title) in ENGLISH ONLY. Do not use Spanish.'
    : 'CRÍTICO: El usuario escribe en ESPAÑOL. Escribe TODO (cada título de tarea/subtarea) SOLO en ESPAÑOL. No uses inglés.';

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

const SYSTEM_PROMPT = `Eres un experto en planificación y productividad que ayuda a las personas a dividir CUALQUIER meta o proyecto en microtareas accionables, sin importar el área: estudios, trabajo, hogar, salud y ejercicio, finanzas personales, proyectos creativos (escribir, música, arte, manualidades), organización de eventos, viajes, aprender una habilidad, emprendimientos, tareas domésticas, etc.

MUY IMPORTANTE: NO asumas que el proyecto es de programación, software o tecnología. Detecta el área REAL a partir del nombre y la descripción del usuario y genera tareas propias de ESE contexto, con su lenguaje natural. Solo usa términos técnicos de software si el usuario pide claramente algo de programación.

REGLA FUNDAMENTAL: Una microtarea = UNA acción concreta con UN resultado verificable. Duración: 15-60 min.

Ejemplos CORRECTOS según el área:
- Estudio: "Resumir el capítulo 3 del libro en una página con tus propias palabras"
- Hogar: "Ordenar y limpiar los cajones de la cocina"
- Ejercicio: "Completar la rutina de cardio de 20 minutos del día 1"
- Escritura: "Escribir el primer borrador de la introducción (unas 300 palabras)"
- Evento: "Hacer la lista de invitados y confirmar el lugar"
- Cocina: "Comprar los ingredientes de la receta según la lista"
- Software (solo si el usuario lo pide): "Crear endpoint POST /projects con validación de nombre"

Ejemplos INCORRECTOS (demasiado vagos):
- "Estudiar" ✗
- "Hacer ejercicio" ✗
- "Organizar la casa" ✗
- "Avanzar el proyecto" ✗

Complejidad del proyecto:
- "simple"   (1-2 días)  → genera 5 a 7 tareas
- "medio"    (3-7 días)  → genera 9 a 13 tareas
- "complejo" (semanas)   → genera 15 a 20 tareas

Reglas de formato para cada tarea:
1. Empieza con un verbo de acción adecuado al área (Leer, Escribir, Llamar, Comprar, Practicar, Ordenar, Preparar, Cocinar, Diseñar, Crear, Revisar, Investigar...).
2. Menciona el objeto o resultado concreto: qué exactamente se hace y con qué.
3. Usa el lenguaje cotidiano del área del usuario; evita jerga técnica innecesaria.
4. Ordena las tareas de forma lógica: preparación → desarrollo → revisión → cierre.

SI EL USUARIO YA INDICA SUS PROPIOS PASOS O TAREAS en la descripción (una lista, "una tarea por cada...", pasos numerados, etc.), RESPÉTALOS: crea exactamente una tarea por cada paso que pide, con sus mismas palabras, sin inventar otras ni reordenarlas. En ese caso tu único trabajo extra es estimar los pomodoros de cada una.

ESTIMACIÓN: para cada tarea estima cuántos pomodoros (bloques de enfoque) toma completarla.
- 1 pomodoro  = tarea pequeña y directa
- 2 pomodoros = tarea media
- 3-4 pomodoros = tarea grande o con varias partes
Usa solo números enteros del 1 al 4. Sé realista, no infles las estimaciones.

IDIOMA: escribe todas las tareas en el idioma que se indique al final del mensaje. Es obligatorio respetarlo.
Responde ÚNICAMENTE con JSON válido, sin texto adicional:
{"complexity":"simple|medio|complejo","tasks":[{"title":"Tarea 1","pomodoros":2},{"title":"Tarea 2","pomodoros":1}]}`;

const generateMicroTasks = async (name, description, localeHint = 'es') => {
  const lang = detectLang(`${name} ${description || ''}`, localeHint);
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
          { role: 'system', content: `${SYSTEM_PROMPT}\n\n${langDirective(lang)}` },
          { role: 'user', content: `Proyecto: ${name}\nDescripción: ${description || 'Sin descripción adicional'}\n\n${langDirective(lang)}` },
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

    console.log(`[Groq] Idioma: ${lang}, complejidad: ${complexity}, tareas generadas: ${tasks.length}`);
    return tasks.slice(0, max);
  } catch (err) {
    console.warn(`[Groq] Falló (${err.message}), usando tareas predeterminadas (${lang})`);
    const words = (description || '').split(/\s+/).filter(Boolean).length;
    const key = words < 20 ? 'simple' : words < 60 ? 'medio' : 'complejo';
    return FALLBACK_TASKS[lang][key].map((t) => normalizeTask(t));
  }
};

const SPLIT_SYSTEM_PROMPT = `Eres un experto en productividad. Una tarea está bloqueada y necesita dividirse en pasos más pequeños y fáciles de empezar. Esto aplica a CUALQUIER tipo de tarea (estudio, hogar, salud, trabajo, creatividad, eventos, etc.), no solo de programación.

Reglas:
- Genera exactamente 3 subtareas concretas y accionables
- Cada subtarea toma 15-30 minutos (1 o 2 pomodoros)
- Empieza con un verbo de acción adecuado al área (Identificar, Preparar, Buscar, Escribir, Hacer, Practicar, Revisar...)
- Las 3 subtareas juntas completan la tarea original
- Usa el lenguaje natural de la tarea; evita jerga técnica innecesaria salvo que la tarea sea de programación
- Estima los pomodoros de cada subtarea (entero, 1 o 2)
- Escribe las subtareas en el idioma que se indique al final del mensaje. Es obligatorio respetarlo.

Responde ÚNICAMENTE con JSON válido:
{"subtasks":[{"title":"Subtarea 1","pomodoros":1},{"title":"Subtarea 2","pomodoros":2},{"title":"Subtarea 3","pomodoros":1}]}`;

const splitBlockedTask = async (taskTitle, projectName, projectDescription, localeHint = 'es') => {
  const lang = detectLang(`${taskTitle} ${projectName || ''} ${projectDescription || ''}`, localeHint);
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
          { role: 'system', content: `${SPLIT_SYSTEM_PROMPT}\n\n${langDirective(lang)}` },
          { role: 'user', content: `Proyecto: ${projectName}\nDescripción: ${projectDescription || ''}\nTarea bloqueada: ${taskTitle}\n\n${langDirective(lang)}` },
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

    console.log(`[Groq split] Idioma: ${lang}, generadas ${parsed.subtasks.length} subtareas para: "${taskTitle}"`);
    // Subtareas: máximo 2 pomodoros cada una.
    return parsed.subtasks
        .map((s) => normalizeTask(s, 2))
        .filter((s) => s && s.title)
        .slice(0, 4);
  } catch (err) {
    console.warn(`[Groq split] Falló (${err.message}), usando subtareas predeterminadas (${lang})`);
    if (lang === 'en') {
      return [
        { title: `Identify what's blocking you on: ${taskTitle}`, pomodoros: 1 },
        { title: `Do the main part of: ${taskTitle}`, pomodoros: 2 },
        { title: `Review and finish: ${taskTitle}`, pomodoros: 1 },
      ];
    }
    return [
      { title: `Identificar qué te está frenando en: ${taskTitle}`, pomodoros: 1 },
      { title: `Hacer la parte principal de: ${taskTitle}`, pomodoros: 2 },
      { title: `Revisar y terminar: ${taskTitle}`, pomodoros: 1 },
    ];
  }
};

const COACH_SYSTEM_PROMPT = {
  es: `Eres un coach de productividad que habla como un amigo cercano. El usuario se atascó y ya dividió la tarea. Necesita sentir que puede seguir.

Escribe UNA sola oración corta (máximo 20 palabras) que:
- Sea honesta y cálida, como si viniera del corazón
- Lo anime a no rendirse y dar el primer paso ahora mismo
- Evite clichés como "tú puedes", "ánimo", "excelente"

Solo la oración. Sin comillas, sin signos de exclamación múltiples, en español, tuteo.`,
  en: `You are a productivity coach who talks like a close friend. The user got stuck and has already split the task. They need to feel they can keep going.

Write ONE short sentence (max 20 words) that:
- Is honest and warm, as if it came from the heart
- Encourages them not to give up and to take the first step right now
- Avoids clichés like "you can do it", "cheer up", "great job"

Only the sentence. No quotation marks, no multiple exclamation marks, in English.`,
};

const generateCoachMessage = async (taskTitle, motivation, localeHint = 'es') => {
  const lang = detectLang(`${taskTitle} ${motivation || ''}`, localeHint);
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
          { role: 'system', content: COACH_SYSTEM_PROMPT[lang] },
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
    console.log(`[Groq coach] Idioma: ${lang}, mensaje generado para: "${taskTitle}"`);
    return message;
  } catch (err) {
    console.warn(`[Groq coach] Falló (${err.message}), usando mensaje predeterminado (${lang})`);
    return lang === 'en'
      ? "Don't give up — one small first step is all you need to take right now."
      : 'No te rindas — el primer paso pequeño es todo lo que necesitas dar ahora.';
  }
};

module.exports = { generateMicroTasks, splitBlockedTask, generateCoachMessage };
