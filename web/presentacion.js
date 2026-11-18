// Mantiene la portada pública en HTML y abre Flutter al navegar a una ruta de la aplicación.
(() => {
  const basePath = new URL(document.baseURI).pathname;
  const isAppRoute = () => window.location.hash.startsWith('#/') ||
    ![basePath, basePath + 'index.html'].includes(window.location.pathname);
  if (!isAppRoute()) {
    // Las rutas con hash necesitan un documento nuevo para quitar el entorno de anuncios.
    window.addEventListener('hashchange', () => {
      if (isAppRoute()) window.location.reload();
    });
    const publisher = document.querySelector('meta[name="google-adsense-account"]').content;
    const ads = document.createElement('script');
    ads.async = true;
    ads.crossOrigin = 'anonymous';
    ads.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + publisher;
    document.head.append(ads);
    return;
  }

  const presentation = document.getElementById('presentacion-unired');
  const opening = document.getElementById('carga-unired');
  const enter = document.getElementById('abrir-unired');
  const status = document.getElementById('estado-inicio-unired');
  const retry = document.getElementById('reintentar-unired');

  opening.hidden = false;
  enter.hidden = true;

  window.addEventListener('flutter-first-frame', () => {
    presentation?.remove();
  }, { once: true });
  window.addEventListener('hashchange', () => {
    if (!isAppRoute()) window.location.reload();
  });

  window.addEventListener('error', (event) => {
    if (event.target?.id !== 'inicio-flutter-unired') return;
    if (status) {
      status.textContent = 'No pudimos abrir la aplicación. Comprueba tu conexión e inténtalo de nuevo.';
    }
    if (retry) retry.hidden = false;
  }, true);

  retry?.addEventListener('click', () => window.location.reload());
  const bootstrap = document.createElement('script');
  bootstrap.id = 'inicio-flutter-unired';
  bootstrap.src = 'flutter_bootstrap.js';
  document.body.append(bootstrap);
})();
