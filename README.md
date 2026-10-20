# SportStats

App de iPhone (SwiftUI) para entrenar voleibol: recordatorios diarios de suplementos y rutinas de tren superior, tren inferior y pliometría con ejercicios de [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (876 ejercicios con fotos, dominio público, sin API key).

El diseño sigue los prototipos hechos con Claude Design.

## Estructura

```
SportStats.xcodeproj        ← ábrelo con Xcode
Frontend/                   Lo que se ve: pantallas, diseño y navegación
  SportStatsApp.swift       Punto de entrada de la app
  Design/                   Colores, tarjetas, botones, sonidos (estilo de los prototipos)
  Navigation/               Pestañas flotantes y rutas entre pantallas
  Screens/                  Inicio, Suplementos, Progreso, Entrenar, Perfil, Configuración
  Assets.xcassets           Ícono y recursos gráficos
Backend/                    Datos y lógica (corre en el iPhone, no hay servidor)
  Models/                   Suplementos y entrenos (SwiftData), ejercicios, objetivos de voleibol, plan del día
  Services/                 Catálogo de ejercicios (descarga única), notificaciones
  Persistence/              Base de datos local (SwiftData): suplementos, entrenos y ejercicios
  Settings/                 Claves y opciones de configuración
scripts/                    Generador del proyecto Xcode
```

Regla: `Frontend/` puede usar lo que hay en `Backend/`, pero `Backend/` no conoce las pantallas.

## Requisitos

- Xcode 15.2 o posterior (el código apunta a iOS 17 para compilar también en Xcode 15).
- Un Apple ID (gratis) para instalar en tu iPhone.

## Instalar en el iPhone

1. Abre `SportStats.xcodeproj`.
2. Selecciona el target **SportStats** → *Signing & Capabilities* → en *Team* elige tu Apple ID
   (si no aparece: Xcode → Settings → Accounts → +).
   Si el bundle id `cl.ninaspro.sportstats` ya está tomado, cámbialo por otro.
3. Conecta el iPhone por cable, acepta "Confiar en este computador" y activa
   **Ajustes → Privacidad y seguridad → Modo de desarrollador**.
4. Elige tu iPhone arriba en Xcode y presiona ▶︎ (Cmd+R).
5. La primera vez: en el iPhone ve a **Ajustes → General → VPN y gestión de dispositivos** y confía en tu Apple ID.

Con un Apple ID gratuito la app deja de abrir a los 7 días; vuelve a darle ▶︎ en Xcode para renovarla.
Con la cuenta de desarrollador pagada (US$99/año) dura un año y puedes usar TestFlight.

## Primer uso

1. Abre **Entrenar** con internet: la app descarga la base de ejercicios una sola vez (~1 MB). Desde ahí funciona sin red.
2. **Configuración → Días de entrenamiento**: la rutina del día rota tren superior → tren inferior → pliometría según esos días.
3. **Inicio → Suplementos**: añade nombre, dosis y hora. Acepta el permiso de notificaciones.

## Cómo funciona

- **Recordatorios**: se programan avisos para los próximos días (hasta 14). Si ya marcaste el suplemento,
  no llega el aviso de ese día. Desde la notificación puedes tocar "Ya lo tomé ✓". La lista se renueva cada vez
  que abres la app.
- **Ejercicios**: la primera vez se hace **una sola petición** a
  `raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json` y los 876 ejercicios se
  guardan en la base local (`ExerciseRecord` en SwiftData). Todas las rutinas, grupos y búsquedas filtran esa
  copia en el iPhone. Para traer ejercicios nuevos: **Configuración → Base de ejercicios → Volver a descargar**.
- **Fotos**: cada ejercicio trae 2 fotos (posición inicial y final). Se descargan al verlas por primera vez y
  quedan en caché en el disco (hasta 300 MB), no forman parte de la petición única.
- **Rutinas equilibradas**: cada objetivo se divide en bloques (p. ej. tren superior: empuje, tracción, hombro,
  lanzamientos, manguito rotador, tríceps, core) y la sesión del día toma un ejercicio de cada bloque por turnos.
- **Casa / Gimnasio**: en "Casa" solo aparecen ejercicios con peso corporal o bandas elásticas.
- **Progreso**: constancia de suplementos de los últimos 7 días, racha y entrenos registrados.

## Añadir archivos

Si creas archivos `.swift` nuevos dentro de `Frontend/` o `Backend/` fuera de Xcode, regenera el proyecto:

```
python3 scripts/gen_xcodeproj.py "$PWD"
```
