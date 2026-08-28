(function () {
  "use strict";

  /* ── Mobile menu ── */
  var hdr = document.getElementById('hdr'),
      burger = document.getElementById('burger'),
      nav = document.getElementById('nav');

  function setMenu(open) {
    hdr.classList.toggle('open', open);
    burger.setAttribute('aria-expanded', String(open));
    burger.setAttribute('aria-label', open ? 'ปิดเมนู' : 'เปิดเมนู');
  }
  burger.addEventListener('click', function () {
    setMenu(!hdr.classList.contains('open'));
  });
  nav.addEventListener('click', function (e) {
    if (e.target.closest('a')) setMenu(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') setMenu(false);
  });

  /* Keep scroll-padding-top in sync with the real sticky header height so
     in-page anchors never land underneath it. */
  function syncHeader() {
    document.documentElement.style.setProperty('--hdr', hdr.offsetHeight + 'px');
    if (window.innerWidth > 860) setMenu(false);
  }
  syncHeader();
  window.addEventListener('resize', syncHeader, { passive: true });

  /* ── Hero video ──
     The original attached the source unconditionally and set muted /
     playsInline from JS after mount, then polled play() every 700ms
     forever when autoplay was refused. Here the attributes are present at
     parse time (required by iOS Safari), the ~520KB source is only
     attached when it is actually worth playing, and the retry gives up. */
  var v = document.getElementById('heroVideo');
  if (v) {
    var conn = navigator.connection || navigator.mozConnection || navigator.webkitConnection,
        effective = (conn && conn.effectiveType) || '',
        saveData = !!(conn && conn.saveData),
        slow = /(^|-)[23]g$/.test(effective),   // slow-2g, 2g, 3g
        reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    /* Data-saver, reduced-motion and anything below 4G keep the poster frame
       only — phones included, where the video is a 16:9 block rather than a
       background. Safari implements no Network Information API, so
       effectiveType is '' there and the source loads regardless of speed. */
    if (!saveData && !reduce && !slow) {
      var tries = 0, timer = null;
      var play = function () {
        var p = v.play();
        if (p && p.catch) p.catch(function () {});
      };
      v.addEventListener('canplay', play);
      v.src = v.dataset.src;
      v.load();
      play();
      timer = setInterval(function () {
        if (!v.paused || ++tries > 6) clearInterval(timer);
        else play();
      }, 700);
      /* Do not burn battery on a hero that has scrolled away. */
      if ('IntersectionObserver' in window) {
        new IntersectionObserver(function (es) {
          es.forEach(function (e) { e.isIntersecting ? play() : v.pause(); });
        }, { threshold: 0.1 }).observe(v);
      }
    }
  }
})();