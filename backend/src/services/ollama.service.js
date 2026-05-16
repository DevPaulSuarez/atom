const { env } = require('../config/env');

// Fallback cuando Ollama no está disponible — tareas concretas y accionables
const FALLBACK_TASKS = {
  simple: [
    'Definir los requisitos del proyecto y escribir los criterios de aceptación en un documento',
    'Crear la estructura de carpetas e instalar las dependencias necesarias',
    'Implementar la funcionalidad principal con el caso de uso más importante',
    'Agregar validaciones y manejo de errores a la funcionalidad core',
    'Escribir pruebas para los flujos críticos y corregir los fallos encontrados',
    'Documentar cómo ejecutar el proyecto y hacer la entrega final',
  ],
  medio: [
    'Definir los requisitos y crear el esquema de la base de datos con tablas e índices',
    'Configurar el proyecto base: repositorio, estructura de carpetas y variables de entorno',
    'Crear los modelos de datos y las migraciones correspondientes',
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
    'Configurar el entorno de desarrollo con CI/CD, variables por entorno y secretos',
    'Crear las migraciones de base de datos y verificar que aplican correctamente',
    'Implementar el sistema de autenticación: registro, login y manejo de tokens',
    'Crear el módulo de usuarios: endpoints CRUD y validación de permisos',
    'Implementar el endpoint POST del recurso principal con validación y persistencia',
    'Implementar el endpoint GET (lista y detalle) con paginación y filtros',
    'Implementar los endpoints PUT/PATCH y DELETE con verificación de propietario',
    'Diseñar y construir la pantalla principal con lista y estado vacío',
    'Crear la pantalla de detalle con navegación y carga de datos desde la API',
    'Implementar el flujo de creación y edición con formularios validados',
    'Conectar todos los flujos del frontend con la API y manejar errores de red',
    'Agregar notificaciones, feedback visual y estados de carga en toda la app',
    'Implementar caché local para uso offline y sincronización al reconectar',
    'Escribir pruebas de integración para los endpoints críticos',
    'Realizar pruebas de carga e identificar cuellos de botella',
    'Revisar seguridad: CORS, rate limiting, validación de entradas y headers HTTP',
    'Preparar el despliegue: Dockerfile, variables de producción y checklist de go-live',
    'Monitorear métricas post-lanzamiento y cerrar issues detectados en las primeras 24h',
  ],
};

const buildPrompt = (name, description) => `\
/no_think
Eres un experto en planificación de proyectos de software y productividad.

PROYECTO: ${name}
DESCRIPCIÓN: ${description || 'Sin descripción adicional'}

REGLA FUNDAMENTAL: Una microtarea = UNA acción técnica concreta con UN resultado verificable. Duración: 15-60 min.

Ejemplos CORRECTOS:
- "Crear endpoint POST /projects en Express con validación de nombre y descripción"
- "Configurar navegación Flutter entre pantallas Home y Detalle con Named Routes"
- "Guardar proyecto en PostgreSQL e insertar microtareas en tabla micro_tasks"
- "Implementar timer de cuenta regresiva de 25 minutos con pausa y reinicio"

Ejemplos INCORRECTOS (demasiado vagos):
- "Implementar backend" ✗
- "Hacer la UI" ✗
- "Desarrollar funcionalidad" ✗

Complejidad del proyecto:
- "simple" (1-2 días) → genera 5 a 7 tareas
- "medio" (3-7 días) → genera 9 a 13 tareas
- "complejo" (semanas/módulos múltiples) → genera 15 a 20 tareas

Reglas de formato:
1. Cada tarea empieza con verbo: Crear / Configurar / Implementar / Conectar / Diseñar / Agregar / Escribir
2. Menciona el artefacto concreto: endpoint, pantalla, función, tabla, modelo, componente
3. Las tareas siguen orden secuencial: estructura → datos → lógica → UI → integración → pruebas

Responde ÚNICAMENTE con este JSON sin texto adicional antes ni después:
{"complexity":"simple|medio|complejo","tasks":["Tarea 1","Tarea 2"]}`;

const LIMITS = { simple: [4, 6], medio: [8, 12], complejo: [14, 20] };

const extractJson = (text) => {
  // Extrae el primer bloque JSON completo del texto (ignora <think>...</think>)
  const clean = text.replace(/<think>[\s\S]*?<\/think>/gi, '').trim();
  const match = clean.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('No se encontró JSON en la respuesta');
  return JSON.parse(match[0]);
};

const generateMicroTasks = async (name, description) => {
  try {
    const response = await fetch(`${env.OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: env.OLLAMA_MODEL,
        prompt: buildPrompt(name, description),
        stream: false,
        // Sin format:'json' — qwen3 (modelo de razonamiento) lo ignora con /no_think
        options: { temperature: 0.3, num_predict: 4096, num_ctx: 4096 },
      }),
      signal: AbortSignal.timeout(90_000),
    });

    if (!response.ok) throw new Error(`Ollama HTTP ${response.status}`);

    const data = await response.json();
    const raw = data.response || '';

    if (!raw.trim()) throw new Error('Respuesta vacía de Ollama');

    const parsed = extractJson(raw);

    if (!Array.isArray(parsed?.tasks) || parsed.tasks.length === 0) {
      throw new Error('Formato de respuesta inválido');
    }

    const complexity = parsed.complexity || 'medio';
    const [min, max] = LIMITS[complexity] ?? LIMITS.medio;
    const tasks = parsed.tasks.map(String).filter(Boolean);

    if (tasks.length < min) throw new Error(`Pocas tareas (${tasks.length} < ${min})`);

    console.log(`[Ollama] Complejidad: ${complexity}, tareas generadas: ${tasks.length}`);
    return tasks.slice(0, max);
  } catch (err) {
    console.warn(`[Ollama] Falló (${err.message}), usando tareas predeterminadas`);
    const words = (description || '').split(/\s+/).filter(Boolean).length;
    const key = words < 20 ? 'simple' : words < 60 ? 'medio' : 'complejo';
    return FALLBACK_TASKS[key];
  }
};

module.exports = { generateMicroTasks };
