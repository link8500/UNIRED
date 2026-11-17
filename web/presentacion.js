// Conserva la presentación pública hasta que Flutter haya dibujado su primera vista.
(() => {
  const presentation = document.getElementById('presentacion-unired');
  const status = document.getElementById('estado-inicio-unired');
  const retry = document.getElementById('reintentar-unired');

  if (status) status.hidden = false;

  window.addEventListener('flutter-first-frame', () => {
    presentation?.remove();
  }, { once: true });

  window.addEventListener('error', (event) => {
    if (event.target?.id !== 'inicio-flutter-unired') return;
    if (status) {
      status.textContent = 'No pudimos abrir la aplicación. Comprueba tu conexión e inténtalo de nuevo.';
    }
    if (retry) retry.hidden = false;
  }, true);

  retry?.addEventListener('click', () => window.location.reload());
})();
