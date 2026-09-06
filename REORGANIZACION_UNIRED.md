# Reorganización de UniRed

Este documento explica la reorganización visual realizada en el proyecto `unired`, tomando como referencia la estructura del proyecto `tiendasalmeron`.

## 1. Estructura de referencia

Se revisó el proyecto ubicado en:

`C:\Users\MSI THIN\Documents\Code\Flutter\tiendasalmeron`

El patrón principal de ese proyecto es:

```text
lib/
├── core/
│   ├── constants/
│   ├── services/
│   └── utils/
├── models/
│   └── modulo/
│       ├── controllers/
│       ├── models/
│       ├── views/
│       └── widgets/
└── shared/
    ├── extensions/
    ├── themes/
    └── widgets/
```

La idea es que cada módulo de la aplicación tenga su propio espacio para datos, pantallas, widgets y controladores futuros. Los elementos que se repiten en varios módulos viven en `shared`.

## 2. Estructura final de UniRed

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── services/
│   └── utils/
│       └── app_navigator.dart
├── models/
│   ├── about/
│   │   ├── views/about_page.dart
│   │   └── widgets/about_widgets.dart
│   ├── admin/
│   │   ├── models/dashboard_data.dart
│   │   ├── views/
│   │   │   ├── admin_login_page.dart
│   │   │   └── dashboard_page.dart
│   │   └── widgets/
│   │       ├── admin_fields.dart
│   │       ├── dashboard_charts.dart
│   │       └── dashboard_sections.dart
│   ├── auth/
│   │   ├── views/
│   │       ├── auth_layout.dart
│   │       ├── login_page.dart
│   │       └── register_page.dart
│   │   └── widgets/auth_widgets.dart
│   ├── home/
│   │   ├── views/home_page.dart
│   │   └── widgets/home_widgets.dart
│   ├── market/
│   │   ├── models/market_item.dart
│   │   └── views/market_page.dart
│   ├── tutorials/views/tutorials_page.dart
│   └── user/
│       ├── views/user_page.dart
│       └── widgets/user_widgets.dart
└── shared/
    ├── extensions/context_extensions.dart
    ├── themes/
    │   ├── app_colors.dart
    │   └── app_theme.dart
    └── widgets/
        ├── abstract_art.dart
        ├── admin_shell.dart
        ├── app_button.dart
        ├── brand_logo.dart
        ├── page_frame.dart
        ├── product_card.dart
        ├── public_footer.dart
        ├── public_header.dart
        └── status_pill.dart
```

Las carpetas `controllers`, `services` y los espacios `models` o `widgets` que todavía no tienen archivos se dejaron preparadas para la siguiente etapa. Como la solicitud actual es visual, no se agregó lógica de autenticación, API, base de datos ni estado de negocio.

## 3. Qué responsabilidad tiene cada nivel

### `core`

Contiene piezas transversales que conocen la aplicación, pero no una pantalla específica.

- `constants/app_constants.dart`: nombre y versión de la aplicación.
- `utils/app_navigator.dart`: nombres de rutas, creación de páginas y transición global.
- `services/`: reservado para API, almacenamiento local o autenticación cuando se implemente la funcionalidad.

### `models/<modulo>`

Cada módulo mantiene su código cerca de la pantalla que lo utiliza.

- `models/`: clases de datos como `MarketItem` y `DashboardStat`.
- `views/`: pantallas completas como Home, Login, Market y Dashboard.
- `widgets/`: componentes exclusivos del módulo, por ejemplo las gráficas del Dashboard.
- `controllers/`: reservado para la lógica futura del módulo.

### `shared`

Contiene piezas reutilizables en dos o más módulos.

- `themes/`: colores y tema global.
- `widgets/`: logo, botones, headers, footer, tarjetas, shells y arte decorativo.
- `extensions/`: atajos de layout para no repetir consultas de tamaño de pantalla.

## 4. Reutilización aplicada

Se evitó duplicar estructuras visuales de estas formas:

1. `PublicPageFrame` compone el header, el contenido con scroll y el footer de todas las páginas públicas.
2. `PublicHeader` concentra todos los enlaces y el menú responsive de móvil.
3. `AuthLayout` comparte el panel ilustrado y la distribución de Login y Registro.
4. `AuthField`, `CoralButton`, `GoogleButton` y `SocialButton` centralizan controles de acceso.
5. `AdminShell` y `AdminTopBar` comparten la navegación y la cabecera del Dashboard y Usuarios.
6. `SoftCard`, `PageSection`, `Eyebrow` y `BrandLogo` mantienen consistentes los espacios, bordes y la marca.
7. Los productos y estadísticas se representan con modelos (`MarketItem` y `DashboardStat`) en lugar de repetir mapas o widgets con datos incrustados.
8. La navegación usa una sola tabla de rutas y una sola transición en `AppNavigator`.
9. Las piezas propias de cada módulo se movieron a su carpeta `widgets`: campos de admin, tarjetas del dashboard, elementos de Home, controles de Auth, etiquetas de usuario y valores de About.

## 5. Migración de gráficas a `fl_chart`

Se agregó:

```yaml
fl_chart: ^1.1.1
```

Las gráficas del Dashboard quedaron concentradas en:

`lib/models/admin/widgets/dashboard_charts.dart`

Ese archivo contiene tres componentes reutilizables:

- `MiniSparkline`: gráfica pequeña para las tarjetas KPI.
- `SalesLineChart`: tendencia principal de ventas.
- `CategoryDonutChart`: distribución circular de ingresos.

Las gráficas ya no usan `CustomPainter`. `CustomPainter` se conserva únicamente para el arte decorativo de las pantallas de autenticación y el fondo del administrador, porque esas piezas son ilustraciones y no gráficas de datos.

Las tarjetas que contienen las gráficas viven en `dashboard_sections.dart`, separado del archivo de datos y separado del archivo de la vista. Así la pantalla solo compone módulos y los componentes pueden reutilizarse en otro dashboard.

Cuando se conecten datos reales, la vista no tendrá que cambiar. Bastará con reemplazar las listas de `FlSpot` en el widget o, preferiblemente, recibirlas desde un controlador.

## 6. Comentarios y documentación

Se añadieron comentarios de documentación en los componentes compartidos y en las gráficas para explicar:

- por qué existe cada capa;
- qué problema resuelve cada widget reutilizable;
- dónde sustituir los datos simulados;
- qué elementos son decorativos y cuáles representan datos.

Este archivo funciona como guía general del proyecto. Los comentarios dentro de los archivos sirven para explicar decisiones locales sin llenar cada línea de texto innecesario.

## 7. Cómo continuar con la funcionalidad

La siguiente etapa puede implementarse sin desordenar la UI:

1. Crear un servicio en `core/services`, por ejemplo `auth_service.dart`.
2. Crear un modelo real en `models/auth/models`.
3. Crear un controlador en `models/auth/controllers`.
4. Mantener la pantalla en `models/auth/views` y hacer que consuma el estado del controlador.
5. Sustituir los datos de ejemplo del Market y Dashboard por modelos entregados por servicios.
6. Mantener los widgets de `shared` sin lógica de negocio para que sigan siendo reutilizables.

## 8. Verificación

Se verificó el proyecto con:

```text
flutter analyze
flutter test
flutter build web
```

El análisis y las pruebas pasan correctamente. La interfaz conserva el diseño coral, azul, blanco y oscuro de UniRed, junto con navegación responsive y pantallas de acceso, marketplace, tutorías, información, administración y usuarios.
