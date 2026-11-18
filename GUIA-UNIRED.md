# Guía de uso de UniRed

## 1. Estudiante: encuentra una tutoría y solicita acceso

1. Entra a **Inicio → Explorar tutorías**.
2. En **Buscar tutorías**, escribe un tema o parte del título. También puedes filtrar por **Área**. Si no sale nada, borra el filtro o prueba otro término.
3. Abre una tutoría publicada. Revisa quién la imparte, el temario, la modalidad y el precio.
4. Pulsa **Solicitar acceso** en esa ficha. La solicitud queda asociada a esa tutoría, no se publica en un tablón de la comunidad.
5. Cuando el tutor la apruebe, una tutoría gratuita abre el aula directamente. Si tiene precio, vuelve a su ficha y pulsa **Pagar con tarjeta de prueba**. Elige la tarjeta de prueba y confirma. No ingreses una tarjeta real: no hay cobros ni factura fiscal. Puedes consultar el comprobante de demostración.
6. Para retomar una tutoría, abre **Mi aprendizaje**. En el aula, elige la lección desde el temario. Puedes reproducir, pausar, arrastrar el progreso, ajustar el volumen y la velocidad o ampliar el video a toda la vista de UniRed. Usa **Salir de pantalla completa** para volver al tamaño normal sin perder tu lugar.
7. En la ficha, **Mi reseña** te permite elegir de una a cinco estrellas, añadir un comentario si quieres y guardar.

El **Historial de solicitudes de ayuda** permite continuar solicitudes antiguas. Para iniciar una tutoría nueva, usa el catálogo.

## 2. Tutor: envía los documentos, publica y atiende solicitudes

1. Inicia sesión y ve a **Inicio → Quiero ser tutor**. El encabezado debe decir **Acreditación para ser tutor**.
2. Elige el área que quieres impartir y pulsa **Continuar a documentos**. Adjunta las evidencias que pide esa área. No debes indicar qué materia necesitas aprender, ni la modalidad, duración o precio de una tutoría.
3. Pulsa **Enviar documentos a revisión**. Vuelve a esa página para consultar el estado. Si te solicitan correcciones, reemplaza los documentos correspondientes y vuelve a enviar.
4. Con la acreditación vigente, entra a **Tutorías → Crear tutoría**. Prepara el temario, las lecciones y los recursos.
5. En el editor, activa **Ofrecer esta tutoría gratis** si esa publicación no tendrá costo. Si queda desactivado, revisa el importe calculado antes de publicar.
6. En la gestión de la tutoría, abre **Alumnos** y revisa las solicitudes. Aprobar una gratuita concede acceso; en una de pago, espera a que el estudiante confirme su pago de demostración.

## 3. Administrador o revisor: tramita una acreditación

1. Entra en el acceso administrativo. **Resumen** es la primera pantalla de gestión.
2. En escritorio, usa la barra lateral oscura para elegir un módulo y sus pestañas superiores para cambiar de apartado. En móvil, abre el menú ☰. **Mi perfil** conserva el mismo marco y te permite editar tus datos, seguridad y preferencias.
3. Ve a **Tutores → Expedientes de acreditación**. El filtro **Por revisar** muestra los expedientes enviados; **Borradores** corresponde a formularios todavía no enviados.
4. Abre un expediente, toma la revisión y comprueba los documentos. Aprueba, solicita correcciones o rechaza según corresponda y registra el motivo.
5. Consulta **Tutores autorizados**, **Próximos vencimientos** o **Historial de solicitudes** para el seguimiento. Los módulos disponibles dependen de los permisos de tu cuenta.

## 4. Marketplace y mensajes

1. Ve a **Marketplace**, busca por categoría o artículo y abre una publicación.
2. Envía un mensaje al vendedor desde la ficha. Acuerden precio y entrega por el chat. Los anuncios del Marketplace no cobran dentro de UniRed.
3. En escritorio, **Enter** envía el mensaje y **Shift + Enter** agrega otra línea. En móvil puedes usar el botón de enviar. La campana de notificaciones permite eliminar las que ya no quieras conservar.

## 5. AdSense: configura un anuncio dentro de Inicio

1. En [AdSense → Sitios](https://adsense.google.com/), comprueba el dominio donde quedará publicado el frontend. El estado del sitio debe permitir publicar anuncios. Un dominio nuevo se revisa por separado.
2. El código de editor `ca-pub-6670088332513129` ya está asociado al frontend. **No lo pegues en Render backend ni en Google Tag Manager.**
3. Los tres bloques ya están configurados. Si necesitas sustituir uno, copia el número de `data-ad-slot` desde **Anuncios → Por bloque de anuncios**. No es el identificador que empieza por `ca-pub-`. Consulta la [guía oficial de Google](https://support.google.com/adsense/answer/9274025).
4. Solo si cambias un bloque, puedes sobrescribir su número en **Settings → Secrets and variables → Actions → Variables** del repositorio frontend. Usa `ADSENSE_SQUARE_SLOT` para el cuadrado, `ADSENSE_HORIZONTAL_SLOT` para el horizontal y `ADSENSE_HOME_SLOT` para el vertical. Con otro hosting puedes usar `--dart-define=NOMBRE=NUMERO` al compilar.
5. Publica una nueva compilación del frontend. No tienes que pegar los tres scripts ni cambiar el backend.
6. Abre `/#/home` en el sitio publicado, sin bloqueador. Entre artículos y tutorías aparece el cuadrado **7849872648** en pantallas estrechas, o el horizontal **1064972445** si hay espacio. El vertical **7759915295** se coloca junto a las tutorías en escritorio amplio. UniRed reserva el tamaño apropiado para cada bloque y retira el espacio si AdSense indica que no encontró un anuncio. La entrega depende de Google y no se garantiza en cada visita.
7. Si quieres anuncios solo en la zona elegida, desactiva **Anuncios automáticos** para ese sitio en AdSense. UniRed no coloca bloques manuales en administración, chat, autenticación, pagos ni en el aula. No hagas clic en tus propios anuncios al verificar. Consulta las [políticas de colocación](https://support.google.com/adsense/answer/1346295).
