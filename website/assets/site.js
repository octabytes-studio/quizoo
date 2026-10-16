// Quizoo legal pages — shared behaviours.
// Theme mirror-settings in the app: System default, then a remembered choice
// in localStorage (`quizoo-theme`), exactly like Settings → App theme.

(function () {
  var KEY = 'quizoo-theme';
  var doc = document.documentElement;

  // Pre-paint script in <head> already set data-app; keep the buttons in sync.
  var light = document.getElementById('theme-light');
  var dark = document.getElementById('theme-dark');

  function paint(state) {
    light.setAttribute('aria-pressed', state !== 'dark');
    dark.setAttribute('aria-pressed', state === 'dark');
  }
  paint(doc.dataset.app === 'dark' ? 'dark' : 'light');

  function store(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }

  light.addEventListener('click', function () { doc.removeAttribute('data-app'); store('light'); paint('light'); });
  dark.addEventListener('click', function () { doc.dataset.app = 'dark'; store('dark'); paint('dark'); });

  // Follow live system changes only while the player hasn't picked a side.
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
    var remembered; try { remembered = localStorage.getItem(KEY); } catch (err) {}
    if (!remembered) {
      if (e.matches) doc.dataset.app = 'dark'; else doc.removeAttribute('data-app');
      paint(e.matches ? 'dark' : 'light');
    }
  });

  // Back-to-top ledge — same 4px press as the app's chunky buttons.
  var btp = document.getElementById('backtop');
  if (btp) {
    addEventListener('scroll', function () {
      btp.classList.toggle('show', scrollY > 560);
    }, { passive: true });
  }
})();
