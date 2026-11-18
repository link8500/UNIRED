// Mantiene la portada pública en HTML y abre Flutter al navegar a una ruta de la aplicación.
(() => {
  const basePath = new URL(document.baseURI).pathname;
  const isAppRoute = () => window.location.hash.startsWith('#/') ||
    ![basePath, basePath + 'index.html'].includes(window.location.pathname);
  const loadAds = () => {
    const { protocol, hostname } = window.location;
    if (protocol !== 'https:' || hostname === 'localhost' ||
        (hostname.endsWith('.netlify.app') && hostname.includes('--'))) return null;
    const existing = document.getElementById('unired-adsense-loader');
    if (existing) return existing;
    const publisher = document.querySelector('meta[name="google-adsense-account"]')?.content;
    if (!publisher || !/^ca-pub-\d+$/.test(publisher)) return null;
    const ads = document.createElement('script');
    ads.id = 'unired-adsense-loader';
    ads.async = true;
    ads.crossOrigin = 'anonymous';
    ads.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + publisher;
    ads.addEventListener('error', () => { ads.dataset.uniredFailed = 'true'; });
    document.head.append(ads);
    return ads;
  };
  window.uniredRegisterDisplayAd = (unit) => {
    if (!(unit instanceof HTMLElement) || unit.dataset.uniredRequested) return;
    // Flutter crea la vista antes de conectarla al DOM. Solo se solicita con ancho real.
    const observer = new ResizeObserver(() => {
      if (!unit.isConnected || unit.clientWidth === 0) return;
      observer.disconnect();
      clearTimeout(timeout);
      if (unit.dataset.uniredRequested) return;
      unit.dataset.uniredRequested = 'true';
      const script = loadAds();
      const hide = () => unit.setAttribute('data-unired-ad-error', '');
      if (!script || script.dataset.uniredFailed) {
        hide();
        return;
      }
      script.addEventListener('error', hide, { once: true });
      script.addEventListener('load', () => script.removeEventListener('error', hide), { once: true });
      try {
        (window.adsbygoogle = window.adsbygoogle || []).push({});
      } catch (error) {
        hide();
        console.warn('No se pudo iniciar el bloque de anuncios de Inicio.', error);
      }
    });
    const timeout = setTimeout(() => {
      observer.disconnect();
      if (unit.isConnected) unit.setAttribute('data-unired-ad-error', '');
    }, 20000);
    observer.observe(unit);
  };
  if (!isAppRoute()) {
    // La portada es HTML independiente y Flutter se abre al entrar a la aplicación.
    window.addEventListener('hashchange', () => {
      if (isAppRoute()) window.location.reload();
    });
    loadAds();
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
