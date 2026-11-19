# Guía técnica de UniRed

Esta guía explica cómo está construido UniRed, cómo levantarlo en tu computadora y dónde cambiar cada función. Las rutas que empiezan por `lib/`, `web/` o `tool/` pertenecen al frontend. Las que empiezan por `src/`, `scripts/` o `database/` pertenecen al backend.

## Contenido

1. [Los dos repositorios](#1-los-dos-repositorios)
2. [Arranque local paso a paso](#2-arranque-local-paso-a-paso)
3. [Cómo está organizado el frontend](#3-cómo-está-organizado-el-frontend)
4. [Cómo está organizado el backend](#4-cómo-está-organizado-el-backend)
5. [Cómo funcionan los recorridos principales](#5-cómo-funcionan-los-recorridos-principales)
6. [PostgreSQL, archivos y correo](#6-postgresql-archivos-y-correo)
7. [Cómo hacer y probar un cambio](#7-cómo-hacer-y-probar-un-cambio)
8. [Despliegue, dominios y AdSense](#8-despliegue-dominios-y-adsense)
9. [Dónde mirar cuando algo falla](#9-dónde-mirar-cuando-algo-falla)

## 1. Los dos repositorios

| Repositorio | Responsabilidad | Punto de entrada |
|---|---|---|
| [UNIRED](https://github.com/link8500/UNIRED) | Flutter/Dart muestra las pantallas, toma entradas, navega y llama a la API. La portada pública y las páginas legales también tienen HTML propio. | [lib/main.dart](lib/main.dart) y [web/index.html](web/index.html) |
| [Unired_backend](https://github.com/link8500/Unired_backend) | NestJS/TypeScript verifica identidad y permisos, aplica las reglas y guarda datos en PostgreSQL. | `src/main.ts` y `src/app.module.ts` |

En esta máquina, el frontend está en `C:/Users/MSI THIN/Documents/Code/Flutter/unired` y el backend en `C:/Users/MSI THIN/Documents/Code/Backend/Nest.js/unired`. Cada repositorio tiene su propio historial. Si el cambio afecta a ambos, revisa `git status` en cada uno.

Flutter envía peticiones a la API de NestJS. El servidor comprueba los permisos del usuario y ejecuta en PostgreSQL las operaciones autorizadas.

## 2. Arranque local paso a paso

Usa Node.js 22, npm, Docker Desktop con contenedores Linux y Flutter 3.44.2, que es la versión fijada en el [workflow del frontend](.github/workflows/frontend.yml). Mantén las dos terminales abiertas. Los comandos siguientes usan PowerShell.

### Terminal 1 para API y PostgreSQL

```powershell
Set-Location 'C:/Users/MSI THIN/Documents/Code/Backend/Nest.js/unired'
npm ci
npm run setup:env
npm run docker:up
npm run db:migrate
npm run start:dev
```

- `setup:env` prepara el `.env` local. `docker:up` levanta solo PostgreSQL, en el puerto `5433` por defecto. NestJS corre en tu equipo y escucha en `127.0.0.1:3000`.
- Si vas a probar archivos de video en Windows, prepara FFmpeg/ffprobe con `npm run setup:media`. Para crear el primer administrador de una base local, usa `npm run admin:create` e introduce las credenciales que solicita para la cuenta nueva.
- Abre [Swagger](http://localhost:3000/docs) para ver rutas, métodos y campos. [Health](http://localhost:3000/api/v1/health) prueba que la API puede consultar PostgreSQL.
- En los siguientes arranques normalmente bastan `npm run docker:up` y `npm run start:dev`. Ejecuta `npm run db:migrate` si hay migraciones nuevas. Usa una base de desarrollo, no una URL de producción. No elimines el volumen de Docker para solucionar un arranque.

### Terminal 2 para Flutter Web

```powershell
Set-Location 'C:/Users/MSI THIN/Documents/Code/Flutter/unired'
flutter pub get
flutter run -d chrome --web-port=62604 --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

Si el navegador muestra la portada HTML, pulsa **Abrir UniRed** o entra directamente a [Inicio local](http://localhost:62604/#/home). Para probar el retorno de Google o Facebook, usa el origen exacto registrado. `http://localhost:62604` y `http://127.0.0.1:62604` son orígenes distintos. El acceso social necesita proveedores configurados en el backend. Las pruebas usan proveedores simulados.

Para revisar una compilación sin subirla:

```powershell
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
node tool/preview_web.cjs web 62604
```

Detén `flutter run` primero si ya está usando ese puerto. Mantén la API local abierta para que la vista previa muestre datos.

## 3. Cómo está organizado el frontend

- [lib/main.dart](lib/main.dart) crea `MaterialApp`, aplica el tema y arranca la carga inicial.
- [navegador_aplicacion.dart](lib/models/aplicacion/navegacion/navegador_aplicacion.dart) relaciona las rutas y parámetros con sus vistas. Por ejemplo, `/tutorials/course?id=9&aula=1` abre el aula de la tutoría 9 en Flutter. El prefijo `#` en la URL web pertenece a la navegación de la app.
- [aplicacion_controller.dart](lib/models/aplicacion/controllers/aplicacion_controller.dart) guarda el estado de la cuenta y los catálogos, coordina cargas y avisa a la interfaz cuando cambian los datos.
- [cliente_api.dart](lib/core/datos/remoto/cliente_api.dart) concentra las peticiones Dio, la URL base, el envío del token por cabecera, la renovación de sesión y la conversión de errores. El reintento por error de red transitorio se aplica a las consultas GET.
- `lib/core/dominio/` contiene contratos, utilidades para leer las respuestas y validaciones de presentación. `lib/core/aplicacion/` contiene, por ejemplo, el caso de uso de consultar o guardar publicaciones. Estas carpetas no dependen de pantallas ni de Dio.
- `lib/shared/` contiene tema, navegación visual, tablas, catálogos, formularios y mensajes de error reutilizados. Úsalo para cambios de aspecto compartido. Cambia la vista del módulo si el ajuste solo afecta una pantalla.

| Si quieres cambiar… | Empieza aquí |
|---|---|
| Inicio, publicaciones recientes y secciones destacadas | [InicioView](lib/models/inicio/views/inicio_view.dart) y `refreshHome()` en el controlador general |
| Búsqueda de tutorías o artículos, filtros y tarjetas | [CatalogoRemoto](lib/shared/widgets/catalogo_remoto.dart), las vistas en `models/tutorias/` y `models/market/` |
| Búsqueda general, denuncias o valoraciones entre usuarios | `models/comunidad/`, `models/interacciones/` y [FormularioResena](lib/shared/widgets/formulario_resena.dart) |
| Publicar una tutoría o un artículo | [EditorPublicacion](lib/models/administracion/widgets/editor_publicacion.dart) y [PublicacionesUseCases](lib/core/aplicacion/publicaciones_use_cases.dart). El editor se comparte con el panel. |
| Ficha, inscripción, temario, clases, aula y video | [CursoView](lib/models/tutorias/views/curso_view.dart), [GestionCurso](lib/models/tutorias/widgets/gestion_curso.dart), [AulaCurso](lib/models/tutorias/widgets/aula_curso.dart) y [LectorLeccion](lib/models/tutorias/widgets/lector_leccion.dart) |
| Enviar documentos para ser tutor | [AcreditacionView](lib/models/acreditaciones/views/acreditacion_view.dart) |
| Resumen administrativo, navegación lateral y perfil del equipo | [PanelView](lib/models/administracion/views/panel_view.dart), [EstructuraAdministracion](lib/shared/widgets/estructura_administracion.dart) y [PerfilView](lib/models/perfil/views/perfil_view.dart) |
| Usuarios, expedientes, revisión y preferencias del panel | `models/usuarios/`, `models/administracion/` y `models/configuracion/` |
| Registro, acceso con contraseña, Google y Facebook | `models/autenticacion/`, en especial [RetornoSocialView](lib/models/autenticacion/views/retorno_social_view.dart) |
| Mis sesiones, cuentas vinculadas, archivos y perfil público | `models/perfil/`, en especial [SeguridadCuenta](lib/models/perfil/widgets/seguridad_cuenta.dart) |
| Chat, notificaciones y forma de contactar a quien vende | [MensajesView](lib/models/mensajeria/views/mensajes_view.dart), [BotonNotificaciones](lib/shared/widgets/boton_notificaciones.dart) y [ContactoVendedor](lib/models/market/widgets/contacto_vendedor.dart) |
| Empresas, campañas, cartera y tarjeta de prueba | `models/comercial/` y [pago_demo.dart](lib/models/comercial/widgets/pago_demo.dart) |
| Página «Nosotros», imagen de marca o textos legales | `models/nosotros/`, `assets/branding/` y `web/` |

## 4. Cómo está organizado el backend

`src/main.ts` valida la configuración e inicia NestJS. `src/app.module.ts` reúne los módulos en una sola API. `src/shared/http/configurar-aplicacion.ts` configura el prefijo `/api/v1`, CORS, Swagger, los errores HTTP y el identificador `X-Request-Id`.

Sigue una petición en este orden:

1. El **controlador** (`src/models/<módulo>/controllers/`) recibe ruta, método, cuerpo y usuario autenticado.
2. El **caso de uso** (`src/models/<módulo>/aplicacion/`) valida datos y permisos, decide qué hacer y abre una transacción cuando corresponde.
3. Los **contratos y reglas** (`src/core/dominio/` y `src/core/aplicacion/`) definen entidades, filtros, validaciones y operaciones como cotizar una tutoría.
4. Los **adaptadores** (`src/shared/`) ejecutan las consultas PostgreSQL, guardan archivos, envían correo y prestan servicios de seguridad.

| Módulo en `src/models/` | Responsabilidad |
|---|---|
| `identidad` | Registro, contraseña, correo, Google/Facebook, perfiles, sesiones y eventos autenticados. |
| `acreditaciones` | Expediente del tutor, evidencias, revisión y habilitación por área. |
| `cursos` | Publicación y edición de tutorías, secciones, lecciones y recursos. |
| `aprendizaje` y `sesiones` | Solicitud y aprobación de inscripción, aula, progreso, preguntas, reseñas, clases en vivo y reservas. |
| `market` | Catálogo, anuncios, imágenes, favoritos y actualizaciones. |
| `mensajeria` e `interacciones` | Contacto directo, chat, bloqueos, historial de ofertas y solicitudes de ayuda, y valoraciones entre usuarios. |
| `comunidad` | Búsqueda, perfiles públicos, notificaciones y denuncias. |
| `comercial` | Tarifas, checkout simulado, comprobantes, cartera, planes, promociones y campañas de empresas. |
| `multimedia` | Subida, escaneo, procesamiento, permisos y entrega de archivos. |
| `administracion` | Panel, usuarios y roles, moderación, catálogos, expedientes y auditoría. |

Los decoradores indican el contrato HTTP. Por ejemplo, `@Post('courses/:id/enrollments')` corresponde a `POST /api/v1/courses/:id/enrollments`. El guard de autenticación protege las rutas privadas y el caso de uso comprueba si *esa persona* puede actuar sobre *ese recurso*. Consulta Swagger o el controlador al cambiar los campos de una petición.

## 5. Cómo funcionan los recorridos principales

### Entrar, vincular Google o Facebook y ver dispositivos

1. Flutter envía `POST /auth/login` con el correo y la contraseña, o prepara el acceso social desde [AplicacionController](lib/models/aplicacion/controllers/aplicacion_controller.dart). Las rutas de API escritas sin prefijo en esta sección llevan `/api/v1`.
2. En acceso social, el navegador conserva temporalmente el verificador PKCE en esa pestaña. El backend recibe el retorno del proveedor y entrega un código de un solo uso. Flutter envía el código y el verificador en el cuerpo de `POST /auth/social/exchange` y recibe los tokens de sesión en la respuesta.
3. `identidad.use-cases.ts` crea la sesión. Flutter conserva los tokens en memoria y obtiene la cuenta y sus roles desde `/me`. Normalmente el usuario entra a Inicio y el administrador a su panel. La verificación de correo y el retorno de vinculación tienen rutas propias.
4. En web, [identificador_navegador_web.dart](lib/core/datos/remoto/identificador_navegador_web.dart) guarda un identificador aleatorio en el almacenamiento del sitio. Al autenticarse de nuevo en la misma cuenta y navegador, la sesión previa de ese navegador se revoca. Dos dispositivos pueden seguir abiertos incluso si usan la misma IP. Cada perfil de navegador y cada dominio tienen su propio almacenamiento. La deduplicación depende de que ese almacenamiento esté disponible.
5. `GET /me/sessions` lista sesiones vigentes y marca la actual. Las etiquetas como «Safari en iPhone» se construyen a partir de los datos que informa el navegador. `DELETE /me/sessions/:id` cierra una sesión. `POST /me/sessions/revoke-others` cierra las demás y conserva la actual. Las sesiones antiguas sin datos se muestran como «Dispositivo no identificado».

Para cambiar este flujo, compara [RetornoSocialView](lib/models/autenticacion/views/retorno_social_view.dart), [SeguridadCuenta](lib/models/perfil/widgets/seguridad_cuenta.dart) y los controladores y casos de uso de `src/models/identidad/`.

### Acreditarse para enseñar

1. En **Inicio → Quiero ser tutor**, [AcreditacionView](lib/models/acreditaciones/views/acreditacion_view.dart) consulta `GET /areas` y crea el expediente con `POST /me/tutor-applications`.
2. Los archivos se suben a `POST /files` con el propósito de evidencia de tutor. Después se adjuntan al expediente y se envían con `POST /me/tutor-applications/:id/submit`.
3. El revisor abre **Tutores → Expedientes de acreditación** en el panel, asume la revisión y registra una decisión. La habilitación resultante determina en qué área puede publicar el tutor.

El área y los documentos que pide el expediente dependen de los requisitos de acreditación.

### Crear, buscar y tomar una tutoría

1. El tutor acreditado abre **Tutorías → Crear tutoría**. El editor guarda un borrador vía `POST /me/courses`. Luego añade contenido, guarda cambios y publica con `POST /me/courses/:id/publish`. Conserva `versionLock` cuando la operación lo pida para detectar ediciones sobre datos desactualizados.
2. El interruptor **Ofrecer esta tutoría gratis** guarda `gratuita` para esa publicación. La cotización la calcula el backend en `src/core/aplicacion/cotizacion-tutoria.ts`.
3. El estudiante usa **Explorar tutorías**. [CatalogoRemoto](lib/shared/widgets/catalogo_remoto.dart) llama a `searchCourses()`. [ClienteApi](lib/core/datos/remoto/cliente_api.dart) envía `GET /courses?q=...&areaId=...` según los filtros. El controlador de cursos llega a `PostgresQueries.catalog()`. Si quieres cambiar *qué resultados aparecen*, sigue esa ruta hasta el filtro SQL. Si quieres cambiar *cómo se ven*, empieza por el catálogo o la tarjeta.
4. Desde la ficha, `POST /courses/:id/enrollments` crea la solicitud de acceso. El tutor puede abrir **Solicitudes y alumnos** desde la campana o con **Ver solicitudes y alumnos** en la ficha de su curso. Al pulsar **Aceptar solicitud**, Flutter envía `PATCH /me/courses/:id/enrollments/:enrollmentId`. Una tutoría gratuita se activa en ese momento. Si tiene precio, la aprobación marca `aprobadaParaPagoEn` y deja el acceso pendiente. El estudiante confirma en `POST /demo/checkout` con el concepto `tutoria_inscripcion`. El servidor registra el comprobante y activa el acceso.
5. En el aula, `GET /courses/:id/lessons/:lessonId` entrega la lección según permisos. El reproductor conserva posición al ampliar y ofrece un toque para reproducir o pausar y doble toque para pantalla completa. `PUT /me/enrollments/:id/progress/:lessonId` guarda avance, y `PUT /me/enrollments/:id/review` guarda la reseña de estrellas y comentario.

El checkout usa una **tarjeta de prueba** y entrega un comprobante de demostración. La búsqueda de tutorías empieza en el catálogo. El historial anterior está en `/me/tutoring-requests`.

### Marketplace, chat y notificaciones

- El catálogo público se lee con `GET /listings`. Las publicaciones propias se editan bajo `/me/listings`. Inicio usa la API para mostrar los artículos recientes.
- **Contactar al vendedor** envía el mensaje inicial a `POST /listings/:id/inquiry`. Luego el chat usa `/conversations/:id/messages`. **Enter** envía y **Shift + Enter** agrega una línea en el editor de escritorio. Comprador y vendedor acuerdan precio y entrega en el chat.
- Las notificaciones se guardan en el servidor. Flutter escucha `/me/events` mediante SSE (eventos del servidor) y también consulta las notificaciones. En [BotonNotificaciones](lib/shared/widgets/boton_notificaciones.dart), **Ver detalles** aparece si el aviso trae datos para abrir una vista. `conversacionId` abre el chat y `cursoId` o `tutoriaId` abre la tutoría. En avisos de inscripción de un curso propio, el enlace abre su gestión. Los avisos generales se muestran como texto. Cada cuenta puede marcar o borrar sus avisos desde `/me/notifications`.

### Administrar UniRed

1. El [panel de resumen](lib/models/administracion/views/panel_view.dart) muestra indicadores de usuarios, tutorías, artículos y casos pendientes. Para cambiar sus cifras, revisa `PostgresQueries.dashboard()` y `analytics()` en el backend.
2. [ModulosAdministracion](lib/models/administracion/models/modulos_administracion.dart) agrupa las rutas de Usuarios, Tutores, Formación, Marketplace, Atención y Configuración. [EstructuraAdministracion](lib/shared/widgets/estructura_administracion.dart) contiene la navegación del panel. Para cambiar una tarea concreta, abre la vista a la que apunta su ruta.
3. El equipo revisa documentos en **Tutores → Expedientes de acreditación**, atiende denuncias en **Atención → Casos abiertos** y consulta cambios registrados en **Configuración → Auditoría**. Al agregar una acción, revisa qué rol puede ejecutarla en la API y qué entradas de auditoría deja.

## 6. PostgreSQL, archivos y correo

| Tema | Dónde está el código |
|---|---|
| Conexión a PostgreSQL | `src/shared/base_datos/conexion.config.ts` usa `DB_*` en local y da prioridad a `DATABASE_URL` si está definida. Producción requiere TLS verificado. |
| Nombres de tablas y campos | `src/core/dominio/comun/entidades.ts` define campos como `navegadorId` y `src/shared/base_datos/esquema.ts` los relaciona con columnas como `navegador_id`. |
| Guardado, consultas y transacciones | `postgres.database.ts` implementa operaciones genéricas. `postgres.queries.ts`, `administracion.queries.ts` y `gestion.queries.ts` contienen lecturas especializadas. Todos están en `src/shared/base_datos/`. |
| Cambios de esquema | `database/design/` contiene SQL de referencia y base para algunas migraciones. Las migraciones aplicadas son las registradas en `src/shared/base_datos/origen-datos.ts`. |
| Archivos | `src/models/multimedia/` maneja el ciclo de carga y permisos. `src/shared/almacenamiento/` implementa almacenamiento local o compatible con S3, como R2. |
| Correo | `src/shared/correo/` procesa el envío. En desarrollo, `MAIL_TRANSPORT=file` deja correo de prueba en `.local-mails` por defecto. El proyecto también tiene transporte SMTP y Resend. |

Al añadir una columna, crea una migración nueva y regístrala en `origen-datos.ts`. Si la leen los casos de uso, actualiza también la entidad y su mapeo. Prueba la actualización con PostgreSQL aislado antes de usarla con datos reales.

Para documentos y videos, Flutter sube archivos a la API, que valida, escanea y procesa según el tipo. Los recursos privados se abren con permisos o enlaces temporales de la API. Si un archivo queda pendiente, revisa su estado de procesamiento y los logs.

`.env.example` del backend documenta los nombres de configuración. Nunca compartas `.env`, `DATABASE_URL`, claves de Google/Facebook, secretos JWT, credenciales S3 ni claves de correo. `API_BASE_URL` y los identificadores públicos de AdSense sí forman parte de la compilación web.

## 7. Cómo hacer y probar un cambio

1. Busca una palabra visible en la interfaz con `rg -n` y abre la vista encontrada. Si es una regla o un dato incorrecto, busca además el endpoint o el nombre del caso de uso en el backend.
2. Reproduce con cuentas de prueba y registra el resultado esperado. Por ejemplo, una inscripción con precio debe seguir pendiente después de la aprobación y activarse al confirmar el pago simulado.
3. Si cambias el contrato, conserva compatibilidad con el cliente que ya está publicado o define el orden de despliegue. Haz validar permisos y precios en el backend. Después ajusta la vista, el progreso, el estado vacío y los mensajes de error en Flutter.
4. Para una regresión, elige una prueba que hubiese fallado antes del arreglo. Revisa móvil y escritorio en ajustes visuales y comprueba los permisos con más de un rol si el cambio toca acceso a datos.

**Frontend** (desde el repositorio Flutter):

```powershell
flutter analyze --no-pub
dart run tool/verificar_arquitectura.dart
flutter test --no-pub
flutter test --no-pub test/acceso_social_test.dart test/reproductor_leccion_test.dart
```

Las pruebas de widgets suelen usar [TestAdapter](test/support/test_adapter.dart). Para unir Flutter, NestJS y PostgreSQL en una base temporal, ejecuta `node tool/test_api_integration.cjs` desde el frontend. Si el backend está en otra carpeta, define `UNIRED_BACKEND_PATH`. Puedes añadir `--web` para el escenario de navegador que ofrece ese script. Necesitas Docker y las dependencias instaladas en ambos repositorios.

**Backend** (desde el repositorio NestJS):

```powershell
npm run architecture:check
npm test
npm run build
node scripts/test-integration.cjs --social
node scripts/test-integration.cjs --interactions
```

`--social` prueba identidad con proveedores simulados. `--interactions` incluye chat, pagos simulados y flujos de tutorías. Ambas integraciones levantan una base temporal de PostgreSQL. Las pruebas unitarias suelen estar en archivos `*.spec.ts`. El workflow de GitHub ejecuta las comprobaciones de la API. [GitHub Actions del backend](https://github.com/link8500/Unired_backend/actions)

## 8. Despliegue, dominios y AdSense

1. **Backend en Render:** el comando de arranque del repositorio es `npm run start:prod`. Tras compilar, `scripts/start-production.cjs` aplica migraciones pendientes con un bloqueo de PostgreSQL y luego levanta la API. Verifica `/api/v1/health` y los logs. El `Dockerfile` también ejecuta ese script de arranque.
2. **Frontend en Netlify:** [frontend.yml](.github/workflows/frontend.yml) instala Flutter, analiza el código, corre pruebas, compila `build/web`, comprueba `ads.txt` y publica desde `main` si pasaron los pasos. Las pull requests solo verifican. Las credenciales de Netlify son secretos de GitHub Actions. [netlify.toml](netlify.toml) indica la carpeta publicada y la regla de rutas.
3. **Si también publicas el frontend en Render:** usa una compilación web del frontend con el `API_BASE_URL` correcto, no el servidor NestJS como alojamiento del sitio. La API debe permitir el nuevo origen HTTPS en `CORS_ORIGINS`. Si usas acceso social revisa además `FRONTEND_URL`, `API_PUBLIC_URL` y las URLs de retorno autorizadas de cada proveedor. No incluyas rutas ni fragmentos `#` en un origen CORS.
4. **Si cambian ambos repositorios:** despliega primero el backend cuando el frontend necesita rutas o campos nuevos. Después comprueba el dominio publicado, no solo el resultado de la compilación.

**Portada y anuncios.** [web/presentacion.js](web/presentacion.js) separa la portada HTML y la carga de Flutter. El identificador del editor se declara en [web/index.html](web/index.html) y la autorización del vendedor se publica en la raíz con [web/ads.txt](web/ads.txt). [InicioView](lib/models/inicio/views/inicio_view.dart) coloca un bloque cuadrado u horizontal entre artículos y tutorías según el espacio disponible. El bloque vertical va junto a las tutorías cuando hay suficiente ancho. [AnuncioInicio para Web](lib/models/inicio/widgets/anuncio_inicio_web.dart) asigna el ID a cada formato y comparte un único cargador. Los IDs actuales son `7849872648` (cuadrado), `1064972445` (horizontal) y `7759915295` (vertical). Sus variables de compilación son `ADSENSE_SQUARE_SLOT`, `ADSENSE_HORIZONTAL_SLOT` y `ADSENSE_HOME_SLOT`, respectivamente.

**Verificaciones de Google.** Search Console, la marca OAuth, Analytics/Tag Manager y AdSense cumplen funciones distintas. Los archivos o etiquetas de verificación web no aprueban automáticamente el acceso con Google ni habilitan la entrega de anuncios.

## 9. Dónde mirar cuando algo falla

| Síntoma | Primer chequeo |
|---|---|
| Inicio abre, pero todo el catálogo sale vacío | Revisa `/api/v1/health`, la petición a `/courses` o `/listings` y los filtros. Mira la pestaña **Red** del navegador antes de cambiar la vista. |
| Swagger o PowerShell funcionan, pero el frontend en otro dominio falla | Compara el `Origin` del navegador con `CORS_ORIGINS` y comprueba el valor de `API_BASE_URL` incorporado en la compilación. |
| Login social vuelve con error | Revisa el origen, el retorno autorizado, el paso de canje y el error HTTP sin compartir el código de un solo uso. La página de marca de Google es una revisión aparte. |
| Una sesión anterior aparece sin nombre | Las sesiones creadas antes del cambio pueden carecer de datos de dispositivo. Revisa **Seguridad → Mis sesiones**. |
| El tutor aprobó, pero el aula sigue cerrada | Si tiene precio, mira si quedó aprobada para pago y si existe el comprobante. Si es gratis, revisa el estado de la inscripción y la disponibilidad del curso. |
| No carga un documento o video | Revisa el estado en **Mis archivos**, el propósito de la carga, permisos, escaneo y FFprobe. Para pantalla completa, prueba el gesto directamente en la app, fuera de una vista previa incrustada. |
| GitHub muestra `exit code 1` | Abre el paso rojo del workflow y lee la primera aserción o fallo real. Distingue ese fallo de los pasos que aparecen omitidos. |
| No ves el anuncio | Comprueba que el frontend nuevo esté publicado, que `/ads.txt` responda como texto y que el sitio esté listo en AdSense. En local y en vistas previas de Netlify no se envían peticiones de anuncios. |

Para ubicar una función, busca el texto visible, abre su vista, identifica la petición y sigue el controlador y el caso de uso del backend. Para reproducir un error, registra la ruta, la hora, el estado HTTP y `X-Request-Id` si está disponible.
